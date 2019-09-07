function open-SQLdatabase {
    <#   
   .SYNOPSIS   
   Function to connect to a SQL database
       
   .DESCRIPTION 
   Opens a connection to a sql database. Returns the open connection which can be used to follow up on other functions

   .NOTES	
       Author: Robin Verhoeven
       Requestor: -
       Created: -
       
       

   .LINK
       https://github.com/Wobs01/SQL

   .EXAMPLE   
   . open-SQLdatabase -servername "foo@bar.corp" -instancename "vikkedinger" -databasename "testdatabase" -usewindowsauthentication
   

   #>
   
   
   [Cmdletbinding(DefaultParameterSetName = "WindowsAuth")] 
   param([parameter(Mandatory = $true)]
       [string]$servername,
       [parameter(Mandatory = $false)]
       [string]$instancename,
       [parameter(Mandatory = $true)]
       [string]$databasename,
       [parameter(Mandatory = $false,ParameterSetName='WindowsAuth')]
       [switch]$usewindowsauthentication,
       [parameter (Mandatory = $false,ParameterSetName='SQLAuth')]
       [string]$username,
       [parameter (Mandatory = $false,ParameterSetName='SQLAuth')]
       [string]$password
             
   ) 
   if ($instancename) {
       $serverstring = "$servername\$instancename"
   }
   else {
       $serverstring = $servername
   }

   try {
       $connection = New-Object System.Data.SqlClient.SqlConnection
       [string]$connectionstring = "Server = $serverstring; Database = $databasename;"
       switch ($PSCmdlet.ParameterSetName) {
           "WindowsAuth" { 
               $connectionstring += " Integrated Security = True;"
           }
           "SQLAuth" {
               $connectionstring += " Integrated Security = False;"
               $connectionstring += "User ID = $username;"
               $connectionstring += "Password = $password;"
           }
       }
               
       $connection.ConnectionString = $connectionstring
       
       $connection.Open()
       "Successfully connected to $serverstring"  | Out-Host
   }
   catch {
       $Error[0] | Out-Host
       $connection = $null
       "failed to connect to $serverstring"  | Out-Host
   }

   return $connection
}

function new-SQLtable {
    <#   
   .SYNOPSIS   
   Function to create a new SQL table
       
   .DESCRIPTION 
   Function to create a new SQL table and create the table and data types based on the system object values
   Includes test if table already exists
   Values default to VARCHAR(MAX)

   .NOTES	
       Author: Robin Verhoeven
       Requestor: -
       Created: -
       
       

   .LINK
       https://github.com/Wobs01/SQL

   .EXAMPLE   
   . new-SQLtable -Connection $connection -tablename "Testtable" -SO $SO
   

   #>
   
   
   [Cmdletbinding()] 
   param([parameter(Mandatory = $true)]
       $connection,
       [parameter(Mandatory = $true)]
       [string]$tablename,
       [parameter(Mandatory = $true)]
       $SO
             
   ) 
   try {
       $command = $connection.CreateCommand()        
       $command.CommandText = "Select top 1 * from $tablename" 
       $command.Parameters.Clear()
       $reader = $command.ExecuteReader()           
       $reader.Close()
   }
   catch [System.Management.Automation.MethodInvocationException] {
       
       #select different type of data types and columns    
       $columnnames = ($SO| select-object -First 1).psobject.properties.name 
       $columntypes = ($SO| select-object -First 1).psobject.properties.TypeNameOfValue
       $i = 0
       [string]$SQLcreate = "CREATE TABLE " + $tablename + " ("
       foreach ($columnname in $columnnames) {
               
           $columntype = $columntypes[$i].split("\.")[-1]
               
           switch ($true) {
               ($columntype -eq "Datetime") {
                   $SQLcolumntype = "DATETIME" 
               }
               ($columntype -eq "GUID") {
                   $SQLcolumntype = "UNIQUEIDENTIFIER"
               }
               ($columntype -eq "INT32") {
                   $SQLcolumntype = "INTEGER"
               }
               #more datatypes could be added
               default {
                   $SQLcolumntype = "VARCHAR(MAX)" 
               }
           }
           $SQLcreate = $SQLcreate + "[" + $columnname + "] " + $SQLcolumntype + ","
           $I++
                      
       }  
       $SQLcreate = ($SQLcreate -replace ".$") + ");"   
       try {
           $command = $connection.CreateCommand()
               
           $command.CommandText = $SQLcreate
           [void]$command.ExecuteNonQuery()
       }
       catch {
           write-host -ForegroundColor Red "Unable to create $tablename`n`n$($Error[0])" 
       }
   }
   
}

