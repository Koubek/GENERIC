if ($password -ne "_") {
    $sqlcmd = "ALTER LOGIN sa with password=" +"'" + $password + "'" + ";ALTER LOGIN sa ENABLE;"
    & sqlcmd -Q $sqlcmd
}
