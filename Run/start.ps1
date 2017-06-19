if ((Test-Path "c:\share" -PathType Container) -and (Test-Path "c:\share\mynavstart.ps1" -PathType Leaf)) {
    . C:\Share\mynavstart.ps1
}
. C:\Run\navstart.ps1

$lastCheck = (Get-Date).AddSeconds(-2) 
while ($true) 
{ 
    Get-EventLog -LogName Application -After $lastCheck -ErrorAction Ignore | Where-Object { $_.EntryType -ne "Information" -and $_.EntryType -ne "0" } | Select-Object TimeGenerated, EntryType, Message | format-list
    $lastCheck = Get-Date 
    Start-Sleep -Seconds 2
}
