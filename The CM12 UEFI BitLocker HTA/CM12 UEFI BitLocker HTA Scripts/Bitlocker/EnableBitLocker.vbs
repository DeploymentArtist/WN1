'===============================================================================
'
' This sample script can be used to automate the deployment of BitLocker using the BitLocker WMI interfaces.
' 
' Last Updated: 7/1/2006
' Microsoft Corporation
'
' Disclaimer
' 
' The sample scripts are not supported under any Microsoft standard support program or service. The sample scripts are provided AS IS without warranty of any kind. 
' Microsoft further disclaims all implied warranties including, without limitation, any implied warranties of merchantability or of fitness for a particular purpose. 
' The entire risk arising out of the use or performance of the sample scripts and documentation remains with you. In no event shall Microsoft, its authors, or anyone else involved in the creation, production, or delivery of the scripts be liable for any damages whatsoever (including, without limitation, damages for loss of business profits, business interruption, loss of business information, or other pecuniary loss) arising out of the use of or inability to use the sample scripts or documentation, even if Microsoft has been advised of the possibility of such damages.
'
'Version 1.2 - Updates
'1 - Removed infinate loop potential in the FindRemoveableDrive function. Three attempts are valid.
'2 - Added saving RK to the /USB option.
'3 - Will not look at local evet log if no policy key present.
'4 - Minor loging and text changes.
'5 - Fixed PIN input cancel button use.
'
' 
'===============================================================================================================
'Script arguments
'/on:<tpm,tp,tsk,usb>			    used to specify options for turning on BitLocker (tpm,tp,tsk) REQUIRED
'/l:<location>	 				    specify to create a log file and it's location REQUIRED
'/em:<128d,256d,128,256> 		    used to specify encryption algorithm (aes128d, aes256d, aes128, aes256) OPTIONAL
'/rk				 			    create a recovery key and store in a particular location  OPTIONAL
'/promptuser					    causes script to prompt user for TPM PIN or to insert USB drive OPTIONAL
'/sms							    creates an SMS status MIF for software distribution OPTIONAL
'/ro:"<existingTPMownerpassword>"	changes the TPM ownership password (password must be placed between "") OPTIONAL
'----------------------------------------------------------------------------------------
'Constants And Variables
'----------------------------------------------------------------------------------------
On Error Resume Next

Const ForAppending = 8
Const SetPres = 10
const HKEY_LOCAL_MACHINE = &H80000002
const REG_SZ = 1
const REG_EXPAND_SZ = 2
const REG_BINARY = 3
const REG_DWORD = 4
const REG_MULTI_SZ = 7

Dim bIsEnabled,bIsActivated,bIsOwned,bIsOwnershipAllowed,objTPM,objLog,TakeOwnership,Enable,objEnVol,strStatusTPM,strStatusBDE,strStatusTPMState
Dim objGPPT,strOwnerPassword,strPassword,objWMIBDE,nProtStatus,ProtectVar,objOSSysDriv,objSWbemServices,objOS,coloperatingsystem,sProtID,strOldOwnerPassword
Dim argProtect,argRK,argEM,argSMS,argLOG,argRO,argPrompt,strCurrentUser,argValid,i,strPIN,objRemovableDrive,strStatusCode,strStatusData,MIF,strEKP,strEK
Dim ActiveDirectoryBackup,ActiveDirectoryInfoToStore,RequireActiveDirectoryBackup,EncryptionMethod,BackupMandatory,strStartDate,strStartTime,strRetry,strPolicy

'----------------------------------------------------------------------------------------
'General 1 - Get ready to run, create objects, create log file, parse command line arguments
'----------------------------------------------------------------------------------------
Set objFSO = CreateObject("Scripting.FileSystemObject")
Set WSHShell = WScript.CreateObject("WScript.Shell")

'Parse command line arguments
Set args = WScript.Arguments
Argument1 = args.Item(0)
Argument2 = args.Item(1)
NumberofArgs = WScript.Arguments.Count
Set colNamedArgs = WScript.Arguments.Named

'Get all command line arguments and set them to lower Case
argProtect = LCase(colNamedArgs.Item("on"))
argRK = LCase(colNamedArgs.Item("rk"))
argEM = LCase(colNamedArgs.Item("em"))
argLOG = LCase(colNamedArgs.Item("l"))
argPrompt = LCase(colNamedArgs.Item("promptuser"))
argSMS = LCase(colNamedArgs.Item("sms"))
strOldOwnerPassword = LCase(colNamedArgs.Item("ro"))

'Evaluate named optional arguments
If colNamedArgs.Exists("rk") Then
	argRK = "1"
	Else
	argRK = "No recovery key use specified"
End If
If colNamedArgs.Exists("sms") Then
	argSMS = "1"
	Else
	argSMS = "No SMS status MIF's will be created"
End If 
If colNamedArgs.Exists("ro") Then
	argRO = "1"
	Else
	argRO = "TPM ownership information will not be cleared"
End If
If colNamedArgs.Exists("promptuser") Then
	argPrompt = "1"
	Else
	argPrompt = "Users will not be prompted for PIN or to insert USB key"
End If

'Evaluate emcyption method if on command line
If Not colNamedArgs.Exists("em") Then
	argEM = "1"
Else If argEM = "" Then
	argEM = "1"
Else If argEM = "128d" Then
	argEM = "1"
Else If argEM = "256d" Then
	argEM = "2"
Else If argEM = "128" Then
	argEM = "3"
Else If argEM = "256" Then
	argEM = "4"
	 End If
    End If
   End If
  End If
 End If
End If

'Create log file 
Set objLog = objFSO.OpenTextFile(argLOG,ForAppending,True)
objlog.writeline "Script processing started  " & Date & "       " & Time
strStartDate = Date
strStartTime = Time

'Set the SMS default status exit code
strStatusCode = 1

'Check arguments for requiered options
If Not colNamedArgs.Exists("on") Then
	strStatusData = "No /on option was specified on the command line."
	objLog.Writeline strStatusData
	Wscript.Echo  strStatusData
    strStatusCode = 0
    CreateStatusMIF strStatusData
	ShowHelp

Else If Not colNamedArgs.Exists("l") Then
	strStatusData = "No /l option specified on the command line."
	objLog.Writeline strStatusData
	Wscript.Echo strStatusData
	strStatusCode = 1
	CreateStatusMIF strStatusData
	ShowHelp
