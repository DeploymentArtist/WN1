# This script creates a deploy task sequence
# Niall Brady 2015/3/29
#
# Connect to ConfigMgr
#
$CMDrive="E:"
$SiteCode="PS1:\"
Import-Module $CMDrive'\Program Files\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1'
Set-Location $SiteCode
#
# Define the task sequence variables
#
$TaskSequenceName = "Windows 8.1 Enterprise x64 - 150301"
$TaskSequenceDescription = "ConfigMgr deploy task sequence"
$OperatingSystemImage = "Windows 8.1 Enterprise - 150301"
$BootImageName = "Boot Image (x64)"
$JoinDomain = "DomainType" # alternative is WorkgroupType
$BootImagePackageId  = (Get-CMBootImage -Name $BootImageName).PackageID
$OperatingSystemImagePackageId = (Get-CMOperatingSystemImage -Name $OperatingSystemImage).PackageID
$OperatingSystemImageIndex = "1"
$DomainName = "CORP.VIAMONSTRA.COM"
$DomainAccount = $DomainName + "\" + "CM_JD"
$DomainPassword = convertto-securestring "P@ssw0rd" -asplaintext -force
$DomainOrganizationUnit = "LDAP://OU=Workstations,OU=ViaMonstra,DC=corp,DC=viamonstra,DC=com"
$ClientPackagePackageId = (Get-CMPackage -Name 'ConfigMgr Client with Hotfixes').PackageID
$LocalAdminPassword = convertto-securestring "P@ssw0rd" -asplaintext -force
$UserStateMigrationToolPackageId = (Get-CMPackage -Name 'User State Migration Tool for Windows 8.1').PackageID
#
# Create the task sequence
#
New-CMTaskSequence -InstallOperatingSystemImageOption `
  -TaskSequenceName $TaskSequenceName `
  -TaskSequenceDescription $TaskSequenceDescription `
  -BootImagePackageId $BootImagePackageId `
  -OperatingSystemImagePackageId $OperatingSystemImagePackageId `
  -OperatingSystemImageIndex $OperatingSystemImageIndex `
  -ClientPackagePackageId $ClientPackagePackageId `
  -JoinDomain $JoinDomain `
  -DomainAccount $DomainAccount `
  -DomainName $DomainName `
  -DomainOrganizationUnit $DomainOrganizationUnit `
  -DomainPassword $DomainPassword `
  -PartitionAndFormatTarget $True `
  -LocalAdminPassword $LocalAdminPassword `
  -UserStateMigrationToolPackageId $UserStateMigrationToolPackageId `
  -ConfigureBitLocker $True `
  -CaptureNetworkSetting $False `
  -CaptureLocallyUsingLinks $True `
  -CaptureUserSetting $True `
  -CaptureWindowsSetting $True
  #
  # Use the -Verbose option if there's any errors from the above settings
  # however if you do add it as a new line then don't forget that the line above it
  # must contain a ` at the end otherwise it won't work.
  #

