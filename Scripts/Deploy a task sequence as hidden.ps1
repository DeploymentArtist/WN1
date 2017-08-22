# This script allows you to deploy a task sequence and made available as hidden
# Niall Brady 2015/5/9
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
$MakeAvailableTo = "MediaAndPxeHidden"
#
# deploy the task sequence
#
Start-CMTaskSequenceDeployment `
–TaskSequencePackageId $TaskSequencePackageId `
–CollectionName $CollectionName `
–Deploypurpose $DeployPurpose `
-MakeAvailableTo $MakeAvailableTo 