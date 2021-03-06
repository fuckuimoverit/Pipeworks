$connStr = Get-SecureSetting LocalMySqlConnection -ValueOnly
$mySqlConnection = $connStr -replace "Database=(\w{1,});", ''


$dbName = Get-Random

New-SQLDatabase -DatabaseName "TestDB$dbName" -useMySql -ConnectionStringOrSetting $mySqlConnection

$mySqlConnection += ";Database=testdb$dbName"

#Add-SqlTable -DatabasePath $randomDatabasePath -UseSqlCompact -TableName "TestTable" -Column a,b -KeyType Sequential -DataType integer, integer

$inputObjs = @()
$inputObjs += New-Object PSObject -Property @{
    "a" = Get-Random
    "B" = Get-Random
} 
$o = New-Object PSObject -Property @{
    "a" = Get-Random
    "B" = Get-Random
}
$o.pstypenames.clear()
$o.pstypenames.add('a')
$inputObjs += $o 
$inputObjs |
    Update-Sql -UseMySql -TableName "TestTable" -Force -ConnectionStringOrSetting $mySqlConnection 

$dbobjs = Select-SQL -FromTable TestTable -UseMySql -ConnectionStringOrSetting $mySqlConnection


$dbobjs |
    Add-Member NoteProperty B (Get-Random) -Force -PassThru |
    Update-Sql -UseMySql -TableName "TestTable" -Force  -ConnectionStringOrSetting $mySqlConnection 


Select-SQL -FromTable TestTable -UseMySql -ConnectionStringOrSetting $mySqlConnection

Remove-SQL -TableName TestTable -Where "RowKey = '$($dbobjs[0].RowKey.ToString().Trim())' "  -UseMySql -ConnectionStringOrSetting $mySqlConnection -Confirm:$false

Select-SQL -FromTable TestTable -UseMySql -ConnectionStringOrSetting $mySqlConnection

Remove-SQL -TableName TestTable -UseMySql -ConnectionStringOrSetting $mySqlConnection -Confirm:$false  


$mySqlConnection = $connStr -replace "Database=(\w{1,});", ''
Select-SQL -ConnectionStringOrSetting $connStr -UseMySql -Query "drop database TestDB$dbName"


#Remove-Item -Path $randomDatabasePath 
