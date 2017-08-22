# distribute a package
# Niall Brady 2015/3/28
# replace the $PackageName variable to point to an already created (but not yet distributed) package.
#
$PackageName = "User State Migration Tool for Windows 8.1"
$DistributionPointName = "CM01.corp.viamonstra.com"
# connect to ConfigMgr
$CMDrive="E:"
$SiteCode="PS1:\"
Import-Module $CMDrive'\Program Files\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1'
Set-Location $SiteCode
# add the -Verbose switch if the content is not doing as expected.
Start-CMContentDistribution -PackageName $PackageName –DistributionPointName $DistributionPointName 