function add-toSQLtable {
    <#   
    .SYNOPSIS   
    Function to convert a system object to a SQL query and insert it into the table
        
    .DESCRIPTION 
    Function to convert a system object to a SQL query and insert it into the table

    .NOTES	
        Author: Robin Verhoeven
        Requestor: -
        Created: -
        
        

    .LINK
        https://github.com/Wobs01/SQL

    .EXAMPLE   
    . add-toSQLtable -Connection $connection -tablename "Testtable" -SO $SO
    

    #>
    [Cmdletbinding()] 
    param(
        [parameter(Mandatory = $true)]
        $connection,
        [parameter(Mandatory = $true)]
        $tablename,
        [parameter(Mandatory = $true)]
        $SO
              
    ) 

   
    $columnnames = ($SO| select-object -First 1).psobject.properties.name 

    [string]$columnstring = "([" + ($columnnames -join "],[") + "])"
    [string]$parametercountstring = "(" + ("@" + ($columnnames -join ",@")) + ")"
    $SQLinsert = @("INSERT INTO $tablename " + $columnstring + " VALUES " + $parametercountstring + ";") 
    
    $command = $connection.CreateCommand()
    
    foreach ($Item in $SO) {
        
        try {
            $command.Parameters.Clear()
            $command.CommandText = $SQLinsert
            
            foreach ($columnname in $columnnames) {
                
                [void]$command.Parameters.Add("@$columnname", [string]$Item.$columnname)
                
            }
                    
            [void]$command.ExecuteNonQuery() 
    
        }
        
        catch {
            $Error[0].Exception
        }
    }
   

}

function add-toSQLtablebulk {
    <#   
    .SYNOPSIS   
    Function to add to a SQL table in bulk
        
    .DESCRIPTION 
    Function to add to a SQL table in bulk, either synchronous or asynchronous

    .NOTES	
        Author: Robin Verhoeven
        Requestor: -
        Created: -
        
        

    .LINK
        https://github.com/Wobs01/SQL

    .EXAMPLE   
    . add-toSQLtablebulk -Connection $connection -tablename "Testtable" -SO $SO -useasync
    

    #>
    [Cmdletbinding()] 
    param([parameter(Mandatory = $true)]
        $connection,
        [parameter(Mandatory = $true)]
        [string]$tablename,
        [parameter(Mandatory = $true)]
        $SO,
        [parameter(Mandatory = $false)]
        [switch]$useasync
              
    ) 
    try {
        $bulk = new-object ("System.Data.SqlClient.SqlBulkCopy") $connection
        $bulk.DestinationTableName = $tablename
        $datatable = add-datatable -inputobject $SO
        if ($useasync) {
            $bulk.WriteToServerAsync($datatable)
        }
        else {
            $bulk.WriteToServer($datatable) #| Out-Null
        }
    }
    catch {
        throw "Unable to write data to $tablename`n`n$($Error[0])" 
    }
    
}