Else If NumberofArgs < 2 Then
	strStatusData = "The required number of arguments of 2 was not met."
	objLog.Writeline strStatusData
	Wscript.Echo strStatusData
	strStatusCode = 1
	CreateStatusMIF strStatusData
	ShowHelp
Else If ((argProtect = "tp") Or (argProtect = "tsk")) And argPrompt <> "1" Then
	strStatusData = "Using the options /on:tp or /on:tsk and not using /promptuser is not allowed."
	objLog.Writeline strStatusData
	Wscript.Echo strStatusData
	strStatusCode = 1
	CreateStatusMIF strStatusData
	ShowHelp
Else If argProtect = "usb" And argPrompt <> "1" Then
	strStatusData = "Using the options /on:usb and not using /promptuser is not allowed."
	objLog.Writeline strStatusData
	Wscript.Echo strStatusData
	strStatusCode = 1
	CreateStatusMIF strStatusData
	ShowHelp
Else If argRK = "1" And argPrompt <> "1" Then
	objLog.Writeline "Using the option /rk and not using /promptuser is not allowed."
	Wscript.Echo "Using the option /rk and not using /promptuser is not allowed."
	ShowHelp
Else
    If argProtect = "tp" Or argProtect = "tpm" Or argProtect = "tsk" Or argProtect = "usb" Then
        objLog.Writeline "Proper number of command line arguments passed to the script"
    Else
	    objLog.Writeline "The /on option does not match one of the required options."
	    Wscript.Echo "The /on option does not match one of the required options."
	    ShowHelp
	  End If
     End If
    End If
   End If
  End If
 End If
End If

'Output command arguments to log file
objLog.Writeline "-----------------------------------------------------------------------"
objLog.Writeline "---------------Executing with the following arguments------------------"
objLog.Writeline "-----------------------------------------------------------------------"
objLog.Writeline "Enable parameters: " & argProtect
objLog.Writeline "Logging location: " & argLOG
objLog.Writeline "Create recovery key: " & argRK
objLog.Writeline "Encryption method: " & argEM
objLog.Writeline "Create SMS status MIF's: " & argSMS
objLog.Writeline "Reset TPM ownership: " & argRO
objLog.Writeline "User prompting: " & argPrompt
objLog.Writeline "-----------------------------------------------------------------------"

'----------------------------------------------------------------------------------------
'General 2 - Main script processing area
'----------------------------------------------------------------------------------------

ConnectTPMProv() 'Connect to the TPM WMI provider

If argProtect = "usb" Then
	ConnectBDEProv() 'Connect to the volume encryption WMI provider
	EvalGPO()
	GetBDEStatus()
Else
    GetTPMStatus() 'Get the current status of the TPM to determine action
    ConnectBDEProv() 'Connect to the volume encryption WMI provider

    'The following If statements cause the script to react differently depending on the TPM state

    If bIsEnabled = "True" and bIsActivated = "True" and bIsOwned = "True" Then
    objlog.writeline "TPM is in a ready state to enable BitLocker."
	    If argRO = "1" Then
		    objlog.writeline "Change TPM owner password specified on the command line."
		    DenTPMPassword
		    ChangeOwnerAuth strOldOwnerPassword,strOwnerPassword
		    EvalGPO()
		    GetBDEStatus()
	    Else
		    EvalGPO()
		    GetBDEStatus()
	    End If
    Else If bIsEnabled = "True" and bIsActivated = "True" and bIsOwned = "False" Then
	    objlog.writeline "TPM ownership is not taken...will take ownership."
	    DenTPMPassword
	    OwnTPM
	    EvalGPO()
	    GetBDEStatus()
    Else If bIsEnabled = "False" And bIsActivated = "False" and bIsOwned = "False" Then
	    objlog.writeline "TPM is not turned on...will Enable and Activate TPM and force a reboot."
	    EnableActivateTPM()
    Else If bIsEnabled = "False" and bIsActivated = "False" and bIsOwned = "True" Then
	    objlog.writeline "TPM is not turned on...will Enable and Activate TPM and force a reboot."
        EnableActivateTPM()
    Else If bIsEnabled = "True" and bIsActivated = "False" and bIsOwned = "False" Then
   	    objlog.writeline "TPM is turned but not activated...will Activate TPM and force a reboot."
        EnableActivateTPM()
        End If
       End If
      End If
     End If
    End If
End If

If strStatusCode = 1 then
    strStatusData = strStatusTPMState & ". " & strStatusTPM & " " & "The volume has a protection status of: " & nProtStatus & ". " & strStatusBDE & ". " & "Script Completed Successfully"
    objLog.writeline strstatusdata
    CreateStatusMIF strStatusData
End if
objlog.writeline "Script ended  " & Date & "       " & Time

'----------------------------------------------------------------------------------------
'Functions and subs
'----------------------------------------------------------------------------------------
'Function 1 - Connect to TPM WMI provider
'----------------------------------------------------------------------------------------

Function ConnectTPMProv()
strConnectionStr1 = "winmgmts:{impersonationLevel=impersonate,authenticationLevel=pktPrivacy}!root\cimv2\Security\MicrosoftTpm"

err.clear
Set objWMITPM = GetObject(strConnectionStr1)
If Err.Number <> 0 Then 
    strStatusData = "ERROR - Failed to connect to the MicrosoftTPM provider. Script is exiting..."
    objLog.Writeline strStatusData
	strStatusCode = 0
	CreateStatusMIF strStatusData
    Wscript.Quit -1
    Else
    objLog.Writeline "Connection succeeded to MicrosoftTPM"
End If
err.clear

' There should either be 0 or 1 instance of the TPM provider class
Set colTpm = objWMITPM.InstancesOf("Win32_Tpm")

If colTpm.Count = 1 And argProtect = "usb" Then
	strStatusData = "Successfully retieved a TPM from the provider class. USB only protection was chosen and cannot be used when a TPM is present. Script is exiting...(Error: " & Err.Number & ")"
	objLog.Writeline strStatusData
	strStatusCode = 0
	CreateStatusMIF strStatusData
	WScript.Quit -1
Else If colTpm.Count = 0 And argProtect = "usb" Then
    	objLog.Writeline "Protect option is set for USB only. Will continue with USB only protection..."
	Exit Function
