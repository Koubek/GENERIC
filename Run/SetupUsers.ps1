if ($auth -eq "Windows") {
    if ($password -ne "_") {
        New-LocalUser -AccountNeverExpires -FullName $username -Name $username -Password (ConvertTo-SecureString -AsPlainText -String $password -Force) -ErrorAction Ignore | Out-Null
        Add-LocalGroupMember -Group administrators -Member $username -ErrorAction Ignore
    }
    if ($username -ne "_") {
        if (!(Get-NAVServerUser -ServerInstance NAV | Where-Object { $_.UserName.EndsWith("'\$username") })) {
            New-NavServerUser -ServerInstance NAV -WindowsAccount $username
            New-NavServerUserPermissionSet -ServerInstance NAV -WindowsAccount $username -PermissionSetId SUPER
        }
    }
} else {
    $username = "admin"
    if (!(Get-NAVServerUser -ServerInstance NAV | Where-Object { $_.UserName -eq $username })) {
        $password = Get-RandomPassword
        New-NavServerUser -ServerInstance NAV -Username $username -Password (ConvertTo-SecureString -String $password -AsPlainText -Force)
        New-NavServerUserPermissionSet -ServerInstance NAV -username $username -PermissionSetId SUPER
        Write-Host "NAV Admin Username  : $username"
        Write-Host "NAV Admin Password  : $password"
    }
}

if ($password -ne "_") {
    $sqlcmd = "ALTER LOGIN sa with password=" +"'" + $password + "'" + ";ALTER LOGIN sa ENABLE;"
    & sqlcmd -Q $sqlcmd
}