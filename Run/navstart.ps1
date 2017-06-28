. (Join-Path $PSScriptRoot "HelperFunctions.ps1")
. (Join-Path $PSScriptRoot "New-SelfSignedCertificateEx.ps1")

. (Get-MyFilePath "SetupVariables.ps1")

if ($databaseInstance -eq "Default") { $databaseInstance = "" }
$windowsAuth = ($env:WindowsAuth -eq "Y")
$myPath = Join-Path $PSScriptRoot "my"
$navDvdPath = "C:\NAVDVD"

# This script is multi-purpose
#
# $buildingImage is true when called during build of specific NAV image (with CRONUS Demo Database and CRONUS license)
# $restartingInstance is true when called due to Docker restart of a running image
# $runningGenericImage is true when running a generic image with NAVDVD on share
# $runningSpecificImage is true when running a specific image (which had buildingImage set true true during image build)
#
$buildingImage = ($env:buildingImage -eq "Y")
if ($buildingImage) { Write-Host "Building Image" }

$restartingInstance = $false
if (Test-Path "C:\Program Files\Microsoft Dynamics NAV" -PathType Container) {
    $CustomConfigFile = Join-Path (Get-Item "C:\Program Files\Microsoft Dynamics NAV\*\Service").FullName "CustomSettings.config"
    $CustomConfig = [xml](Get-Content $CustomConfigFile)
    $restartingInstance = ($CustomConfig.SelectSingleNode("//appSettings/add[@key='PublicWebBaseUrl']").Value -ne "")
}
if ($restartingInstance) { Write-Host "Restarting Instance" }

$runningGenericImage = !$restartingInstance -and !$buildingImage -and (!(Test-Path "C:\Program Files\Microsoft Dynamics NAV" -PathType Container))
if ($runningGenericImage) { Write-Host "Running Generic Image" }

$runningSpecificImage = (!$restartingInstance) -and (!$runningGenericImage) -and (!$buildingImage)
if ($runningSpecificImage) { Write-Host "Running Specific Image" }

if ($buildingImage + $restartingInstance + $runningGenericImage + $runningSpecificImage -ne 1) {
    Write-Error "ERROR: Cannot determine reason for running script."
    exit 1
}

# start the SQL Server
Write-Host "Starting Local SQL Server"
Start-Service -Name 'MSSQLSERVER' -ErrorAction Ignore

if ($windowsAuth) {
    $auth = "Windows"
    $useSSL = $false
    $protocol = "http://"
    $webClientPort = 80
} else {
    $auth = "NavUserPassword"
    $useSSL = $true
    $protocol = "https://"
    $webClientPort = 443
}

if ($runningGenericImage -or $buildingImage) {
    if (!(Test-Path $navDvdPath -PathType Container)) {
        Write-Error "ERROR: NAVDVD folder not found"
        Write-Error "You must map a folder on the host with the NAVDVD content to $navDvdPath"
        exit 1
    }
}

if ($runningSpecificImage -and $Accept_eula -ne "Y")
{
    Write-Error "ERROR: You must accept the End User License Agreement before this container can start."
    Write-Error "Set the environment variable ACCEPT_EULA to 'Y' if you accept the agreement."
    exit 1 
}

if ($runningGenericImage -or $runningSpecificImage) 
{
    Write-Host "Using $auth Authentication"

    # re-installing Url rewrite when running the image means that we can avoid iisreset (which is much slower)
    Write-Host "Installing Url Rewrite"
    start-process C:\Install\rewrite_amd64.msi -ArgumentList "/quiet /qn /passive" -Wait
}

# Copy Service Tier in place if we are running a Generic Image or Building a specific image
if ($runningGenericImage -or $buildingImage) {
    Write-Host "Copy Service Tier"
    Copy-Item -Path "C:\NAVDVD\ServiceTier\Program Files" -Destination "C:\" -Recurse -Force

    Write-Host "Copy Web Client"
    Copy-Item -Path "C:\NAVDVD\WebClient\Microsoft Dynamics NAV" -Destination "C:\Program Files\" -Recurse -Force
    Copy-Item -Path "$navDvdPath\WebClient\inetpub" -Destination $PSSCriptRoot -Recurse -Force

    Write-Host "Copy RTC Files"
    Copy-Item -Path "$navDvdPath\RoleTailoredClient\program files\Microsoft Dynamics NAV" -Destination "C:\Program Files (x86)\" -Recurse -Force
    Copy-Item -Path "$navDvdPath\*.vsix" -Destination $PSScriptRoot
}