Else If colTpm.Count = 0 And argProtect <> "usb" Then
	strStatusData = "ERROR - Failed get a TPM instance in the provider class. Script is exiting..."
	objLog.Writeline strStatusData
	strStatusCode = 0
	CreateStatusMIF strStatusData
	WScript.Quit -1
  End If 
 End If
End If
Err.Clear

'Get a single instance of the TPM provider class 
Set objTpm = objWMITPM.Get("Win32_Tpm=@")
If Err.Number <> 0 Then
	strStatusData = "ERROR - Failed get a TPM instance in the provider class. Script is exiting...(Error: " & Err.Number & ")"
	objLog.Writeline strStatusData
	strStatusCode = 0
	CreateStatusMIF strStatusData
	WScript.Quit -1
	Else
	objLog.Writeline "Successfully retrieved a TPM instance from the Win32_TPM provider class"
End If
Err.Clear

End Function

'----------------------------------------------------------------------------------------
'Function 2 - Connect to BDE WMI provider
'----------------------------------------------------------------------------------------

Function ConnectBDEProv()

strConnectionStr2 = "winmgmts:{impersonationLevel=impersonate,authenticationLevel=pktPrivacy}!root\cimv2\Security\MicrosoftVolumeEncryption"

err.clear
Set objWMIBDE = GetObject(strConnectionStr2)
If Err.Number <> 0 Then 
    strStatusData = "ERROR - Failed to connect to the MicrosoftVolumeEncryption provider. Script is exiting...(Error " & Err.Number & ")"
	objLog.Writeline strStatusData
	strStatusCode = 0
	CreateStatusMIF strStatusData
	WScript.Quit -1
Else 
    objLog.Writeline "Connection succeeded to MicrosoftVolumeEncryption"
End If
err.clear

End Function

'-----------------------------------------------------------------------------------------
'Function 3 - Get BDE status data and enable encryption
'-----------------------------------------------------------------------------------------

Function GetBDEStatus()

Set colEnVol = objWMIBDE.ExecQuery("Select * from Win32_EncryptableVolume")
objlog.writeline "EncryptableVolumes count is: " & colEnVol.count

If colEnVol.count < 1 then
strStatusData = "ERROR - EncryptableVolumes is null and count is: " & colEnVol.count & " Script is quitting..."
objLog.Writeline strStatusData
strStatusCode = 0
CreateStatusMIF strStatusData
WScript.Quit -1
Else
strConnectionStr3 = "winmgmts:{impersonationLevel=impersonate,authenticationLevel=pktPrivacy}!root\cimv2"
Set objSWbemServices = GetObject(strConnectionStr3)
Set coloperatingsystem = objSWbemServices.ExecQuery("Select * from Win32_OperatingSystem") 
For each objOperatingSystem in colOperatingSystem
	strWin32SysDrive = objOperatingSystem.SystemDrive
Next

For Each objEnVol in colEnVol
objlog.writeline "The EncryptableVolume(s) found: " & objEnVol.DeviceID
strEncDriveLetter = objEnVol.DriveLetter

