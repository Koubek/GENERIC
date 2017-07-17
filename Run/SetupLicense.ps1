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
    if ($licensefile.StartsWith("https://") -or $licensefile.StartsWith("http://"))
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

if (!$licenseOk) {
    Write-Host "Import NAV License"
    Import-NAVServerLicense -LicenseFile $licensefile -ServerInstance 'NAV' -Database NavDatabase -WarningAction SilentlyContinue
}
