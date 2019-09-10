[Cmdletbinding(DefaultParameterSetName = 'file')] 
param(
    [parameter(Mandatory = $true, ParameterSetName = 'File')]$sourcefile,
    [parameter(Mandatory = $false)]$SQLtable = "dirinfo",
    [parameter(Mandatory = $false)]$SQLdatabase = "powershelldemo",
    [parameter(Mandatory = $false)]$SQLservername = "vikkedinger.database.windows.net",
    [parameter(Mandatory = $false)]$username,
    [parameter(Mandatory = $false)]$password
    
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
    $connection = open-SQLdatabase -servername $SQLservername -databasename $SQLdatabase -username $username -password $password
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
    $i2++
    try {
        add-toSQLtablebulk -connection $connection -tablename $SQLtable -SO $line
        }
    catch {
        $Error[0]
        break
    }
}
close-SQLdatabase -connection $connection