If strEncDriveLetter = strWin32SysDrive then
    objlog.writeline "EncryptableVolume used for encryption is: " & strEncDriveLetter
    intRC = objEnVol.GetProtectionStatus(nProtStatus)
    objlog.writeline "The volume has a protection status of: " & nProtStatus         

    If nProtStatus = 1 then
        strStatusData = "BitLocker Protection is already enabled. Check log file for more details. Process is quitting..."
    objLog.Writeline strStatusData
        strStatusCode = 0
        CreateStatusMIF strStatusData
    Wscript.quit -1
    Else
        If nProtStatus = 0 then
            objlog.writeline "BitLocker Protection is Off"
            nRC = objEnVol.GetConversionStatus(strCS)
            objlog.writeline "Get conversion status is: " & strCS
            If strCS = 0 Then
                err.Clear
                objlog.writeline "The volume has a status of fully decrypted"

                    If argProtect = "tpm" Then
                        intRC = objEnVol.ProtectKeyWithTPM("TPM Protection",Empty,sProtID)
                        objLog.Writeline "Attempting to enable BitLocker TPM"
                            If intRC <> 0 Then
                                    CheckError intRC
                                    strStatusData = "ERROR - the ProtectKeyWithTPM Method failed with the exit code:  " & Hex(intRC)
                                    objLog.Writeline strStatusData
                                    strStatusCode = 0
                                    CreateStatusMIF strStatusData
                                Else
                                    strStatusData = "Successfully initiated ProtectKeyWithTPM Method with an exit code of:  " & Hex(intRC)
                                    objlog.writeline strStatusData
                                    strStatusBDE = strStatusData
                                    CheckUser
					                CreateRP objEnVol
                        			EnableBitlocker objEnVol
                        			CreateRK sProtID
                            End If
                            err.clear
                            
                    Else
                        If argProtect = "tp" Then
                            CheckUser
                            GetPIN
                            If argPrompt = "1" and strCurrentUser = "1" and argValid = "1" Then  
                                intRC = objEnVol.ProtectKeyWithTPMAndPIN("TPM and PIN Protection",Empty,strPIN,sProtID)
								objLog.Writeline "Attempting to enable BitLocker TPM + Pin"
                                    If intRC <> 0 Then 
                                        CheckError intRC
                                        strStatusData = "ERROR - the ProtectKeyWithTPMAndPIN Method failed with the exit code:  " & Hex(intRC)
                                        objLog.Writeline strStatusData
                                    strStatusCode = 0
                                    CreateStatusMIF strStatusData
                                    Else	                                            
                                    strStatusData = "Successfully initiated ProtectKeyWithTPMAndPIN Method with an exit code of:  " & Hex(intRC)
                                    objlog.writeline strStatusData
                                    strStatusBDE = strStatusData
                                    CreateRP objEnVol
                                	EnableBitlocker objEnVol
                                	CreateRK sProtID
                                    End If
                                    err.clear
                            Else
                                strStatusData = "ERROR - TPM and PIN Protection failed.  One of the following conditions was not met: Command line switch /promptuser not used, No logged on User, or PIN was not of a valid format"
                                objlog.writeline strStatusData
                                strStatusBDE = strStatusData
                                Exit Function
                            End If
                        Else
                            If argProtect = "tsk" Then
                                CheckUser
                            	If argPrompt = "1" Then
                                		FindRemovableDrive()
                                	Else
                                		objLog.WriteLine "TPM and StarupKey option is chosen and user prompting for USB device is disabled.  Script is exiting..."
                                		FindRemovableDrive()
                                		Exit Function
                                	End If                                  
                                        intRC = objEnVol.ProtectKeyWithTPMAndStartupKey("TPM and Startup Key Protection",Empty,Empty,sProtID)
			                            objLog.Writeline "Attempting to enable BitLocker TPM + StartupKey"
                                        If intRC <> 0 Then
                                            CheckError intRC 
                                            strStatusData = "ERROR - the ProtectKeyWithTPMAndStartupKey Method failed with the exit code:  " & Hex(intRC)
                                            objLog.Writeline strStatusData
                                            strStatusCode = 0
                                            CreateStatusMIF strStatusData
                                        Else
                                            objlog.writeline "Successfully initiated ProtectKeyWithTPMAndStartupKey Method with an exit code of:  " & Hex(intRC)
					                        objLog.Writeline "Attempting to save startup key..."
                                    		intRC = objEnVol.SaveExternalKeyToFile(sProtID,objRemovableDrive)
                                		    If intRC <> 0 Then 
                                                strStatusData = "ERROR - Failed to save the startup key to a USB drive with the following exit code:  " & Hex(intRC)
                                                objLog.Writeline strStatusData
                                                strStatusCode = 0
                                                CreateStatusMIF strStatusData
                                        	Else
                                            	strStatusData = "Successfully completed ProtectKeyWithTPMAndStartupKey Method and saved the startup key to USB drive with an exit code of:  " & Hex(intRC)
                                            	objlog.writeline strStatusData
                                                strStatusBDE = strStatusData
                                    			CreateRP objEnVol
                                    			EnableBitlocker objEnVol
                                    			CreateRK sProtID
					                        End If
                                    		err.clear
			                            End If
                                        err.clear
                            Else
                                If argProtect = "usb" then
                                    CheckUser
                                    FindRemovableDrive()
                                    intRC = objEnVol.ProtectKeyWithExternalKey("USB Key Protection",Empty,sProtID)
                                    objLog.Writeline "Attempting to enable BitLocker with External Key only"
                                        If intRC <> 0 Then 
                                            CheckError intRC
                                            strStatusData = "ERROR - the ProtectKeyWithExternalKey Method failed with the exit code:  " & Hex(intRC)
                                            objLog.Writeline strStatusData
                                            strStatusCode = 0
                                            CreateStatusMIF strStatusData
                                        Else
                                            objlog.writeline "Successfully initiated ProtectKeyWithExternalKey Method with an exit code of:  " & Hex(intRC)
				    						objLog.Writeline "Attempting to save USB key..."
                                		    intRC = objEnVol.SaveExternalKeyToFile(sProtID,objRemovableDrive)
                            		        If intRC <> 0 Then 
                                        		strStatusData = "ERROR - Failed to save the startup key to a USB drive with the following exit code:  " & Hex(intRC)
                                        		objLog.Writeline strStatusData
                                                strStatusCode = 0
                                                CreateStatusMIF strStatusData
                            		        Else
                                        	    strStatusData = "Successfully completed ProtectKeyWithExternalKey Method and saved the startup key to USB drive with an exit code of:  " & Hex(intRC)
                                        	    objlog.writeline strStatusData
                                                strStatusBDE = strStatusData
                                			    CreateRP objEnVol
					                            EnableBitlocker objEnVol
					                            CreateRK sProtID
				                            End If
                                		    err.clear
                                        End If
                                    End If
                                End If
                            End If
                        End If
              End if	 
        End if
    End if
End if                

Next
	If strCS = "" Then
		strStatusData = "ERROR - The available encyptable volumes must match the operating system volume and this did not occur.  Operating system drive found - " & strWin32SysDrive
        	objLog.Writeline strStatusData
        	strStatusCode = 0
        	CreateStatusMIF strStatusData
	Else
		GetConversionStatus strCS
	End If
End If
End Function

'-----------------------------------------------------------------------------------------
'Function 4 - Get TPM status data to determine if TPM is enabled, activated, and owned
'-----------------------------------------------------------------------------------------

Function GetTPMStatus()

nRC = objTpm.IsEnabled(bIsEnabled)
If nRC <> 0 Then
    strStatusData = "ERROR - The method IsEnabled failed with return code 0x" & Hex(nRC)
    objLog.Writeline strStatusData
	strStatusCode = 0
	CreateStatusMIF strStatusData
End If

nRC = objTpm.IsActivated(bIsActivated)
If nRC <> 0 Then
    strStatusData = "ERROR - The method IsActivated failed with return code 0x" & Hex(nRC)
    objLog.Writeline strStatusData
	strStatusCode = 0
	CreateStatusMIF strStatusData
End If

nRC = objTpm.IsOwned(bIsOwned)
If nRC <> 0 Then
    strStatusData = "ERROR - The method IsOwned failed with return code 0x" & Hex(nRC)
    objLog.Writeline strStatusData
	strStatusCode = 0
	CreateStatusMIF strStatusData
End If

'Output TPM status information to the log file
objLog.WriteLine "TPM found in the following state:"
objLog.WriteLine "Enabled - " & bIsEnabled
objLog.WriteLine "Activated - " & bIsActivated
objLog.WriteLine "Owned - " & bIsOwned

strStatusTPMState = "TPM found in the following state: Enabled - " & bIsEnabled & ", Activated - " & bIsActivated & ", Owned - " & bIsOwned

End Function

'-----------------------------------------------------------------------------------------
'Function 5 - Enable and Activate TPM 
'-----------------------------------------------------------------------------------------

Function EnableActivateTPM

Err.clear

'Enable and activate TPM device

intRC = objTPM.SetPhysicalPresenceRequest(SetPres)
objLog.Writeline "Attempting to enable and activate the TPM"
If intRC <> 0 Then 
        strStatusData = "ERROR - failed to enable and activate the TPM with the following exit code:  " & Hex(intRC)
        objLog.Writeline strStatusData
	    strStatusCode = 0
	    CreateStatusMIF strStatusData
    Else
	    objlog.writeline "Completed enabling and activating the TPM with an exit code of:  " & Hex(intRC)
End If

