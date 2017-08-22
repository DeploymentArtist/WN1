# Check for elevation
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "You need to run this script from an elevated PowerShell prompt!`nPlease start the PowerShell prompt as an Administrator and re-run the script."
	Write-Warning "Aborting script..."
    Break
}

# specify the drive letter that you want the folders created on
$DataDrive = "E:"
# specify the ConfigMgr Admin
$CMAdmin = "VIAMONSTRA\Niall"
# Give the CMAdmin access to the following folders
$OSDBootImagePath = "$DataDrive\Program Files\Microsoft Configuration Manager\OSD"
icacls $OSDBootImagePath /grant $CMAdmin":(OI)(CI)(M)"
# create some folders
New-Item -Path "$DataDrive\Backups" -ItemType Directory
New-Item -Path "$DataDrive\Captures" -ItemType Directory
New-Item -Path "$DataDrive\Hidden" -ItemType Directory

# Check for Setup folder
Write-Host "Checking for Setup folder"
If (Test-Path 'E:\Setup'){
    Write-Host "E:\Setup folder found, OK, continuing."
    Write-Host ""
    } 
Else {
    Write-Host "Sources folder not found, creating it."
    New-Item -Path "$DataDrive\Setup" -ItemType Directory
    Write-Host ""
}

# Check for Sources folder
Write-Host "Checking for Sources folder"
If (Test-Path 'E:\Sources'){
    Write-Host "E:\Sources folder found, OK, continuing."
    Write-Host ""
    } 
Else {
    Write-Host "Sources folder not found, creating it."
    New-Item -Path "$DataDrive\Sources" -ItemType Directory
    Write-Host ""
}

New-Item -Path "$DataDrive\Sources\OSD" -ItemType Directory
New-Item -Path "$DataDrive\Sources\OSD\Boot" -ItemType Directory
New-Item -Path "$DataDrive\Sources\OSD\DriverPackages" -ItemType Directory
New-Item -Path "$DataDrive\Sources\OSD\Drivers" -ItemType Directory
New-Item -Path "$DataDrive\Sources\OSD\MDT" -ItemType Directory
New-Item -Path "$DataDrive\Sources\OSD\OS" -ItemType Directory
New-Item -Path "$DataDrive\Sources\OSD\OS\Operating System Images" -ItemType Directory
New-Item -Path "$DataDrive\Sources\OSD\OS\Operating System Installers" -ItemType Directory
New-Item -Path "$DataDrive\Sources\OSD\Settings" -ItemType Directory
New-Item -Path "$DataDrive\Sources\Software" -ItemType Directory
New-Item -Path "$DataDrive\Sources\Software\Microsoft" -ItemType Directory
New-Item -Path "$DataDrive\Sources\Software\7Zip" -ItemType Directory
New-Item -Path "$DataDrive\Sources\Software\Mozilla" -ItemType Directory
New-Item -Path "$DataDrive\USMTStores" -ItemType Directory

# create some shares
New-SmbShare –Name Captures$ –Path $DataDrive\Captures -ChangeAccess EVERYONE
icacls $DataDrive\Captures /grant '"VIAMONSTRA\CM_BA":(OI)(CI)(M)'
New-SmbShare –Name Sources –Path $DataDrive\Sources -FullAccess EVERYONE
New-SmbShare –Name USMTStores$ –Path $DataDrive\USMTStores -FullAccess EVERYONE
New-SmbShare –Name Backups$ –Path $DataDrive\Backups -FullAccess EVERYONE
