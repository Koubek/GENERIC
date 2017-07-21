$username = "$env:username"
if ($username -eq "ContainerAdministrator") {
    $username = ""
}
$password = "$env:password"
$licensefile = "$env:licensefile"
$bakfile = "$env:bakfile"
$databaseServer = "$env:databaseServer"
$databaseInstance = "$env:databaseInstance"
$databaseName = "$env:databaseName"
$Accept_eula = "$env:Accept_eula"
