# Script to import a computer into the All Systems collection in ConfigMgr
# Niall Brady 2015/3/8
# Define some variables first

$ComputerName="REF001"
$MacAddress= "00:15:5d:00:ac:4a"
$CollectionName = "All Systems"

Import-CMComputerInformation -ComputerName $ComputerName -MacAddress $MacAddress -CollectionName $CollectionName