# Copy custom Add-ins in place
$AddinsFolder = (Join-Path $PSScriptRoot "Add-ins")
if (Test-Path $AddinsFolder -PathType Container) {
    copy-item -Path (Join-Path $AddinsFolder "*") -Destination (Join-Path $ServiceTierFolder "Add-ins") -Recurse
    copy-item -Path (Join-Path $AddinsFolder "*") -Destination (Join-Path $RoleTailoredClientFolder "Add-ins") -Recurse
}
