# This script allows you to deploy a task sequence
# Niall Brady 2015/3/29
#
# Connect to ConfigMgr
#
$CMDrive="E:"
$SiteCode="PS1:\"
Import-Module $CMDrive'\Program Files\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1'
Set-Location $SiteCode
#
# set variables for the deployment 
#
$TaskSequenceName = "Windows 8.1 Enterprise x64 - 150301" 
$TaskSequencePackageId = (Get-CMTaskSequence -Name $TaskSequenceName).PackageID 
$CollectionName = "OSD Deploy" 
$DeployPurpose = "Available"
$MakeAvailableTo = "MediaAndPxe"
#
# deploy the task sequence
#
Start-CMTaskSequenceDeployment `
–TaskSequencePackageId $TaskSequencePackageId `
–CollectionName $CollectionName `
–Deploypurpose $DeployPurpose `
-MakeAvailableTo $MakeAvailableTo 