function remove-SQLtable {
    <#   
    .SYNOPSIS   
    Function to add to drop a SQL table
        
    .DESCRIPTION 
    Function to add to drop a SQL table

    .NOTES	
        Author: Robin Verhoeven
        Requestor: -
        Created: -
        
        

    .LINK
        https://github.com/Wobs01/SQL

    .EXAMPLE   
    . remove-SQLtable -Connection $connection -tablename "Testtable" 
    

    #>
    
    [Cmdletbinding()] 
    param([parameter(Mandatory = $true)
        ]$connection,
        [parameter(Mandatory = $true)]
        [string]$tablename
              
              
    ) 
    try {
        $command = $connection.CreateCommand()        
        $command.CommandText = "drop table $tablename"
        [void]$command.ExecuteNonQuery()
            
    }
        
    catch {
        throw "Unable to remove $tablename`n`n$($Error[0])" 
    }

}

function close-SQLdatabase {
    <#   
    .SYNOPSIS   
    Function to close the connection to a SQL database
        
    .DESCRIPTION 
    Function to close the connection to a SQL database, requires an open connection and a valid connection object

    .NOTES	
        Author: Robin Verhoeven
        Requestor: -
        Created: -
        
        

    .LINK
        https://github.com/Wobs01/SQL

    .EXAMPLE   
    . close-SQLdatabase -Connection $connection" 
    

    #>
    
    
    [Cmdletbinding()] 
    param([parameter(Mandatory = $true)]
    $connection            
              
    ) 
    try {
        $connection.Close()
        $connection.Dispose()
        "Closed connection " + $connection.DataSource | Out-Host
    }
    catch {        
        throw "Failed to close connection to $($connection.DataSource)`n`n$($Error[0])"  
    }
}

function get-SQLtablecontent {
     <#   
    .SYNOPSIS   
    Function to get all content from a SQLtable
        
    .DESCRIPTION 
    Function to get all content from a SQLtable, outputs a datatable

    .NOTES	
        Author: Robin Verhoeven
        Requestor: -
        Created: -
        
        

    .LINK
        https://github.com/Wobs01/SQL

    .EXAMPLE   
    . get-SQLtablecontent -Connection $connection -tablename "test2" 
    

    #>
    
    
    [Cmdletbinding()] 
    param([parameter(Mandatory = $true)]
        $connection,
        [parameter(Mandatory = $true)]
        [string]$tablename           
              
    ) 
    try {
        $command = $connection.createcommand()      
        
        $command.CommandText = "Select * from $tablename" 
        $command.Parameters.Clear()
        $reader = $command.ExecuteReader()
        $result = New-Object System.Data.DataTable
        $result.Load($reader)       
        $reader.Close()
    }
    catch {
        throw "Failed to get content from $tablename`n`n$($Error[0])"  
    }
    
    return $result

}


function new-SQLcustomquery {
    [Cmdletbinding()] 
    param([parameter(Mandatory = $true)]
        $connection,
        [parameter(Mandatory = $true)]
        [string]$querystring           
              
    ) 
    try {
        $command = $connection.createcommand()      
        
        $command.CommandText = $querystring 
        $command.Parameters.Clear()
        $reader = $command.ExecuteReader()
        $result = New-Object System.Data.DataTable
        $result.Load($reader)       
        $reader.Close()
    }
    catch {
        throw "Failed to get content from $tablename`n`n$($Error[0])"  
    }
    
    return $result

}


function add-datatable ($inputobject) {
    $datatable = new-object System.data.datatable
    $columnnames = ($inputobject | select-object -First 1).psobject.properties.name 
    $columnnames | foreach-object {$datatable.Columns.Add($_)} | Out-Null
    foreach ($object in $inputobject) {        
        $row = $datatable.NewRow()
        foreach ($column in $columnnames) {
            $row.item($column) = $object.$column
        }
        $datatable.Rows.Add($row)
    }
    return , $datatable
}

Export-ModuleMember -Function open-SQLdata, new-SQLtable, add-toSQLtable, add-toSQLtablebulk, remove-SQLtable, close-SQLdatabase, get-SQLtablecontent, new-SQLcustomquery -Alias *