intRC = objTPM.GetPhysicalPresenceTransition(strPT)
objlog.writeline "Presence Transition = " & strPT
If intRC <> 0 Then 
        strStatusData = "ERROR - failed to get PhysicalPresenceTransition with the following exit code:  " & Hex(intRC)
        objLog.Writeline strStatusData
	    strStatusCode = 0
	    CreateStatusMIF strStatusData
    Else
	    objlog.writeline "Completed PhysicalPresenceTransition with an exit code of:  " & Hex(intRC)
End If
 
If strPT = 0 then
    objlog.writeline "The platform does not need to transition"
Else
    If strPT = 1 then
	   strStatusData = "Shutting down system to finish enabling the TPM"
	   objlog.writeline strStatusData
	   strStatusTPM = strStatusData
       oReboot = WSHShell.Run("shutdown.exe /s /t 5",2,True)
       '***** Add status code???
	Else
	    If strPT = 2 then
	        objlog.writeline "Rebooting system to finish enabling the TPM"
            oReboot = WSHShell.Run("shutdown.exe /r /t 5",2,True)
            '***** Add status code???
        Else
            If strPT = 3 Then
	            strStatusData = "The TPM transition is vendor-specific cannot continue. Contact your vendor for instructions. Script is quitting..."
                objLog.Writeline strStatusData
	            strStatusCode = 0
	            CreateStatusMIF strStatusData
	            WScript.Quit -1
	        End if
	    End if
    End if
End if 	  

End Function

'-----------------------------------------------------------------------------------------
'Function 6 - Create a recovery key if specified on command line
'-----------------------------------------------------------------------------------------
Function CreateRK(sProtID)
If argRK = "1" Then
	FindRemovableDrive()
	intRC = objEnVol.ProtectKeyWithExternalKey("Recovery Protection",Empty,sProtID)
	objLog.Writeline "Attempting to create BitLocker Recovery Key."
    If intRC <> 0 Then 
    	objlog.writeline "ERROR - Failed generating Recovery Key with the exit code:  " & Hex(intRC)
    Else
		objlog.writeline "Successfully generated Recovery key with an exit code of:  " & Hex(intRC)
		objLog.Writeline "Attempting to save Recovery Key to USB..."
		intRC = objEnVol.SaveExternalKeyToFile(sProtID,objRemovableDrive)
  		If intRC <> 0 Then 
        	objlog.writeline "ERROR - Failed to save the recovery key to a USB drive with the following exit code:  " & Hex(intRC)
  		Else
     		objlog.writeline "Successfully saved the recovery key to USB drive with an exit code of:  " & Hex(intRC)
		End If
		err.clear
End If
End If

End Function

'-----------------------------------------------------------------------------------------
'Function 7 - Changing TPM owner information
'-----------------------------------------------------------------------------------------
Function ChangeOwnerAuth(strOldOwnerPassword,strOwnerPassword)
err.clear

' Convert the owner password to owner authorization by using SHA-1 hashing
intRC = objTpm.ConvertToOwnerAuth(strOldOwnerPassword, OldOwnerAuthDigest)
If intRC <> 0 Then 
        objlog.writeline "ERROR - Failed to converting old owner password to owner authorization:  " & Hex(intRC)
    Else
	    objlog.writeline "Completed converting old owner password to owner authorization:  " & Hex(intRC)
End If
err.clear

intRC = objTpm.ConvertToOwnerAuth(strOwnerPassword, OwnerAuthDigest)
If intRC <> 0 Then 
        objlog.writeline "ERROR - Failed to converting owner password to owner authorization:  " & Hex(intRC)
    Else
	    objlog.writeline "Completed converting owner password to owner authorization:  " & Hex(intRC)
End If
err.clear

' Change owner authorization on the TPM
intRC = objTpm.ChangeOwnerAuth(OldOwnerAuthDigest,OwnerAuthDigest)
objlog.writeline "Starting to change owner authorization process on the TPM"
If intRC <> 0 Then 
        objlog.writeline "ERROR - Failed to change owner authorization on the TPM with the following exit code:  " & Hex(intRC)
    Else
	    objlog.writeline "Completed change owner authorization process on the TPM with the following exit code:  " & Hex(intRC)
End If
err.clear

'Wait for TPM to finish ownership process
Wscript.Sleep(10000)

End Function

'-----------------------------------------------------------------------------------------
'Function 8 - Generate random string for TPM owner password.  This password will range
'from 7-14 characters and will contain numbers and letters.
'-----------------------------------------------------------------------------------------
Function DenTPMPassword

'Upper and lower limits for TPM owner password 
intUpperLimit = 14
intLowerLimit = 7

Randomize
intCharacters = Int(((intUpperLimit - intLowerLimit + 1) * Rnd) + intUpperLimit)   

intUpperLimit = 126
intLowerLimit = 33

For i = 1 to intCharacters
    Randomize
    intASCIIValue = Int(((intUpperLimit - intLowerLimit + 1) * Rnd) + intLowerLimit)   
    strPassword = strPassword & Chr(intASCIIValue)
Next

strOwnerPassword = strPassword
objLog.WriteLine "Random TPM owner password is: " & strOwnerPassword

End Function

'-----------------------------------------------------------------------------------------
' Function 9 - Check for endoresement key and take ownership of TPM
'-----------------------------------------------------------------------------------------

Function OwnTPM

err.clear

'Check for the presence of Endorsement Key Pair and create one if not found
intRC = objTpm.IsEndorsementKeyPairPresent(strEK)
If intRC <> 0 Then 
    strStatusData = "ERROR - Failed to determine if Endorsement Key Pair is present with the following exit code:  " & Hex(intRC)
    objLog.Writeline strStatusData
	strStatusCode = 0
	CreateStatusMIF strStatusData
Else
	objlog.writeline "Successfully determined if Endorsement Key Pair is present with an exit code of:  " & Hex(intRC)
	objlog.writeline "IsEndorsementKeyPairPresent returned a value of: " & strEK
End If
err.clear

If strEK = "True" then
    objlog.writeline "Endorsement Key Pair is present."
