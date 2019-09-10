git
https://github.com/Wobs01/SQL

integration with vscode
commit

module 

Get-Command -Module azure | Select-Object -First 10

import-module .\sqlmgmt

get-command -module sqlmgmt

psm1

export-modulemember
internal functions

azure database
azure console
Query editor

open-SQLdatabase
get-help open-SQLdatabase

paramaters
parametersets
$PSCmdlet.ParameterSetName

connection.open()

$connection = open-SQLdatabase -servername vikkedinger.database.windows.net -databasename Powershelldemo -username robin -password

new-SQLtable
catch specific exception
select psobjecttype
columntype
Create query in commandtext
Executenonquery

new-SQLtable -Connection $connection -tablename "connectiontable" -SO $connection

$dirinfo = get-childitem

new-SQLtable -Connection $connection -tablename "dirinfo" -SO $dirinfo

add-toSQLtable
extract columns
create query string
add paramater values

add-toSQLtable -Connection $connection -tablename "connectiontable" -SO $connection
debug

add-toSQLtablebulk
sqlbulkcopy object
converttodatatable
writetoserver
writetoserverasync

add-toSQLtablebulk -Connection $connection -tablename "dirinfo" -SO $dirinfo
add-toSQLtablebulk -Connection $connection -tablename "dirinfo" -SO $dirinfo -useasync



.\import-csvtoSQL.ps1 -SQLtable "dirinfo" -sourcefile .\testcsv.csv -username robin -password 

.\import-csvtoSQL.ps1 -SQLtable "dirinfo2" -sourcefile .\testcsv.csv -username robin -password 

ORDER BY

get-SQLtablecontent
createcommand
commandtext
databable 
reader
get-SQLtablecontent -Connection $connection -tablename "dirinfo"


permformance
adjust script into bulk and bulkasync
.\import-csvtoSQL.ps1 -SQLtable "dirinfo3" -sourcefile .\testcsv.csv -username robin -password 

$datatable = get-SQLtablecontent -Connection $connection -tablename "dirinfo2"
$SO = import-csv .\testcsv.csv

measure-command {add-toSQLtable -Connection $connection -tablename "dirinfo3" -SO $SO}
measure-command {add-toSQLtablebulk -Connection $connection -tablename "dirinfo3" -datatable $datatable}
measure-command {add-toSQLtablebulk -useasync -Connection $connection -tablename "dirinfo3" -datatable $datatable}

new-SQLcustomquery -Connection $connection -querystring "SELECT * FROM TABLE test WHERE PSCHILDNAME='README.md'"

remove-SQLtable -Connection $connection -tablename "dirinfo2" 
remove-SQLtable -Connection $connection -tablename "dirinfo3" 

Close-SQLdatabase
$connection.close and dispose

Use cases
