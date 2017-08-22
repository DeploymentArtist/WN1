# This script creates an operating system image package and then distributes it to the distribution point
# It requires the contents of the operating system package to be copied to the $OperatingSystemImageSource
# Niall Brady 2015/3/28
#
$OperatingSystemImageArch = "x64"
$OperatingSystemLongName = "Windows 8.1 Enterprise"
$OperatingSystemShortName = "W81"
$OperatingSystemImageVersion = "150301"
$OperatingSystemImageWimFile = $OperatingSystemShortName + "_" + $OperatingSystemImageVersion + ".wim"
$OperatingSystemImageName = $OperatingSystemLongName + " - " + $OperatingSystemImageVersion
$OperatingSystemImageSource = "\\CM01.corp.viamonstra.com\Sources\OSD\OS\Operating System Images\" + $OperatingSystemLongName + " " + $OperatingSystemImageArch + "\" + $OperatingSystemImageWimFile
$DistributionPointName = "CM01.corp.viamonstra.com"
# connect to ConfigMgr
$CMDrive="E:"
$SiteCode="PS1:\"
Import-Module $CMDrive'\Program Files\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1'
Set-Location $SiteCode
# create the Operating System Image package
New-CMOperatingSystemImage -Name $OperatingSystemImageName -Path $OperatingSystemImageSource -Version $OperatingSystemImageArch 
# distribute the operating system image package
Start-CMContentDistribution -OperatingSystemImageName $OperatingSystemImageName –DistributionPointName $DistributionPointName