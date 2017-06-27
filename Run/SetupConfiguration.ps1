Write-Host "Modify NAV Service Tier Config File with Instance Specific Settings"
$PublicWebBaseUrl = "$protocol$hostname/NAV/WebClient"
$CustomConfigFile =  Join-Path $ServiceTierFolder "CustomSettings.config"
$CustomConfig = [xml](Get-Content $CustomConfigFile)
$customConfig.SelectSingleNode("//appSettings/add[@key='ClientServicesCredentialType']").Value = $auth
$CustomConfig.SelectSingleNode("//appSettings/add[@key='PublicWebBaseUrl']").Value = $PublicWebBaseUrl
$CustomConfig.SelectSingleNode("//appSettings/add[@key='PublicSOAPBaseUrl']").Value = "$protocol${hostname}:7047/NAV/WS"
$CustomConfig.SelectSingleNode("//appSettings/add[@key='PublicODataBaseUrl']").Value = "$protocol${hostname}:7048/NAV/OData"
$developerServicesKeyExists = ($customConfig.SelectSingleNode("//appSettings/add[@key='DeveloperServicesPort']") -ne $null)
if ($developerServicesKeyExists) {
    $customConfig.SelectSingleNode("//appSettings/add[@key='DeveloperServicesPort']").Value = "7049"
    $customConfig.SelectSingleNode("//appSettings/add[@key='DeveloperServicesEnabled']").Value = $windowsAuth.ToString().ToLower()
}
if ($useSSL) {
    $CustomConfig.SelectSingleNode("//appSettings/add[@key='ServicesCertificateThumbprint']").Value = "$thumbprint"
    $CustomConfig.SelectSingleNode("//appSettings/add[@key='ServicesCertificateValidationEnabled']").Value = "false"
    $CustomConfig.SelectSingleNode("//appSettings/add[@key='SOAPServicesSSLEnabled']").Value = "true"
    $CustomConfig.SelectSingleNode("//appSettings/add[@key='ODataServicesSSLEnabled']").Value = "true"
    if ($developerServicesKeyExists) {
        $CustomConfig.SelectSingleNode("//appSettings/add[@key='DeveloperServicesSSLEnabled']").Value = "true"
    }
}
$CustomConfig.Save($CustomConfigFile)
