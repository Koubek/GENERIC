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
$mageExeFile = Join-Path $installPath 'mage.exe'
if (!(Test-Path $mageExeFile ))
{
    Copy-Item -Path 'C:\temp\mage.exe' -Destination $mageExeFile
}

$maintainer = "Freddy Kristiansen"
$created = [DateTime]::Now.ToUniversalTime().ToString("yyyy-MM-ddTHH:mmZ")
docker build --label maintainer="$maintainer" --label created="$created" -t "${registry}dynamics-nav-generic" $PSScriptRoot
if ($push) {
    docker push "${registry}dynamics-nav-generic"
}
