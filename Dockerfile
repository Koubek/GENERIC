FROM microsoft/mssql-server-windows-developer

LABEL maintainer "Freddy Kristiansen"

SHELL ["powershell", "-Command", "$ErrorActionPreference = 'Stop'; $ProgressPreference = 'SilentlyContinue';"]

# Install the prerequisites first to be able reuse the cache when changing only the scripts.
RUN Add-WindowsFeature Web-Server,web-AppInit,web-Asp-Net45,web-Windows-Auth,web-Dyn-Compression

# Temporary workaround for Windows DNS client weirdness (need to check if the issue is still present or not).
RUN Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters' -Name ServerPriorityTimeLimit -Value 0 -Type DWord

COPY Install /Install/
COPY Run /Run/

RUN Remove-Item c:\license.txt; \
    Remove-Item c:\start.ps1; \
    Remove-Item c:\dockerfile

HEALTHCHECK --interval=30s --timeout=10s CMD [ "powershell", ".\\Run\\HealthCheck.ps1" ]

EXPOSE 1433 80 443 7045-7049

CMD .\Run\start.ps1
