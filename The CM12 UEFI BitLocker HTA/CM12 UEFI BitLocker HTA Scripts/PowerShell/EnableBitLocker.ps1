# script to enable bitlocker on hyper-v virtual machine with Configuration Manager 2012 R2
# niall brady, windows-noob.com (c) 2015/6/25
#
# Hide the progress dialog
$TSProgressUI = new-object -comobject Microsoft.SMS.TSProgressUI
$TSProgressUI.CloseProgressDialog()

# 
# prompt for the BitLocker Password 

$command1 = @'
cmd.exe /c manage-bde -protectors -add -pw c:
'@

Invoke-Expression -Command:$command1

# pause for 5 seconds
Start-Sleep -m 5000

# Enable BitLocker

$command2 = @'
cmd.exe /c manage-bde -on c:
'@

Invoke-Expression -Command:$command2

# pause for 5 seconds
Start-Sleep -m 5000
