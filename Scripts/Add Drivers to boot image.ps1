# This script adds drivers to a boot image by driver id and then updates the boot image to the dp, assumes boot image is already distributed to the dp
# Niall Brady 2015/4/6
# 
# connect to ConfigMgr
$CMDrive="E:"
$SiteCode="PS1:\"
Import-Module $CMDrive'\Program Files\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1'
Set-Location $SiteCode

# add driver to boot image using driver ID, there are two drivers, each with their own unique CI-ID (DriverID)
$DriverName = "Surface Ethernet Adapter"
$DriversToSearch = (Get-CMDriver -name $DriverName).CI_ID 
$BootImageName = "Boot Image (x64)"
# look for drivers matching the DriverName
foreach($DriverId in $DriversToSearch)
{
Write-Host "Importing the following driver: '$DriverName' with CI_ID:" $DriverId
Set-CMDriverBootImage -SetDriveBootImageAction AddDriverToBootImage -DriverId $DriverId -BootImageName $BootImageName
}
Write-Host "Updating boot image: '$BootImageName' to distribution points"
Update-CMDistributionPoint -BootImageName $BootImageName 
Write-Host "Completed."