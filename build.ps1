if (!($registry)) {
    throw '$registry needs to be set. Either to a valid registry or to _ in order to avoid push'
}

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

$registrystr = ""
if ($registry -ne "_") { $registrystr = $registry }

$maintainer = "Freddy Kristiansen"
$created = [DateTime]::Now.ToUniversalTime().ToString("yyyy-MM-ddTHH:mmZ")
docker build --label maintainer="$maintainer" --label created="$created" -t "${registrystr}dynamics-nav-generic" $PSScriptRoot
if ($registry -ne "_") {
    docker push "${registry}dynamics-nav-generic"
}
