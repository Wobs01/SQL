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
Create query