Else
    objlog.writeline "Attempting to create Endorsement Key Pair"
    intRC = objTpm.CreateEndorsementKeyPair(strEKP)
    If intRC <> 0 Then 
        strStatusData = "ERROR - Failed to create Endorsement Key Pair with the following exit code:  " & Hex(intRC)
        objLog.Writeline strStatusData
	    strStatusCode = 0
	    CreateStatusMIF strStatusData
	    Wscript.quit -1
    Else
	    objlog.writeline "Successfully created Endorsement Key Pair with an exit code of:  " & Hex(intRC)
    End If
End if

err.clear

' Convert the owner password to owner authorization by using SHA-1 hashing
intRC = objTpm.ConvertToOwnerAuth(strOwnerPassword, OwnerAuthDigest)
If intRC <> 0 Then 
        strStatusData = "ERROR - Failed to hash TPM owner password with the following exit code:  " & Hex(intRC)
        objLog.Writeline strStatusData
	    strStatusCode = 0
	    CreateStatusMIF strStatusData
	    Wscript.quit -1
    Else
	    objlog.writeline "Successfully hashed TPM owner password with an exit code of:  " & Hex(intRC)
    End If

' Take ownership of the TPM - two string values to be hashed using SHA-1
intRC = objTpm.TakeOwnership(OwnerAuthDigest)
objlog.writeline "Starting to take ownership of the TPM"
If intRC <> 0 Then 
        strStatusData = "ERROR - Failed to take ownership of the TPM with the following exit code:  " & Hex(intRC)
        objLog.Writeline strStatusData
	    strStatusCode = 0
	    CreateStatusMIF strStatusData
    Else
	    objlog.writeline "Completed taking ownership of the TPM with an exit code of:  " & Hex(intRC)
End If
err.clear

'Wait for TPM to finish ownership process
Wscript.Sleep(10000)

End Function

'-----------------------------------------------------------------------------------------
'Function 10 - Enable Bitlocker
'-----------------------------------------------------------------------------------------

Function EnableBitlocker(objEnVol)

Err.clear
intRC = objEnVol.Encrypt(argEM)
objLog.Writeline "Attempting to enable BitLocker..."
If intRC <> 0 Then 
        strStatusData = "ERROR - failed to initiate drive encryption with the following exit code:  " & Hex(intRC)
        objLog.Writeline strStatusData
        strStatusCode = 0
        CreateStatusMIF strStatusData

        objLog.Writeline "Deleting previously created key protectors..."
	intRC = objEnVol.DeleteKeyProtectors()
        If intRC <> 0 Then 
            strStatusData = "ERROR - failed to remove key protectors with the following exit code:  " & Hex(intRC) & "  Script is quitting..."
            objLog.Writeline strStatusData
	Else
	        objlog.writeline "Successfully removed key protectors with the following exit code:  " & Hex(intRC) & "  Script is quitting..."
	End If

    Else
        objlog.writeline "Successfully initiated BitLocker drive encryption with an exit code of:  " & Hex(intRC)
End If
err.clear

End Function

'--------------------------------------------------------------
'Function 11 - Find the removeable drive in WMI
'--------------------------------------------------------------
Function FindRemovableDrive()

strRetry = strRetry + 1
If strRetry > 3 Then
    strStatusData = "ERROR - User did not input a valid USB device within the 3 attempts allowed. Script is quitting..."
	    objLog.Writeline strStatusData
	    strStatusCode = 0
	    CreateStatusMIF strStatusData
	    Wscript.Quit -1
End If

Err.Clear
Set colDrives = objSWbemServices.ExecQuery("Select * from Win32_Volume where DriveType = '2'")
If Err.Number = 0 Then 
        objLog.Writeline "Successfully completed the search for a USB drive with the following exit code:  " & Err.Number
    Else
	    strStatusData = "ERROR - the search for a USB drive failed with the following exit code:  " & Err.Number
	    objLog.Writeline strStatusData
	    strStatusCode = 0
	    CreateStatusMIF strStatusData
End If
err.clear

If argPrompt = "1" and strCurrentUser = "1" Then

	If colDrives.count = 1 Then
		For Each objDrive in colDrives
	        objRemovableDrive = objDrive.DriveLetter
		objLog.WriteLine "Found USB drive in the system at the following drive letter: " & objDrive.DriveLetter
		Next
	Else If colDrives.count > 1 Then
	    strStatusData = "ERROR - More then one USB device was found in your system cannot determine where to save key. Script is quitting..."
	    objLog.Writeline strStatusData
	    strStatusCode = 0
	    CreateStatusMIF strStatusData
	    Wscript.Quit -1
	Else If colDrives.count = 0 Then
		objLog.WriteLine "Warning - Did not find USB device to save your startup key.  Waiting for user will retry....."
	    Wscript.Echo "No removeable USB device was found in your system.  To complete the BitLocker configuration please insert a USB removeable drive to save your Startup or Recovery Key." 
	    WScript.Sleep(10000)
	    FindRemovableDrive()
	  End If 
	 End If
	End If
Else
	If colDrives.count = 1 Then
		For Each objDrive in colDrives
	        objRemovableDrive = objDrive.DriveLetter
		Next
	Else
		strStatusData = "ERROR - No USB device available to save key.  Script is quitting..."
		objLog.Writeline strStatusData
	    strStatusCode = 0
	    CreateStatusMIF strStatusData
		WScript.Quit -1
	End If
End If

End Function

'----------------------------------------------------------------------------------------
'Function 12 - Function used to interogate Group Policy and determine successfully backup of recovery data
'----------------------------------------------------------------------------------------
Function EvalGPO

strComputer = "."
strPolicy = "0"

err.Clear
Set objReg=GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strComputer & "\root\default:StdRegProv")
If Not Err.number=0 Then 
	strStatusData = "ERROR - Could not connect to WMI StdRegProv" & Err.Description
	objLog.Writeline strStatusData
	strStatusCode = 0
	CreateStatusMIF strStatusData
	Else
	objLog.Writeline "Successfully connected to WMI StdRegProv"
End If

err.Clear
objLog.WriteLine "Checking if Group Policy encryption method is set..."
strKeyPath = "SOFTWARE\Policies\Microsoft\FVE"
objReg.EnumValues HKEY_LOCAL_MACHINE, strKeyPath, arrValueNames, arrValueTypes
If IsEmpty(arrValueNames) = True or IsNull(arrValueNames) = True Then
    strPolicy = "1"
    strStatusData = "No FVE policy registry key found" & Err.Description
    objLog.Writeline strStatusData
    strStatusCode = 0
    CreateStatusMIF strStatusData
