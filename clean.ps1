#throw "Do not run script!"

# Remove orphan containers and images
Get-ContainerImage | Where-Object { $_.RepoTags.Count -eq 1 -and $_.RepoTags[0] -eq "<none>:<none>" } | % {
    Write-Host $_.ID
    $img = $_
    Get-Container | Where-Object { $_.ImageID -eq $img.ID } | Remove-Container -Force
    Remove-ContainerImage -ImageIdOrName $img.ID -Force
}

# Remove generic containers
Get-ContainerImage | Where-Object { $_.RepoTags.Count -eq 1 -and $_.RepoTags[0] -eq "navdocker.azurecr.io/nav/generic:latest" } | % {
    Write-Host $_.ID
    $img = $_
    Get-Container | Where-Object { $_.ImageID -eq $img.ID } | Remove-Container -Force
    # Leave generic container image
    #Remove-ContainerImage -ImageIdOrName $img.ID -Force
}
