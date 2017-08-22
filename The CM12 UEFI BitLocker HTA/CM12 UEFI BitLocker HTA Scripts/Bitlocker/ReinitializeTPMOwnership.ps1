# Script to reinitialize TPM ownership in Windows
# run's as part of a task sequence after the Setup Windows and configMgr step
# Niall Brady 2015-1-30
#

$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$TPMHash = (ConvertTo-TpmOwnerAuth -PassPhrase "T3traP4k0SDT35M") 
write-output "TpmHash = " $TPMHash
Try
{
$TPMHashAuth=(Import-TpmOwnerAuth -OwnerAuthorization "$TPMHash")
#write-output "TPMHash auth result=" $TPMHashAuth | Where-Object {$_.TpmReady -eq $True}
If ($TPMHashAuth | Where-Object {$_.TpmReady -eq $True})
    {
    Write-Output "All good in the hood !"
    $tsenv.Value("TPMOwnerAuth") = "OK"
     
    }

Else
    {
     $tsenv.Value("TPMOwnerAuth") = "FAILED"
    }
}
Catch
{
    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    write-output "An error occurred: $ErrorMessage"
    $tsenv.Value("TPMOwnerAuth") = "AlreadyOwned"
    #Break
}

