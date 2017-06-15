Write-Host "Create Self Signed Certificate"
$certificatePfxFile = "c:\Run\certificate.pfx"
$certificateCerFile = "c:\Run\certificate.cer"
$certificatePfxPassword = Get-RandomPassword
$SecurePfxPassword = ConvertTo-SecureString -String $certificatePfxPassword -AsPlainText -Force
New-SelfSignedCertificateEx -Subject "CN=$hostname" -IsCA $true -Exportable -Path $certificatePfxFile -Password $SecurePfxPassword | Out-Null
$cert = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2($certificatePfxFile, $certificatePfxPassword)
Export-Certificate -Cert $cert -FilePath $CertificateCerFile | Out-Null
$thumbprint = $cert.Thumbprint
Write-Host "Self Signed Certificate Thumbprint $Thumbprint"
Import-PfxCertificate -Password $SecurePfxPassword -FilePath $certificatePfxFile -CertStoreLocation "cert:\localMachine\my" | Out-Null
Import-PfxCertificate -Password $SecurePfxPassword -FilePath $certificatePfxFile -CertStoreLocation "cert:\localMachine\Root" | Out-Null
