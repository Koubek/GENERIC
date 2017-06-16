$installPath = Join-Path $PSScriptRoot 'Install'
if (!(Test-Path $installPath))
{
    New-Item -ItemType Directory -Force $installPath
}

Invoke-WebRequest -Uri "http://go.microsoft.com/fwlink/?LinkID=615137" -OutFile (Join-Path $installPath 'rewrite_amd64.msi')

docker build -t navdocker.azurecr.io/nav/generic .
