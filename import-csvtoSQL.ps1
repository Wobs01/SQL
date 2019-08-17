[Cmdletbinding(DefaultParameterSetName = 'file')] 
param(
    [parameter(Mandatory = $true, ParameterSetName = 'File')]$sourcefile,
    [parameter(Mandatory = $false)]$SQLtable = "SQLauditinfo",
    [parameter(Mandatory = $false)]$SQLdatabase = "Auditlog",
    [parameter(Mandatory = $false)]$SQLinstancename  = "SQLmgmt_prd"
    
)



$script:timestamp = Get-Date
$SQLmodule = "$PSScriptRoot\SQLmgmt.psm1"


try {
    $CSV = Import-Csv -Path $sourcefile -ErrorAction Stop     
    }
catch {
    $Error[0].exception | out-host
    "Unable to open $($sourcefile)" |  out-host 
    $CSV = $null   
}

try {
    Import-Module $SQLmodule -ErrorAction Stop
    $connection = open-SQLdatabase -servername $env:COMPUTERNAME -instancename $SQLinstancename -databasename $SQLdatabase
    }
catch {
    $connection = $null
    "SQL connection not available" | Out-Host
}
$i2 = 1
foreach ($line in $csv) {
    Write-Progress -Activity "processing $i2 of $($csv.count)" -PercentComplete (($i2/$csv.Count) * 100)
    if ($i2 -le 1) {
        new-SQLtable -tablename $SQLtable -connection $connection -SO $line        
    }
    $line.timestamp = [datetime]$line.timestamp
    $i2++
    add-toSQLtable -connection $connection -tablename $SQLtable -SO $line
}
close-SQLdatabase -connection $connection