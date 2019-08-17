
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
    . add-toSQLtable -Connection $connection -tablename "Testtable" -object "$SO"
    

    #>
    [Cmdletbinding()] 
    param(
        [parameter(Mandatory = $true)]
        $connection,
        [parameter(Mandatory = $true)]
        $tablename,
        [parameter(Mandatory = $true)]
        $object
              
    ) 

   
    $columnnames = ($object| select-object -First 1).psobject.properties.name 

    [string]$columnstring = "([" + ($columnnames -join "],[") + "])"
    [string]$parametercountstring = "(" + ("@" + ($columnnames -join ",@")) + ")"
    $SQLinsert = @("INSERT INTO $tablename " + $columnstring + " VALUES " + $parametercountstring + ";") 
    
    $command = $connection.CreateCommand()
    
    foreach ($Item in $object) {
        
        try {
            $command.Parameters.Clear()
            $command.CommandText = $SQLinsert
            
            foreach ($columnname in $columnnames) {
                if ([string]::IsNullOrEmpty($Item.$columnname)) {
                    $Item.$columnname = "NULL"
                }
                [void]$command.Parameters.Add("@$columnname", $Item.$columnname)
                
            
            }
                    
            [void]$command.ExecuteNonQuery() 
    
        }
        
        catch {
            throw $Error[0]
        }
    }
   

}

function add-toSQLtablebulk {
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
        throw $Error[0] 
    }
    
}

function remove-SQLtable {
    [Cmdletbinding()] 
    param([parameter(Mandatory = $false)]$connection,
        [parameter(Mandatory = $false)]$tablename
              
              
    ) 
    try {
        $command = $connection.CreateCommand()        
        $command.CommandText = "drop table $tablename"
                  
      
        [void]$command.ExecuteNonQuery()
            
    }
        
    catch {
        $Error[0] | Out-Host
    }

}

function new-SQLtable {
    [Cmdletbinding()] 
    param([parameter(Mandatory = $false)]$connection,
        [parameter(Mandatory = $false)]$tablename,
        [parameter(Mandatory = $false)]$SO
              
    ) 
    try {
        $command = $connection.CreateCommand()
        
        $command.CommandText = "Select * from $tablename" 
        $command.Parameters.Clear()
        $reader = $command.ExecuteReader()           
        $reader.Close()
    }
    catch [System.Management.Automation.MethodInvocationException] {
        
            
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
            $Error[0] | out-host
        }
    }
    
}

function open-SQLdatabase {
    [Cmdletbinding(DefaultParameterSetName = "WindowsAuth")] 
    param([parameter(Mandatory = $false)]
        [string]$servername,
        [parameter(Mandatory = $false)]
        [string]$instancename,
        [parameter(Mandatory = $false)]
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
        #needs work
        $connection.ConnectionString = "Server = $serverstring ; Database = $databasename; Integrated Security = True;" 
        
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

function close-SQLdatabase {
    [Cmdletbinding()] 
    param([parameter(Mandatory = $false)]$connection            
              
    ) 
    try {
        $connection.Close()
        $connection.Dispose()
        "Closed connection " + $connection.DataSource | Out-Host
    }
    catch {
        $Error[0] | write-log -type Error
        "Failed to close connection to " + $connection.DataSource | write-log -type error
    }
}

function get-SQLtableinfo {
    [Cmdletbinding()] 
    param([parameter(Mandatory = $false)]$connection,
        [parameter(Mandatory = $false)]$tablename           
              
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
        $Error[0]
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

Export-ModuleMember -Function * -Alias *