Else
    err.clear
    For R=0 To UBound(arrValueNames)
    If arrValueNames(R) = "EncryptionMethod" Then
        objReg.GetDWORDValue HKEY_LOCAL_MACHINE,strKeyPath,arrValueNames(R),dwValue
        EncryptionMethod = dwValue
        objLog.Writeline "Found EncryptionMethod with value: " & dwValue
        objLog.Writeline "Found EncryptionMethod policy registry key ignoring any /em options on command line"
        argEM = "0"
    End If
    If arrValueNames(R) = "RequireActiveDirectoryBackup" Then
        objReg.GetDWORDValue HKEY_LOCAL_MACHINE,strKeyPath,arrValueNames(R),dwValue
        RequireActiveDirectoryBackup = dwValue
        objLog.Writeline "Found RequireActiveDirectoryBackup with value: " & dwValue
    End if
    If arrValueNames(R) = "ActiveDirectoryBackup" Then
        objReg.GetDWORDValue HKEY_LOCAL_MACHINE,strKeyPath,arrValueNames(R),dwValue
        ActiveDirectoryBackup = dwvalue
        objLog.Writeline "Found ActiveDirectoryBackup with value: " & dwValue
    End if
    Next
End If

'Process local policy to see what BDE settings are available

If ActiveDirectoryBackup = 1 and RequireActiveDirectoryBackup = 1 Then
    objLog.WriteLine "Determined client Group Policy configured to require AD escrow of recovery password"
    BackupMandatory = "1"
Else If ActiveDirectoryBackup = 1 and RequireActiveDirectoryBackup = 0 Then
    objLog.WriteLine "Warning - Determined client Group Policy is configured to require AD escrow of recovery password but is not mandatory. If AD was not available when BitLocker was enabled recovery data may not be escrowed but BitLocker will be enabled."
    BackupMandatory = "0"
 End If
End If

End Function

'----------------------------------------------------------------------------------------
'Function 13 - Function used by the EvalGPO function to scan event logs for BitLocker recovery events
'----------------------------------------------------------------------------------------
Function getBDEEvents()

If strPolicy = "1" Then
    Exit Function
End If

Set objWMIService = GetObject("winmgmts:{impersonationLevel=impersonate}!\root\cimv2")
Set colBDEEvents = objWMIService.ExecQuery("Select * from Win32_NTLogEvent Where Logfile = 'System' and EventCode = '514' or EventCode = '513'")
If colBDEEvents.Count >= 1 Then
    For Each objBDEEvent in colBDEEvents
        If objBDEEvent.EventCode = "514" Then
            objLog.Writeline "---------------------------------------------------------------------------------"
            strStatusCode =  "WARNING - Found event log entry showing unsuccessful recovery information backup."
            objLog.Writeline strStatusData
	        objLog.WriteLine "Event log ID: " & objBDEEvent.EventCode
            objLog.WriteLine "Event log message: " & objBDEEvent.Message
            objLog.Writeline "---------------------------------------------------------------------------------"
	        strStatusCode = 0
	        CreateStatusMIF strStatusData
        ElseIf objBDEEvent.EventCode = "513" Then
            objLog.Writeline "---------------------------------------------------------------------------------"
            objLog.Writeline "Found event log entry showing successfull recovery information backup."
	        objLog.Writeline "Event log ID: " & objBDEEvent.EventCode 
	        objLog.Writeline "Event log message: " & objBDEEvent.Message
	        objLog.Writeline "---------------------------------------------------------------------------------"
        End If
    Next
Else
    objLog.WriteLine "Did not find a local event log entry for BitLocker AD backup."
End If

End Function

'----------------------------------------------------------------------------------------
'Function 14 - Used to create SMS status MIF's
'----------------------------------------------------------------------------------------
Function CreateStatusMIF(strStatusData)

err.clear
If argSMS = "1" then
    Set MIF=CreateObject("ISMIFCOM.InstallStatusMIF") 
    Mif.Create "BitLocker","Microsoft","BitLocker.vbs","1.0","","",strStatusData,strStatusCode

    If Err.number <> 0 Then 
	    objLog.Writeline "Failed to create the SMS status MIF."
    Else
	    objLog.WriteLine "Successfully created the SMS status MIF."
    End If 
End if

err.clear

End Function
'----------------------------------------------------------------------------------------
'Function 15 - Check for logged on User
'----------------------------------------------------------------------------------------
Function CheckUser

Set colComputer = objSWbemServices.ExecQuery("Select * from Win32_ComputerSystem") 
    For Each objComputer in colComputer
        If not objComputer.UserName = "" Then
        objlog.writeline "The following user is logged on: " & objComputer.UserName
        strCurrentUser = "1"
        Else 
        objlog.writeline "There is no user currently logged on to this computer"
        strCurrentUser = "0"
        End If
    Next 
End Function
'-----------------------------------------------------------------------------------------
'Function 16 - Create a Protect Key With Numerical Password 
'-----------------------------------------------------------------------------------------

Function CreateRP(objEnVol)
On Error Resume Next

Err.clear
intRC = objEnVol.ProtectKeyWithNumericalPassword("Recovery Password",Empty,vProtID)
objLog.Writeline "Attempting to create a recovery password..."
If intRC <> 0 Then 
        strStatusData = "WARNING - failed to create recovery password with the following exit code:  " & Hex(intRC)
        objLog.Writeline strStatusData
	    strStatusCode = 0
	    CreateStatusMIF strStatusData

	If Hex(intRC) = "8007054B" and BackupMandatory = "1" Then
   		strStatusData = "ERROR - failed to save recovery password to active directory with the following exit code:  " & Hex(intRC)
   		objlog.writeline "Group Policy is requiring AD backup of the recovery password but AD could not be contacted."
        	objLog.Writeline strStatusData
	    	strStatusCode = 0
	    	CreateStatusMIF strStatusData
	    
	    	Err.Clear
	    	objLog.Writeline "Deleting previously created key protectors..."
	    	intRC = objEnVol.DeleteKeyProtectors()
        If intRC <> 0 Then 
            strStatusData = "ERROR - failed to remove key protectors with the following exit code:  " & Hex(intRC) & "  Script is quitting..."
            objLog.Writeline strStatusData
	        strStatusCode = 0
	        CreateStatusMIF strStatusData
	        Wscript.Quit -1
        Else
	        objlog.writeline "Successfully removed key protectors with the following exit code:  " & Hex(intRC) & "  Script is quitting..."
	        Wscript.Quit -1
        End If