$ServiceTierFolder = (Get-Item "C:\Program Files\Microsoft Dynamics NAV\*\Service").FullName
$RoleTailoredClientFolder = (Get-Item "C:\Program Files (x86)\Microsoft Dynamics NAV\*\RoleTailored Client").FullName
$WebClientFolder = (Get-Item "C:\Program Files\Microsoft Dynamics NAV\*\Web Client")[0]

Import-Module "$ServiceTierFolder\Microsoft.Dynamics.Nav.Management.psm1"

if ($restartingInstance) {
    Write-Host "Wait for NAV Service Tier to start"
    while ((Get-service -name 'MicrosoftDynamicsNavServer$NAV').Status -ne 'Running') { 
        Start-Sleep -Seconds 5
    }
    Write-Host "NAV Service Tier started"
}


# License file
$licenseOk = $false
if ($restartingInstance) {
    $licenseOk = $true
} elseif ($licensefile -eq "_") {
    Write-Host "Using CRONUS license file"
    $licensefile = "$ServiceTierFolder\Cronus.flf"
    if ($runningSpecificImage) { 
        $licenseOk = $true
    }
} else {
    if ($licensefile.StartsWith("https://") -or $licensefile.StartsWidth("http://"))
    {
        $licensefileurl = $licensefile
        $licensefile = (Join-Path $PSScriptRoot "license.flf")
        Write-Host "Downloading license file '$licensefileurl'"
        (New-Object System.Net.WebClient).DownloadFile($licensefileurl, $licensefile)
    } else {
        Write-Host "Using license file '$licensefile'"
        if (!(Test-Path -Path $licensefile -PathType Leaf)) {
        	Write-Error "ERROR: License File not found."
            Write-Error "The file must be uploaded to the container or available on a share."
            exit 1
        }
    }
}

# Database
if (!$restartingInstance) {
    if ($databaseServer -ne "_" -and $databaseInstance -ne "_" -and $databaseName -ne "_") {
        
        # Specific images will have database settings - no DB restore
        Write-Host "Using Database Connection $DatabaseServer\$DatabaseInstance [$DatabaseName]"
    
    } else {

        if ($runningSpecificImage) {
        	Write-Error "ERROR: Database Connection not properly specified when running a pre-built image."
            exit 1
        }

        if ($databaseServer -ne "_" -or $databaseInstance -ne "_" -or $databaseName -ne "_") {
        	Write-Error "ERROR: Database Connection only partly specified."
            Write-Error "Specifying Database settings to an existing database requires all parameters to be set"
            Write-Error "DatabaseServer, DatabaseInstance and DatabaseName"
            exit 1
        }
    
        $databaseFolder = "c:\databases"
        New-Item -Path $databaseFolder -itemtype Directory | Out-Null
        $databaseServer = "localhost"
        $databaseInstance = ""
        $databaseName = ""
        
        if ($bakfile -eq "_") 
        {
            Write-Host "Using CRONUS Demo Database"
        
            $bak = (Get-ChildItem -Path "$navDvdPath\SQLDemoDatabase\CommonAppData\Microsoft\Microsoft Dynamics NAV\*\Database\*.bak")[0]
            $databaseName = "CRONUS"
            $databaseFile = $bak.FullName
            
        } else {
        
            if ($bakfile.StartsWith("https://") -or $bakfile.StartsWidth("http://"))
            {
                $bakfileurl = $bakfile
                $databaseFile = (Join-Path $PSScriptRoot "mydatabase.bak")
                Write-Host "Downloading database backup file '$bakfileurl'"
                (New-Object System.Net.WebClient).DownloadFile($bakfileurl, $databaseFile)
        
            } else {
                Write-Host "Using Database .bak file '$bakfile'"
                if (!(Test-Path -Path $bakfile -PathType Leaf)) {
                	Write-Error "ERROR: Database Backup File not found."
                    Write-Error "The file must be uploaded to the container or available on a share."
                    exit 1
                }
                $databaseFile = $bakFile
            }
            $databaseName = "mydatabase"
        }
    
        # Restore database
        New-NAVDatabase -DatabaseServer $databaseServer `
                        -DatabaseInstance $databaseInstance `
                        -DatabaseName "$databaseName" `
                        -FilePath "$databaseFile" `
                        -DestinationPath "$databaseFolder" | Out-Null
    }
}

