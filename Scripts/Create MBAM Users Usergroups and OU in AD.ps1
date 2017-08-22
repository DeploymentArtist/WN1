<#
# adds MBAM specific users and groups to AD 
# niall brady 2015/4/28
#>

try {
    Import-Module ActiveDirectory
    }
    catch {
    Write-host "The Active Directory module was not found"
    }

   # Create the MBAM OU
   $OUName="MBAM"
   $OUPath="OU=Service Accounts,OU=ViaMonstra,DC=corp,DC=viamonstra,DC=com"
    try {$IsOUInAD=Get-ADOrganizationalUnit -Identity "OU=$OUName,$OUPAth" 
         write-host "OU $OUNAme was already found in AD."
        }
    catch {
    write-host "$OUName OU does not exist in AD, adding..." -NoNewline
            New-ADOrganizationalUnit -Name $OUName -Path $OUPath
            write-host "Done !" -ForegroundColor Green}

# create an array of users to add to AD
     $strUsers = @("MBAM_DB_RO","MBAM_HD_AppPool", "MBAM_Reports_Compl")
foreach($User in $strUsers){
    try {$IsUsserInAD=Get-ADUser -LDAPFilter "(sAMAccountName=$User)"
        If ($IsUsserInAD -eq $Null) 
            {write-host "User $User does not exist in AD, adding..." -NoNewline
            New-ADUser -Name $User -GivenName $User -SamAccountName $User -UserPrincipalName $User@corp.viamonstra.com -AccountPassword (ConvertTo-SecureString "P@ssw0rd" -AsPlainText -Force) -Path 'OU=MBAM,OU=Service Accounts,OU=ViaMonstra,DC=corp,DC=viamonstra,DC=com' -PassThru | Enable-ADAccount
            # -ErrorAction Stop -Verbose
            write-host "Done !" -ForegroundColor Green}
        Else {
            write-host "User $User was already found in AD."
             }
        }
        catch{
            write-host "Error adding user: " $User -ForegroundColor Red
            }  
}  

# create an array of usergroups to add to AD

     $strUserGroups = @("MBAM_DB_RW","MBAM_HD", "MBAM_HD_Adv", "MBAM_HD_Report", "MBAM_Reports_RO")
foreach($UserGroup in $strUserGroups){
    try {$IsUserGroupInAD=Get-ADGroup -LDAPFilter "(sAMAccountName=$UserGroup)"
        If ($IsUserGroupInAD -eq $Null) 
            {write-host "UserGroup $UserGroup does not exist in AD, adding..." -NoNewline
            New-ADGroup -Name $UserGroup -DisplayName $UserGroup -SamAccountName $UserGroup -GroupCategory Security -GroupScope Global -Path 'OU=MBAM,OU=Service Accounts,OU=ViaMonstra,DC=corp,DC=viamonstra,DC=com'
             
            # -ErrorAction Stop -Verbose
            write-host "Done !" -ForegroundColor Green}
        Else {
            write-host "UserGroup $UserGroup was already found in AD."
             }
        }
        catch{
            write-host "Error adding UserGroup: " $UserGroup -ForegroundColor Red
            }  
}  

write-host "All done !"