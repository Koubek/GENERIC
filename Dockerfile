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

# Install the prerequisites first to be able reuse the cache when changing only the scripts.
RUN Add-WindowsFeature Web-Server,web-AppInit,web-Asp-Net45,web-Windows-Auth,web-Dyn-Compression

WORKDIR /
COPY Install /Install/
COPY Run /Run/

RUN DEL c:\license.txt; \
    DEL c:\start.ps1; \
    DEL c:\dockerfile

HEALTHCHECK --interval=30s --timeout=10s CMD [ "powershell", ".\\Run\\HealthCheck.ps1" ]

EXPOSE 1433 80 443 7045-7049

CMD .\Run\start.ps1
