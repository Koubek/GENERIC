$username = $env:username
$password = $env:password
$licensefile = $env:licensefile
$bakfile = $env:bakfile
$databaseServer = $env:databaseServer
$databaseInstance = $env:databaseInstance
$databaseName = $env:databaseName
$buildingImage = ($env:buildingImage -eq "Y")

# start the SQL Server
Write-Host "Starting SQL Server"
Start-Service -Name 'MSSQL$SQLEXPRESS'

if ($env:WindowsAuth -eq "Y") {
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

if (!(Test-Path "C:\NAVDVD" -PathType Container)) {
    Write-Error "ERROR: NAVDVD folder not found"
    Write-Error "You must map a folder on the host with the NAVDVD content"
    exit 1
}

Write-Host "Using $auth Authentication"
Write-Host "Installing Url Rewrite"
start-process C:\Install\rewrite_amd64.msi -ArgumentList "/quiet /qn /passive" -Wait

# Copy Service Tier in place
$genericImage = (!(Test-Path "C:\Program Files\Microsoft Dynamics NAV" -PathType Container))
if ($genericImage) {
    Write-Host "Copy Service Tier"
    Copy-Item -Path "C:\NAVDVD\ServiceTier\Program Files" -Destination "C:\" -Recurse -Force

    Write-Host "Copy Web Client"
    Copy-Item -Path "C:\NAVDVD\WebClient\Microsoft Dynamics NAV" -Destination "C:\Program Files\" -Recurse -Force
}
$ServiceTierFolder = (Get-Item "C:\Program Files\Microsoft Dynamics NAV\*\Service").FullName
$WebClientFolder = (Get-Item "C:\Program Files\Microsoft Dynamics NAV\*\Web Client")[0]

. C:\RUN\HelperFunctions.ps1
. C:\RUN\New-SelfSignedCertificateEx.ps1
Import-Module "$ServiceTierFolder\Microsoft.Dynamics.Nav.Management.psm1"

# License file
$licenseOk = $false
if ($licensefile -eq "_") 
{
    Write-Host "Using CRONUS license file"
    $licensefile = "$ServiceTierFolder\Cronus.flf"
    if (!$genericImage) { 
        $licenseOk = $true
    }
} else {
    if ($licensefile.StartsWith("https://") -or $licensefile.StartsWidth("http://"))
    {
        $licensefileurl = $licensefile
        $licensefile = "c:\Run\license.flf"
        Write-Host "Downloading license file '$licensefileurl'"
        Invoke-WebRequest $licensefileurl -OutFile $licensefile
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
if ($databaseServer -ne "_" -and $databaseInstance -ne "_" -and $databaseName -ne "_") {
    Write-Host "Using Database Connection $DatabaseServer\$DatabaseInstance [$DatabaseName]"
} else {
    if ($databaseServer -ne "_" -or $databaseInstance -ne "_" -or $databaseName -ne "_") {
        	Write-Error "ERROR: Database Connection only partly specified."
            Write-Error "Specifying Database settings to an existing database requires all parameters to be set"
            Write-Error "DatabaseServer, DatabaseInstance and DatabaseName"
            exit 1
    }

    $databaseFolder = "c:\databases"
    New-Item -Path $databaseFolder -itemtype Directory | Out-Null
    $databaseServer = "localhost"
    $databaseInstance = "SQLEXPRESS"
    $databaseName = ""
    
    if ($bakfile -eq "_") 
    {
        Write-Host "Using CRONUS Demo Database"
    
        $bak = (Get-ChildItem -Path "C:\NAVDVD\SQLDemoDatabase\CommonAppData\Microsoft\Microsoft Dynamics NAV\*\Database\*.bak")[0]
        $databaseName = "CRONUS"
        $databaseFile = $bak.FullName
        
    } else {
    
        if ($bakfile.StartsWith("https://") -or $bakfile.StartsWidth("http://"))
        {
            $bakfileurl = $bakfile
            $databaseFile = "c:\Run\mydatabase.bak"
            Write-Host "Downloading database backup file '$bakfileurl'"
            Invoke-WebRequest $bakfileurl -OutFile $databaseFile
    
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

if ($genericImage) {

    # run local installers if present
    Get-ChildItem "C:\NAVDVD\Installers" | Where-Object { $_.PSIsContainer } | % {
        Get-ChildItem $_.FullName | Where-Object { $_.PSIsContainer } | % {
            $dir = $_.FullName
            Get-ChildItem (Join-Path $dir "*.msi") | % {
                $filepath = $_.FullName
                Write-Host "Installing $filepath"
                Start-Process -FilePath $filepath -WorkingDirectory $dir -ArgumentList "/qn /norestart" -Wait
            }
        }
    }

    Write-Host "Modify NAV Service Tier Config File for Docker"
    $PublicWebBaseUrl = "$protocol$hostname/NAV/WebClient"
    $CustomConfigFile = Join-Path (Get-Item "C:\Program Files\Microsoft Dynamics NAV\*\Service").FullName "CustomSettings.config"
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
    $customConfig.SelectSingleNode("//appSettings/add[@key='EnableTaskScheduler']").Value = "false"
    $CustomConfig.Save($CustomConfigFile)

    if ($buildingImage) {

        # Create Service
        Write-Host "Create NAV Service Tier"
        $serviceCredentials = New-Object System.Management.Automation.PSCredential ("NT AUTHORITY\SYSTEM", (new-object System.Security.SecureString))
        New-Service -Name 'MicrosoftDynamicsNavServer$NAV' -BinaryPathName """$ServiceTierFolder\Microsoft.Dynamics.Nav.Server.exe"" `$NAV /config ""$ServiceTierFolder\Microsoft.Dynamics.Nav.Server.exe.config""" -DisplayName '"Microsoft Dynamics NAV Server [NAV]' -Description 'NAV' -StartupType auto -Credential $serviceCredentials -DependsOn @("HTTP") | Out-Null
        Start-Service -Name 'MicrosoftDynamicsNavServer$NAV' -WarningAction SilentlyContinue
        
        Write-Host "Import NAV License"
        Import-NAVServerLicense -LicenseFile $licensefile -ServerInstance 'NAV' -Database NavDatabase -WarningAction SilentlyContinue
    }
}

if (!$buildingImage) {

    $hostname = hostname
    Write-Host "Hostname: $hostname"
    
    # Certificate
    if ($useSSL) {
        . C:\RUN\SetupCertificate.ps1
    }
    
    Write-Host "Modify NAV Service Tier Config File with Instance Specific Settings"
    $PublicWebBaseUrl = "$protocol$hostname/NAV/WebClient"
    $CustomConfigFile = Join-Path (Get-Item "C:\Program Files\Microsoft Dynamics NAV\*\Service").FullName "CustomSettings.config"
    $CustomConfig = [xml](Get-Content $CustomConfigFile)
    $customConfig.SelectSingleNode("//appSettings/add[@key='ClientServicesCredentialType']").Value = $auth
    $CustomConfig.SelectSingleNode("//appSettings/add[@key='PublicWebBaseUrl']").Value = $PublicWebBaseUrl
    $CustomConfig.SelectSingleNode("//appSettings/add[@key='PublicSOAPBaseUrl']").Value = "$protocol${hostname}:7047/NAV/WS"
    $CustomConfig.SelectSingleNode("//appSettings/add[@key='PublicODataBaseUrl']").Value = "$protocol${hostname}:7048/NAV/OData"
    $developerServicesKeyExists = ($customConfig.SelectSingleNode("//appSettings/add[@key='DeveloperServicesPort']") -ne $null)
    if ($developerServicesKeyExists) {
        $customConfig.SelectSingleNode("//appSettings/add[@key='DeveloperServicesPort']").Value = "7049"
        $customConfig.SelectSingleNode("//appSettings/add[@key='DeveloperServicesEnabled']").Value = ($auth -eq "Windows").ToString().ToLower()
    }
    if ($useSSL) {
        $CustomConfig.SelectSingleNode("//appSettings/add[@key='ServicesCertificateThumbprint']").Value = "$thumbprint"
        $CustomConfig.SelectSingleNode("//appSettings/add[@key='ServicesCertificateValidationEnabled']").Value = "false"
        $CustomConfig.SelectSingleNode("//appSettings/add[@key='SOAPServicesSSLEnabled']").Value = "true"
        $CustomConfig.SelectSingleNode("//appSettings/add[@key='ODataServicesSSLEnabled']").Value = "true"
        if ($developerServicesKeyExists) {
            $CustomConfig.SelectSingleNode("//appSettings/add[@key='DeveloperServicesSSLEnabled']").Value = "true"
        }
    }
    $CustomConfig.Save($CustomConfigFile)
    
    if ($genericImage) {
        # Create Service
        Write-Host "Create NAV Service Tier"
        $serviceCredentials = New-Object System.Management.Automation.PSCredential ("NT AUTHORITY\SYSTEM", (new-object System.Security.SecureString))
        New-Service -Name 'MicrosoftDynamicsNavServer$NAV' -BinaryPathName """$ServiceTierFolder\Microsoft.Dynamics.Nav.Server.exe"" `$NAV /config ""$ServiceTierFolder\Microsoft.Dynamics.Nav.Server.exe.config""" -DisplayName '"Microsoft Dynamics NAV Server [NAV]' -Description 'NAV' -StartupType auto -Credential $serviceCredentials -DependsOn @("HTTP") | Out-Null
        Start-Service -Name 'MicrosoftDynamicsNavServer$NAV' -WarningAction SilentlyContinue
    } else {
        Restart-Service -Name 'MicrosoftDynamicsNavServer$NAV' -WarningAction SilentlyContinue
    }
    
    if (!$licenseOk) {
        Write-Host "Import NAV License"
        Import-NAVServerLicense -LicenseFile $licensefile -ServerInstance 'NAV' -Database NavDatabase -WarningAction SilentlyContinue
    }
    
    # Remove Default Web Site
    Get-WebSite | Remove-WebSite
    Get-WebBinding | Remove-WebBinding
    
    # Create Web Client
    Write-Host "Create Web Site"
    if ($useSSL) {
        New-NavWebSite -WebClientFolder $WebClientFolder.FullName -inetpubFolder "C:\NAVDVD\WebClient\inetpub\" -AppPoolName "NavWebClientAppPool" -SiteName "NavWebClient" -Port $webClientPort -Auth $Auth -CertificateThumbprint $thumbprint
    } else {
        New-NavWebSite -WebClientFolder $WebClientFolder.FullName -inetpubFolder "C:\NAVDVD\WebClient\inetpub\" -AppPoolName "NavWebClientAppPool" -SiteName "NavWebClient" -Port $webClientPort -Auth $Auth
    }
    Write-Host "Create NAV Web Server Instance"
    New-NAVWebServerInstance -Server "localhost" -ClientServicesCredentialType $auth -ClientServicesPort 7046 -ServerInstance "NAV" -WebServerInstance "NAV"
    
    $ip = (Get-NetIPAddress | Where-Object { $_.AddressFamily -eq "IPv4" -and $_.IPAddress -ne "127.0.0.1" })[0].IPAddress
    Write-Host "Container IP Address: $ip"
    Write-Host "Container Hostname  : $hostname"
    Write-Host "Web Client          : $publicWebBaseUrl"

    . C:\Run\SetupUsers.ps1
}