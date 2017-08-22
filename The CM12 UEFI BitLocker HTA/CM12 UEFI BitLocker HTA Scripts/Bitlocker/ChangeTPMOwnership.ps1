# Script to change TPM ownership in Windows
# requires the TPM Onwer Password set with $OldPassPhrase first (for example in WinPE)
# run's as part of a task sequence after the Setup Windows and configMgr step
# to use outside of a Task Sequence, rem out the tsenv steps.
#
# Niall Brady 2015-2-5
# v.1

$OldPassPhrase="Password123"
$NewPassPhrase="Password1234567890"

$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$OldTPMHash = (ConvertTo-TpmOwnerAuth -PassPhrase $OldPassPhrase) 
$NewTPMHash = (ConvertTo-TpmOwnerAuth -PassPhrase $NewPassPhrase) 

write-output "OldTpmHash = " $OldTPMHash "NewTPMHash=" $NewTPMHash
Try
{
$ChangeTPMAuth = (Set-TpmOwnerAuth -OwnerAuthorization $OldTPMHash -NewOwnerAuthorization $NewTPMHash)
#write-output "ChangeTPM auth result=" $ChangeTPMAuth| Where-Object {$_.TpmReady -eq $True}
If ($ChangeTPMAuth | Where-Object {$_.TpmReady -eq $True})
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
}

