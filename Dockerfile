FROM microsoft/mssql-server-windows-express

LABEL maintainer "Freddy Kristiansen"

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

ENV username _
ENV password _
ENV licensefile _
ENV bakfile _
ENV WindowsAuth N
ENV DatabaseServer _
ENV DatabaseInstance _
ENV DatabaseName _

WORKDIR /
COPY Install /Install/
COPY Run /Run/

RUN DEL c:\license.txt
RUN DEL c:\start.ps1
RUN DEL c:\dockerfile

RUN PowerShell -Command Add-WindowsFeature Web-Server,web-AppInit,web-Asp-Net45,web-Windows-Auth,web-Dyn-Compression

HEALTHCHECK CMD [ "sqlcmd", "-Q", "select 1" ]

EXPOSE 1433 80 443 7045-7049

CMD C:\Run\start.ps1
