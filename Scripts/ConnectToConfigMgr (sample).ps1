# This script allows you to connect to ConfigMgr in order to use the ConfigMgr PowerShell cmdlets
# change the $CMDrive and $Sitecode variables to match your infrastructure
# Niall Brady 2015/3/1
$CMDrive="E:"
$SiteCode="PS1:\"
Import-Module $CMDrive'\Program Files\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1'
Set-Location $SiteCode