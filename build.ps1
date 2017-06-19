$installPath = Join-Path $PSScriptRoot 'Install'
if (!(Test-Path $installPath))
{
    New-Item -ItemType Directory -Force $installPath
}

if (!(Test-Path (Join-Path $installPath 'rewrite_amd64.msi')))
{
	(New-Object System.Net.WebClient).DownloadFile("http://go.microsoft.com/fwlink/?LinkID=615137", (Join-Path $installPath 'rewrite_amd64.msi.tmp'))
	Rename-Item (Join-Path $installPath 'rewrite_amd64.msi.tmp') (Join-Path $installPath 'rewrite_amd64.msi')
}

docker build -t navdocker.azurecr.io/nav/generic $PSScriptRoot
