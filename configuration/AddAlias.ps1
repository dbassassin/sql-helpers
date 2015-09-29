#Enter the path of the Alises.csv file.  The below code would be if you had the script and file in the same directory
$csvFilename = $PSScriptRoot + "\Aliases.csv"
$csv = Import-Csv $csvFilename -Header @("ServerName","Address","Port")

foreach ($line in $csv) {
    #Debug Statement
    #Write-Host "ServerName=$line.ServerName Address=$line.Address Port=$line.Port" 
    #[String]$RegPath = 'HKLM:\SOFTWARE\Microsoft\MSSQLServer\Client\ConnectTo'
    #The below line would be if you needed to add 32bit aliases
    [String]$RegPath = 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\MSSQLServer\Client\ConnectTo'
    [String]$RegName = $line.ServerName
    [String]$RegData = "DBMSSOCN," +  $line.Address + "," + $line.Port
    #Debug Statements
    #Write-Host $RegName
    #Write-Host $RegData
    New-ItemProperty -Path $RegPath -Name $RegName -PropertyType String -Value $RegData
}