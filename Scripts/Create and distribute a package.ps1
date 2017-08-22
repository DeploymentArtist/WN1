#
# This script creates a package and then distributes it to the distribution point
# requires the contents of the package to be copied to the $PackageSource
# Niall Brady 2015/3/16
#
$PackageSource = "\\CM01.corp.viamonstra.com\Sources\OSD\OS\Operating System Start Screens\Windows 8.1 x64 Start Screen"
$PackageName = "Windows 8.1 x64 Start Screen"
$PackageDescription = ""
$PackageVersion = ""
$PackageLanguage = ""
$PackageManufacturer = ""
$DistributionPointName = "CM01.corp.viamonstra.com"
# connect to ConfigMgr
$CMDrive="E:"
$SiteCode="PS1:\"
Import-Module $CMDrive'\Program Files\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1'
Set-Location $SiteCode
# create the package
New-CMPackage –Name $PackageName –Version $PackageVersion –Description $PackageDescription –Language $PackageLanguage –Manufacturer $PackageManufacturer –Path $PackageSource
# distribute the package
Start-CMContentDistribution –PackageName $PackageName –DistributionPointName $DistributionPointName