End If
    Else
	    objlog.writeline "Successfully created recovery password with the following exit code:  " & Hex(intRC)
	    If BackupMandatory = 0 Then
	        Wscript.Sleep(5000)
		getBDEEvents
	    End If
	    Exit Function
End If
err.clear

End Function
'----------------------------------------------------------------------------------------
'Function 17 - Request PIN from User
'----------------------------------------------------------------------------------------
Function GetPIN

strPIN=InputBox("Enter your new PIN number. The PIN must consist of a sequence of 4 to 20 digits.")
If strPIN = "" Then
    strStatusData = "ERROR - User canceled the PIN input operation. Script is quitting..."
    objLog.Writeline strStatusData
    strStatusCode = 0
    CreateStatusMIF strStatusData
    Wscript.Quit -1
End If

If IsNumeric(strPIN) Then
iLen = Len(strPIN)
    If iLen > 3 and iLen < 21 Then
        argValid = "1"
    Else        
	i = i + 1
	
        If i < 3 Then
	    Wscript.Echo "The PIN you entered was not 4 to 20 digits please re-enter a valid PIN."
	    objLog.writeline "WARNING - User did not enter a PIN that was not 4 to 20 digits."
            GetPIN
        Else
            strStatusData = "ERROR - The PIN was not 4 to 20 digits. You have exceeded your maximum attempts."
            Wscript.Echo "You exceeded the maximum number of attempts(3) to enter a PIN.  The process is quitting."
	        objLog.Writeline strStatusData
	        strStatusCode = 0
	        CreateStatusMIF strStatusData
	        argValid = "0"	    
        End If
    End If
Else
    Wscript.Echo "The PIN you entered contained letters or symbols.  The PIN must only contain numbers please re-enter a valid PIN."
    objlog.writeline "WARNING - User did not enter a PIN as a number."
    	i = i + 1
        If i < 3 Then
            GetPIN
        Else
	    Wscript.Echo "You exceeded the maximum number of attempts(3) to enter a PIN.  The process is quitting."
            strStatusData = "ERROR - The PIN was not entered as a number. You have exceeded your maximum attempts."
            objLog.Writeline strStatusData
	        strStatusCode = 0
	        CreateStatusMIF strStatusData
	    argValid = "0"
        End If
End If

End Function

'----------------------------------------------------------------------------------------
'Function 18 - Determine conversion status
'----------------------------------------------------------------------------------------
Function GetConversionStatus(strCS)
If strCS = 1 Then
    objlog.writeline "The volume has a status of fully encrypted but a clear key is present"
    intRC = objWMIBDE.EnableKeyProtectors()
        If intRC <> 0 Then 
            strStatusData = "ERROR - failed to enable key protector with the following exit code:  " & Hex(intRC)
            objLog.Writeline strStatusData
	        strStatusCode = 0
	        CreateStatusMIF strStatusData
        Else
         strStatusData = "Completed method EnableKeyProtectors with an exit code of:  " & Hex(intRC)
         objlog.writeline strStatusData
         strStatusBDE = strStatusData
        End If
Else
    If strCS = 2 Then
        strStatusData = "The volume has a status of encryption in progress"
        objLog.Writeline strStatusData
	    strStatusCode = 0
	    CreateStatusMIF strStatusData
	    Wscript.Quit -1
    Else    
        If strCS = 3 Then
            strStatusData = "The volume has a status of decryption in progress"
            objLog.Writeline strStatusData
	        strStatusCode = 0
	        CreateStatusMIF strStatusData
		Wscript.Quit -1
        Else
            If strCS = 4 Then
                strStatusData = "The volume has a status of encryption paused"
                objLog.Writeline strStatusData
	            strStatusCode = 0
	            CreateStatusMIF strStatusData
		    Wscript.Quit -1
            Else
                If strCS = 5 then
                    strStatusData = "The volume has a status of decryption paused"
                    objLog.Writeline strStatusData
	                strStatusCode = 0
	                CreateStatusMIF strStatusData
			Wscript.Quit -1
                End If
       End If
      End if
     End if
    End if

End Function


'----------------------------------------------------------------------------------------
'Function 19 - Check protect errors for any know problems
'----------------------------------------------------------------------------------------
Function CheckError(intRC)

If Hex(initRC) = "80310030" Then
    strStatusData = "ERROR - There is a boot CD/DVD or USB device in the system please remove and restart script.  Script is quitting..."
    objLog.Writeline strStatusData
    strStatusCode = 0
    CreateStatusMIF strStatusData
    Wscript.Quit -1
End If

End Function

'----------------------------------------------------------------------------------------
'Function 20 - Shows help for the script
'----------------------------------------------------------------------------------------
Function ShowHelp
On Error Resume Next
WScript.echo "************************************************************************************************************************************" & vbCr & _
"Example: EnableBitLocker.vbs /on:tpm /l:c:\bitlocker.log," & vbCr & vbCr & _
"/on:<tpm,tp,tsk,usb>" & vbTab & "used to specify options for turning on BitLocker (tpm,tp,tsk) REQUIRED" & vbCr & _
"/l:<location>" & vbTab & vbTab &  "specify to create a log file and it's location REQUIRED" & vbCr & _
"/rk:<location>" & vbTab & vbTab &  "create a recovery key and store in a particular location  OPTIONAL" & vbCr & _
"/em:<128d,256d,128,256>" & vbTab & "used to specify encryption algorithm if left out aes128d is used (aes128d, aes256d, aes128, aes256) OPTIONAL" & vbCr & _
"/promptuser" & vbTab & vbTab & "causes script to prompt user for TPM PIN or to insert USB drive OPTIONAL" & vbCr & _
"/sms" & vbTab & vbTab & vbTab & "creates an SMS status MIF for software distribution OPTIONAL" & vbCr & _
"/ro:" & chr(34) & "<oldownerpassword>" & chr(34) & " " & vbTab & "reset the TPM ownership using the existing owner password (password must be placed between quotes) OPTIONAL" & vbCr & vbCr & _
"************************************************************************************************************************************" & vbCr & _
WScript.quit
End Function
