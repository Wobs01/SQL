git
https://github.com/Wobs01/SQL


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
ORDER BY

get-SQLtablecontent
createcommand
commandtext
databable 
reader
get-SQLtablecontent -Connection $connection -tablename "dirinfo"

new-SQLcustomquery -Connection $connection -querystring "SELECT * FROM TABLE test WHERE PSCHILDNAME='README.md'"

Close-SQLdatabase
$connection.close and dispose

Use cases
