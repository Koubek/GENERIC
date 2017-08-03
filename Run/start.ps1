Set-ExecutionPolicy Unrestricted

$runPath = "c:\Run"
$myPath = Join-Path $runPath "my"

function Get-MyFilePath([string]$FileName)
{
    if ((Test-Path $myPath -PathType Container) -and (Test-Path (Join-Path $myPath $FileName) -PathType Leaf)) {
        (Join-Path $myPath $FileName)
    } else {
        (Join-Path $runPath $FileName)
    }
}

. (Get-MyFilePath "HelperFunctions.ps1")
. (Get-MyFilePath "navstart.ps1")

$lastCheck = (Get-Date).AddSeconds(-2) 
while ($true) 
{ 
    Get-EventLog -LogName Application -After $lastCheck -ErrorAction Ignore | Where-Object { ($_.Source -like '*Dynamics*' -or $_.Source -eq $SqlServiceName) -and $_.EntryType -ne "Information" -and $_.EntryType -ne "0" } | Select-Object TimeGenerated, EntryType, Message | format-list
    $lastCheck = Get-Date 
    Start-Sleep -Seconds 2
}
