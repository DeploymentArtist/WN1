# script to wait until bitlocker has finished encrypting the drive
# on hyper-v virtual machine with Configuration Manager 2012 R2
# niall brady, windows-noob.com (c) 2015/6/25
#
#Hide the progress dialog
$TSProgressUI = new-object -comobject Microsoft.SMS.TSProgressUI
$TSProgressUI.CloseProgressDialog()

# wait until bitlocker is fully encrypted
#
do 
{
    $Volume = Get-BitLockerVolume -MountPoint C:
    Write-Progress -Activity "Encrypting volume $($Volume.MountPoint)" -Status "Encryption Progress:" -PercentComplete $Volume.EncryptionPercentage
    Start-Sleep -Seconds 1
}
until ($Volume.VolumeStatus -eq 'FullyEncrypted')

Write-Progress -Activity "Encrypting volume $($Volume.MountPoint)" -Status "Encryption Progress:" -Completed