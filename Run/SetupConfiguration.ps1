# INPUT
#     $auth
#     $protocol
#     $hostname
#     $ServiceTierFolder
#     $navUseSSL
#     $servicesUseSSL
#     $certificateThumbprint
#
# OUTPUT
#

Write-Host "Modify NAV Service Tier Config File with Instance Specific Settings"
$PublicWebBaseUrl = "$protocol$hostname/NAV/WebClient/"
$CustomConfigFile =  Join-Path $ServiceTierFolder "CustomSettings.config"
$CustomConfig = [xml](Get-Content $CustomConfigFile)
$customConfig.SelectSingleNode("//appSettings/add[@key='ClientServicesCredentialType']").Value = $auth
$CustomConfig.SelectSingleNode("//appSettings/add[@key='PublicWebBaseUrl']").Value = $PublicWebBaseUrl
$CustomConfig.SelectSingleNode("//appSettings/add[@key='PublicSOAPBaseUrl']").Value = "$protocol${hostname}:7047/NAV/WS"
$CustomConfig.SelectSingleNode("//appSettings/add[@key='PublicODataBaseUrl']").Value = "$protocol${hostname}:7048/NAV/OData"
if ($navUseSSL) {
    $CustomConfig.SelectSingleNode("//appSettings/add[@key='ServicesCertificateThumbprint']").Value = "$certificateThumbprint"
    $CustomConfig.SelectSingleNode("//appSettings/add[@key='ServicesCertificateValidationEnabled']").Value = "false"
}

$CustomConfig.SelectSingleNode("//appSettings/add[@key='SOAPServicesSSLEnabled']").Value = $servicesUseSSL.ToString().ToLower()
$CustomConfig.SelectSingleNode("//appSettings/add[@key='ODataServicesSSLEnabled']").Value = $servicesUseSSL.ToString().ToLower()
netsh http add urlacl url=$protocol+:7047/NAV user="NT AUTHORITY\SYSTEM" | Out-Null
netsh http add urlacl url=$protocol+:7048/NAV user="NT AUTHORITY\SYSTEM" | Out-Null
$developerServicesKeyExists = ($customConfig.SelectSingleNode("//appSettings/add[@key='DeveloperServicesPort']") -ne $null)
if ($developerServicesKeyExists) {
    $customConfig.SelectSingleNode("//appSettings/add[@key='DeveloperServicesPort']").Value = "7049"
    $customConfig.SelectSingleNode("//appSettings/add[@key='DeveloperServicesEnabled']").Value = "true"
    $CustomConfig.SelectSingleNode("//appSettings/add[@key='DeveloperServicesSSLEnabled']").Value = $servicesUseSSL.ToString().ToLower()
    netsh http add urlacl url=$protocol+:7049/NAV user="NT AUTHORITY\SYSTEM" | Out-Null
}
if ($servicesUseSSL) {
    netsh http add sslcert ipport=0.0.0.0:7047 certhash=$certificateThumbprint appid="{00112233-4455-6677-8899-AABBCCDDEEFF}" | Out-Null
    netsh http add sslcert ipport=0.0.0.0:7048 certhash=$certificateThumbprint appid="{00112233-4455-6677-8899-AABBCCDDEEFF}" | Out-Null
    netsh http add sslcert ipport=0.0.0.0:7049 certhash=$certificateThumbprint appid="{00112233-4455-6677-8899-AABBCCDDEEFF}" | Out-Null
}
$CustomConfig.Save($CustomConfigFile)
