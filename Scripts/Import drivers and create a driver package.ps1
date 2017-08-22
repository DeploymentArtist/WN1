# This script creates a driver package and then distributes it
# Niall Brady 2015/3/29, derived from a script from http://tinyurl.com/qzwwffc
#
# set variables for the driver import 
#
clear
CD C: # get-childitem will fail otherwise if you re-run
#
# set the distribution point name
$DistributionPointName = "CM01.CORP.VIAMONSTRA.COM"
#
#== Example: "Dell Optiplex 7010" or "Dell Latitude E6540"
$Make = "Microsoft"
$Model = "Surface Pro 3"

#== Example: "Win7" or "Win8"
$DriverOS = "Windows 8.1"

#== Options are "x86" or "x64"
$DriverArchitecture = "x64"

#== Driver root source dir
$DriverRootSource = "\\cm01\Sources\OSD\Drivers"
$DriverPkgRootSource = "\\cm01\Sources\OSD\DriverPackages"

#==============================================================
# Begin
#==============================================================

#Put together variables based on os, make, model and architecture
$DriverPackageName = $DriverOS + " " + $DriverArchitecture + " - " + $Make + " " + $Model
Write-Host "DriverPackageName = " $DriverPackageName
$DriverSource = $DriverRootSource + "\" + $DriverOS + " "+ $DriverArchitecture + "\" + $Make + "\" + $Model
Write-Host "DriverSource = " $DriverSource
$DriverPkgSource = $DriverPkgRootSource + "\" + $DriverOS + " " + $DriverArchitecture + "\" + $Make + "\" + $Model
Write-Host "DriverPkgSource = " $DriverPkgSource

$choice = ""
while ($choice -notmatch "[y|n]"){
    $choice = read-host "Do you want to continue? (Y/N)"
    }

if ($choice -eq "y"){
#unblock the files
gci $DriverSource -recurse | unblock-file

# Verify Driver Source exists.
If (Get-Item "$DriverSource" -ErrorAction SilentlyContinue)
{
# Get driver files
#Write-host "Importing the following drivers.." $Drivers

$Drivers = Get-childitem -path $DriverSource -Recurse -Filter "*.inf"
}
else
{
Write-Warning "Driver Source not found. Cannot continue"
Break
}

# Create Driver package source if not exists
If (Get-Item $DriverPkgSource -ErrorAction SilentlyContinue)
{
Write-Host "$DriverPkgSource already exists… "
}
else
{
Write-Host "Creating Driver package source directory $DriverPkgSource"
New-Item -ItemType directory $DriverPkgSource
}

# Connect to ConfigMgr
#
$CMDrive="E:"
$SiteCode="PS1:\"
Import-Module $CMDrive'\Program Files\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1'
#Set-Location $SiteCode
cd $SiteCode

#

If (Get-CMDriverPackage -Name $DriverPackageName -ErrorAction SilentlyContinue)
{
Write-Warning "$DriverPackageName Already exists. Exiting"
Break
}
else
{
Write-Host "Creating new Driver Package: " $DriverPackageName
# works up to CU3 
# New-CMDriverPackage -Name "$DriverPackageName" -Path "$DriverPkgSource" -PackageSourceType StorageDirect
# use below for CU4 onwards
#
New-CMDriverPackage -Name "$DriverPackageName" -Path "$DriverPkgSource"
$DriverPackage = Get-CMDriverPackage -Name $DriverPackageName
New-CMCategory -CategoryType DriverCategories -Name $DriverPackageName -ErrorAction SilentlyContinue
$DriverCategory = Get-CMCategory -Name $DriverPackageName

foreach($item in $Drivers)
{
$DriverPackage = Get-CMDriverPackage -Name $DriverPackageName
Write-Host "Importing the following driver: " $item.FullName
Import-CMDriver -UncFileLocation $item.FullName -ImportDuplicateDriverOption AppendCategory -EnableAndAllowInstall $True -DriverPackage $DriverPackage -AdministrativeCategory $DriverCategory -UpdateDistributionPointsforDriverPackage $False -verbose

}

}

# distribute it !

Start-CMContentDistribution –DriverPackageName $DriverPackageName –DistributionPointName $DistributionPointName
Start-Sleep -s 60
Update-CMDistributionPoint -DriverPackageName $DriverPackageName
Write-Host "Operations are complete !, exiting."

CD C:
    }
   
else {write-host "No drivers were imported, exiting!"}