if ($runningGenericImage -or $buildingImage) {

    # run local installers if present
    if (Test-Path "$navDvdPath\Installers" -PathType Container) {
        Get-ChildItem "$navDvdPath\Installers" | Where-Object { $_.PSIsContainer } | % {
            Get-ChildItem $_.FullName | Where-Object { $_.PSIsContainer } | % {
                $dir = $_.FullName
                Get-ChildItem (Join-Path $dir "*.msi") | % {
                    $filepath = $_.FullName
                    Write-Host "Installing $filepath"
                    Start-Process -FilePath $filepath -WorkingDirectory $dir -ArgumentList "/qn /norestart" -Wait
                }
            }
        }
    }

    Write-Host "Modify NAV Service Tier Config File for Docker"
    $PublicWebBaseUrl = "$protocol$hostname/NAV/WebClient"
    $CustomConfigFile =  Join-Path $ServiceTierFolder "CustomSettings.config"
    $CustomConfig = [xml](Get-Content $CustomConfigFile)
    $customConfig.SelectSingleNode("//appSettings/add[@key='DatabaseServer']").Value = $databaseServer
    $customConfig.SelectSingleNode("//appSettings/add[@key='DatabaseInstance']").Value = $databaseInstance
    $customConfig.SelectSingleNode("//appSettings/add[@key='DatabaseName']").Value = "$databaseName"
    $customConfig.SelectSingleNode("//appSettings/add[@key='ServerInstance']").Value = "NAV"
    $customConfig.SelectSingleNode("//appSettings/add[@key='ManagementServicesPort']").Value = "7045"
    $customConfig.SelectSingleNode("//appSettings/add[@key='ClientServicesPort']").Value = "7046"
    $customConfig.SelectSingleNode("//appSettings/add[@key='SOAPServicesPort']").Value = "7047"
    $customConfig.SelectSingleNode("//appSettings/add[@key='ODataServicesPort']").Value = "7048"
    $customConfig.SelectSingleNode("//appSettings/add[@key='DefaultClient']").Value = "Web"
    $taskSchedulerKeyExists = ($customConfig.SelectSingleNode("//appSettings/add[@key='EnableTaskScheduler']") -ne $null)
    if ($taskSchedulerKeyExists) {
        $customConfig.SelectSingleNode("//appSettings/add[@key='EnableTaskScheduler']").Value = "false"
    }
    $CustomConfig.Save($CustomConfigFile)
}

if ($runningGenericImage -or $runningSpecificImage) {

    if ($databaseServer -ne 'localhost' -or $databaseInstance -ne '') {
        Write-Host "Stopping local SQL Server"
        Stop-Service -Name 'MSSQLSERVER' -ErrorAction Ignore
    }

    $hostname = hostname
    Write-Host "Hostname is $hostname"
    
    # Certificate
    if ($useSSL) {
        . (Get-MyFilePath "SetupCertificate.ps1")
    }
    
    . (Get-MyFilePath "SetupConfiguration.ps1")
    . (Get-MyFilePath "SetupAddIns.ps1")
}
 
