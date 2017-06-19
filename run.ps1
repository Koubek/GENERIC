$navdvdPath = Join-Path $PSScriptRoot 'NAVDVD'
if (!(Test-Path $navdvdPath)) {
    Write-Error "NAVDVD folder not present - cannot run generic image without NAVDVD folder"
    exit
}
$sharePath = Join-Path $PSScriptRoot 'Share'
$shareParameter = ""
if (Test-Path $sharePath) {
    $shareParameter = " -v ${sharePath}:c:\share"
}
start-process 'docker.exe' -argumentList "run -v ${navdvdPath}:c:\NAVDVD$shareParameter navdocker.azurecr.io/nav/generic"
