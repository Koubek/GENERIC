powershell -command Invoke-WebRequest -Uri "http://go.microsoft.com/fwlink/?LinkID=615137" -OutFile ".\Install\rewrite_amd64.msi"
docker rmi navdocker.azurecr.io/nav/generic
docker build -t navdocker.azurecr.io/nav/generic .
