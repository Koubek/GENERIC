if ($useSSL) {
    Copy-Item -Path (Join-Path $PSScriptRoot "Certificate.cer") -Destination $httpPath
}
Copy-Item -Path (Join-Path $PSScriptRoot "*.vsix") -Destination $httpPath
