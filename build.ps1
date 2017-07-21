$registry = "navdocker.azurecr.io/"
$registry = ""

$installPath = Join-Path $PSScriptRoot 'Run\Install'
if (!(Test-Path $installPath))
{
    New-Item -ItemType Directory -Force $installPath
}

$hlinkFile = Join-Path $installPath 'hlink.dll'
if (!(Test-Path $hlinkFile ))
{
    Copy-Item -Path 'C:\Windows\SysWOW64\hlink.dll' -Destination $hlinkFile
}

docker build -t "${registry}dynamics-nav-generic" $PSScriptRoot
if ($registry -ne "") {
    docker push "${registry}dynamics-nav-generic"
}
