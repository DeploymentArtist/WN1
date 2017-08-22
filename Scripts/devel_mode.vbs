' niall brady (c) 2015/5/12
' This script allows you to selectively run a hidden prestart command based on previous actions.
' In addition, it will list all DeploymentId's found in a file called DeploymentIDs.txt located on a UNC share
' The user specified can be a local user.

Option Explicit
DIM fso, WshNetwork, WshShell, strUser, strPassword, clDrives, i, objFileToRead, strFileText, strFileTextBeta, LogFileName, logfile

Set WshShell = CREATEOBJECT("WScript.Shell")
PrepLogFile
Logtext "Starting logging process."

Set fso = CreateObject("Scripting.FileSystemObject")
Set WshNetwork = WScript.CreateObject("WScript.Network")
strUser = "CM_HL"
strPassword = "P@ssw0rd"

'Disconnect ALL mapped drives
Disconnect()

'Map network drive
Logtext "Connecting to hidden$ share"
WshNetwork.MapNetworkDrive "Z:", "\\CM01.corp.viamonstra.com\hidden$", , strUser, strPassword

'Check if Devel Mode was selected
Logtext "Checking if Devel Mode was selected"

	If (fso.FileExists("x:\hidden.txt")) Then
Logtext "Devel Mode was selected!"
'WScript.Echo("hidden.txt file exists, devel mode selected!")
' Now check to see if DeploymentIDs.txt file exists, this file is used so that we can display what deployment ID's are available in the prestart prompt
		If (fso.FileExists("Z:\DeploymentIDs.txt")) Then  
		LogText "DeploymentIDs.txt file was found, displaying a list of Deployment IDs and waiting for input..."
			'Found the DeploymentIDs.txt file, read it's contents into a variable
			Set objFileToRead = CreateObject("Scripting.FileSystemObject").OpenTextFile("z:\DeploymentIDs.txt",1)
			strFileText = objFileToRead.ReadAll()
			objFileToRead.Close
			Set objFileToRead = Nothing
			'WScript.Quit()
		else
			'msgbox "could not find DeploymentIDs.txt, please select manually"
LogText "DeploymentIDs.txt file was NOT found or could not be READ..."
		End If

' Devel mode was selected so display the Prestart prompt
	Dim env,value,value2
	value=InputBox ("The following hidden DeploymentID's are available." & vbCrLf & vbCrLf & strFileText & vbCrLf & vbCrLf & "Please enter the Task Sequence Deployment ID eg: PS1201B7 and click [OK] or click [Cancel] to continue.")
' Now check to see if the user wants to list all DeploymentID's
	If lcase(value)="listall" Then
	LogText "Listall was entered - checking for ALLDeploymentIDs.txt"
		If (fso.FileExists("Z:\AllDeploymentIDs.txt")) Then  
		LogText "AllDeploymentIDs.txt file was found, displaying a longer list of Deployment IDs and waiting for input..."
			Set objFileToRead = CreateObject("Scripting.FileSystemObject").OpenTextFile("z:\AllDeploymentIDs.txt",1)
			strFileTextBeta = objFileToRead.ReadAll()
			objFileToRead.Close
			Set objFileToRead = Nothing
			value2=InputBox ("The following hidden DeploymentID's are available." & vbCrLf & vbCrLf & strFileText & vbCrLf & strFileTextBeta & vbCrLf & vbCrLf &"Please enter the Task Sequence Deployment ID eg: PS1201B7 and click [OK] or click [Cancel] to continue.")
			'	MsgBox "The following BETA Task Sequence Advertisement ID will be selected: " & value2
			if value2 = "" then 
			LogText "Setting SMSTSPreferredAdvertID to nothing as nothing was entered."
				else
					set env = CreateObject("Microsoft.SMS.TSEnvironment")
					LogText "Setting SMSTSPreferredAdvertID to: " & value2
					env("SMSTSPreferredAdvertID") = value2
			end if
		else
			'msgbox "could not find AllDeploymentIDs.txt, please select manually"
			LogText "AllDeploymentIDs.txt file was NOT found or could not be READ..."
		End If
	Else
 		'MsgBox "The following Task Sequence Advertisement ID will be selected: " & value
			if value = "" then 
			LogText "Setting SMSTSPreferredAdvertID to nothing as nothing was entered."
				else
					set env = CreateObject("Microsoft.SMS.TSEnvironment")
					LogText "Setting SMSTSPreferredAdvertID to: " & value
					env("SMSTSPreferredAdvertID") = value
			end if
	End If
	Else
  	'WScript.Echo("The hidden.txt File does not exist so will not change SMSTSPreferredAdvertID!")
Logtext "Devel Mode was NOT selected, therefore will not set any hidden task sequence DeploymentID's"
End If

'job done !
Disconnect()
LogText "All done, exiting script." 
WScript.Quit()

Function Disconnect()
Logtext "Disconnecting any connected network shares."
Set clDrives = WshNetwork.EnumNetworkDrives
	For i = 0 to clDrives.Count -1 Step 2
		WSHNetwork.RemoveNetworkDrive clDrives.Item(i), True, True
	Next
End Function


' =====================================================
' PrepLogFile Subroutine
' =====================================================

Sub PrepLogFile
	
	Dim objFSO

	Set wShShell = WScript.CreateObject("WScript.Shell")
	LogFileName = "X:\Windows\Temp\SMSTSLOG\Devel_Mode.log"

	'On Error Resume Next
	Err.Clear

	Set objFSO = CreateObject("Scripting.FileSystemObject")
	
	If Err.number <> 0 Then
		MsgBox("****   ERROR (" & Err.Number & ") Could not create Logfile - exiting script")
		ExitScript 0
	Else
		If objFSO.FileExists(LogFileName) Then
			objFSO.DeleteFile(LogFileName) 
		End If
		Err.Clear
		Set logfile = objFSO.CreateTextFile(LogFileName)
		If Err.number <> 0 Then
			MsgBox "ERROR (" & Err.Number & ") Could not create logfile (File) - exiting script"
			ExitScript 0
		End If
	End If
	
	Err.Clear
	
	'On Error GoTo 0
	
	logfile.writeline "##############################################"
	logfile.writeline "    windows-noob.com Devel Mode Script   "
	logfile.writeline "##############################################"
End Sub

' =====================================================
' LogText Subroutine
' =====================================================

Sub LogText (TextToLog)
	logfile.writeline "" & Now() & " " & TextToLog
End Sub

' =====================================================
' Exit function
' =====================================================

Function ExitScript(iStatus)
	if iStatus <> 0 then
		set WshShell = WScript.CreateObject("WScript.Shell")
		ComSpec = WshShell.ExpandEnvironmentStrings("%COMSPEC%")
		WshShell.Run "cmtrace.exe " & LogFileName , 1, False
	End if

	LogText "All done, exiting successfully"
	wscript.quit(iStatus)
End Function