if ($runningGenericImage -or $buildingImage) {
    # Create NAV Service
    Write-Host "Create NAV Service Tier"
    $serviceCredentials = New-Object System.Management.Automation.PSCredential ("NT AUTHORITY\SYSTEM", (new-object System.Security.SecureString))
    New-Service -Name 'MicrosoftDynamicsNavServer$NAV' -BinaryPathName """$ServiceTierFolder\Microsoft.Dynamics.Nav.Server.exe"" `$NAV /config ""$ServiceTierFolder\Microsoft.Dynamics.Nav.Server.exe.config""" -DisplayName '"Microsoft Dynamics NAV Server [NAV]' -Description 'NAV' -StartupType auto -Credential $serviceCredentials -DependsOn @("HTTP") | Out-Null
    Start-Service -Name 'MicrosoftDynamicsNavServer$NAV' -WarningAction SilentlyContinue
}

if ($runningSpecificImage) {
    # Restart NAV Service
    Write-Host "Restart NAV Service Tier"
    Restart-Service -Name 'MicrosoftDynamicsNavServer$NAV' -WarningAction SilentlyContinue
}
        
if (!$licenseOk) {
    Write-Host "Import NAV License"
    Import-NAVServerLicense -LicenseFile $licensefile -ServerInstance 'NAV' -Database NavDatabase -WarningAction SilentlyContinue
}

$wwwRootPath = Get-WWWRootPath
$httpPath = Join-Path $wwwRootPath "http"
if ($runningGenericImage -or $runningSpecificImage) {

    # Remove Default Web Site
    Get-WebSite | Remove-WebSite
    Get-WebBinding | Remove-WebBinding
    
    # Create Web Client
    Write-Host "Create Web Site"
    if ($useSSL) {
        New-NavWebSite -WebClientFolder $WebClientFolder -inetpubFolder (Join-Path $PSScriptRoot "inetpub") -AppPoolName "NavWebClientAppPool" -SiteName "NavWebClient" -Port $webClientPort -Auth $Auth -CertificateThumbprint $thumbprint
    } else {
        New-NavWebSite -WebClientFolder $WebClientFolder -inetpubFolder (Join-Path $PSScriptRoot "inetpub") -AppPoolName "NavWebClientAppPool" -SiteName "NavWebClient" -Port $webClientPort -Auth $Auth
    }
    Write-Host "Create NAV Web Server Instance"
    New-NAVWebServerInstance -Server "localhost" -ClientServicesCredentialType $auth -ClientServicesPort 7046 -ServerInstance "NAV" -WebServerInstance "NAV"

    Write-Host "Create http download site"
    if ($useSSL) {
        New-Item -Path $httpPath -ItemType Directory | Out-Null
        New-Website -Name http -Port 80 -PhysicalPath $httpPath | Out-Null
    } else {
        New-Item -Path $httpPath -ItemType SymbolicLink -Target (Join-Path $wwwRootPath "NAVWebApplicationContainer") | Out-Null
        Remove-Item -Path (Join-Path $httpPath "Default.htm") 
    }

    $webConfigFile = Join-Path $httpPath "web.config"
    Copy-Item -Path (Join-Path $PSScriptRoot "web.config") -Destination $webConfigFile
    get-item -Path $webConfigFile | % { $_.Attributes = "Hidden" }

    . (Get-MyFilePath "SetupFileShare.ps1")
    . (Get-MyFilePath "SetupSqlUsers.ps1")
    . (Get-MyFilePath "SetupNavUsers.ps1")
}

if ($buildingImage) {
    # NAVDVD content not needed after building specific image
    Remove-Item -Path $navDvdPath -Recurse -Force
} else {
    $ip = (Get-NetIPAddress | Where-Object { $_.AddressFamily -eq "IPv4" -and $_.IPAddress -ne "127.0.0.1" })[0].IPAddress
    Write-Host "Container IP Address: $ip"
    Write-Host "Container Hostname  : $hostname"
    Write-Host "Web Client          : $publicWebBaseUrl"

    if (Test-Path -Path (Join-Path $httpPath "*.vsix")) {
        Write-Host "Dev. Server         : http://$hostname"
        Write-Host "Dev. ServerInstance : NAV"
    }

    Write-Host 
    Write-Host "Files:"
    Get-ChildItem -Path $httpPath -file | % {
        Write-Host "http://$hostname/$($_.Name)"
    }
    Write-Host 
    Write-Host "Ready for connections!"
}
