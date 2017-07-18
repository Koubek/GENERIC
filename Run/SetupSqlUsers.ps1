﻿if ($password -ne "_") {
    $sqlcmd = "ALTER LOGIN sa with password=" +"'" + $password + "'" + ";ALTER LOGIN sa ENABLE;"
    & sqlcmd -Q $sqlcmd
}

if ($username.Contains('\') -and $windowsAuth) {
    $sqlcmd = 
        "IF NOT EXISTS 
            (SELECT name  
            FROM master.sys.server_principals
            WHERE name = '$username')
        BEGIN
            CREATE LOGIN [$username] FROM WINDOWS
            EXEC sp_addsrvrolemember '$username', 'sysadmin'
        END
        
        ALTER LOGIN [$username] ENABLE
        GO"
        
    & sqlcmd -Q $sqlcmd
}
