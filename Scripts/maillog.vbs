' script to mail OSD logs and include Deployment related info
' 2015-5-17 Niall Brady.
' requires the mail executable files to be populated in
' the mailer sub-dir of Windows\System32 before running this script.
' for a list of all task sequence variables see: https://technet.microsoft.com/en-us/library/hh273375.aspx

Dim SERIAL, oSH, objFSO, MailServer, MailPort, MailTo, MailFrom, MailUser, MailPassword, tmpObj, tmpItem, DriveLetter, LogFileName, logfile
SERIAL 			= getserial
MailServer		="smtp.sendgrid.net"
MailPort		="2525"
MailTo			="osdsupport@windows-noob.com"
MailFrom		="noreply@windows-noob.com"
MailUser		="username"
MailPassword		="password"

CheckDriveLetter()
DriveLetter = CheckDriveLetter
PrepLogFile(DriveLetter)

Logtext "Starting logging process."
LogText "Checking Task Sequence variables"

On Error Resume Next
Set env 		= CreateObject("Microsoft.SMS.TSEnvironment") 
SMSTSPackageName 	= env("_SMSTSPackageName")
SMSTSCurrentActionName 	= env("_SMSTSCurrentActionName")
SMSTSLaunchMode 	= env("_SMSTSLaunchMode")
SMSTSInWinPE 		= env("_SMSTSInWinPE")
SMSTSSiteCode 		= env("_SMSTSSiteCode")
SMSTSBootUEFI		= env("_SMSTSBootUEFI")

LogText "Identifying Make/Model/Product info"

SystemName 		= "localhost"
set tmpObj 		= GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & SystemName & "\root\cimv2").InstancesOf ("Win32_ComputerSystem")
for each tmpItem in tmpObj
  	strComputerName = tmpItem.Name
	Make = trim(tmpItem.Manufacturer)
	Model = trim(tmpItem.Model)
next
Set tmpObj 		= Nothing: Set tmpItem = Nothing
set tmpObj 		= GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & SystemName & "\root\cimv2").InstancesOf ("win32_computersystemproduct")
for each tmpItem in tmpObj
  Product = trim(tmpItem.Version)
next

Set objFSO 		= CreateObject("Scripting.FileSystemObject")
Set oSH 		= CreateObject("Wscript.Shell")

LogText "Copying Logs to " & DriveLetter & "\Windows\temp\osdlogs\"

if DriveLetter = "X:" then
	State= "In WinPE"
	oSH.Run"xcopy " & DriveLetter & "\Windows\Temp\SMSTSLOG " & DriveLetter & "\Windows\temp\osdlogs\ /E /R /Y", 0, True	
ElseIf objFSO.FileExists(DriveLetter &"\Windows\CCM\LOGS\SMSTSLOG\smsts.log") then
	State= "In Windows with a CCM client installed"
	oSH.Run"xcopy " & DriveLetter & "\Windows\CCM\LOGS\SMSTSLOG " & DriveLetter & "\Windows\temp\osdlogs\ /E /R /Y", 0, True	
ElseIf objFSO.FileExists(DriveLetter &"\_SMSTaskSequence\LOGS\smsts.log") then
	State= "In Windows with no CCM client installed"
	oSH.Run"xcopy " & DriveLetter & "\_SMSTaskSequence\LOGS " & DriveLetter & "\Windows\temp\osdlogs\ /E /R /Y", 0, True
Else
	LogText "No smsts.log files found, nothing to email, exiting script."
	wscript.quit
End If
	LogText "The drive letter was detected as " & DriveLetter &"\. " & State & "."
	CompressLogs(DriveLetter)	
	CreateMail(DriveLetter)
	EmailLogs(DriveLetter)
	LogText "The script has completed all operations, exiting."
	wscript.quit

'****************************************************************************
' 				FUNCTIONS
'****************************************************************************

Private Function GetSerial()
	Dim objWMIService, objItem, colItems

	Set objWMIService = GetObject ("winmgmts:\\.\root\CIMV2")
	Set colItems = objWMIService.ExecQuery ("SELECT SerialNumber FROM Win32_bios")

	For Each objItem In colItems
	  GetSerial = objItem.SerialNumber
	Next
End Function

Private Function CreateMail(DriveLetter)
	oSH.RUN"cmd /C " & CHR(34) & "echo _______________________________________________________________" & 	"> " & DriveLetter & "\Windows\temp\mailbody ", 0, True
	oSH.RUN"cmd /C " & CHR(34) & "echo." & 	">> " & DriveLetter & "\Windows\temp\mailbody ", 0, True
	oSH.RUN"cmd /C " & CHR(34) & "echo Deployment Info" & ">> " & DriveLetter & "\Windows\temp\mailbody", 0, True
	oSH.RUN"cmd /C " & CHR(34) & "echo _______________________________________________________________" & 	">> " & DriveLetter & "\Windows\temp\mailbody ", 0, True
	oSH.RUN"cmd /C " & CHR(34) & "echo." & 	">> " & DriveLetter & "\Windows\temp\mailbody ", 0, True
	oSH.RUN"cmd /C " & CHR(34) & "echo ComputerName: 	" & strComputerName & 	">> " & DriveLetter & "\Windows\temp\mailbody ", 0, True
	oSH.RUN"cmd /C " & CHR(34) & "echo SerialNumber: 	" & Serial & 		">> " & DriveLetter & "\Windows\temp\mailbody ", 0, True
	oSH.RUN"cmd /C " & CHR(34) & "echo State: 		" & State & ">> " & DriveLetter & "\Windows\temp\mailbody ", 0, True
	oSH.RUN"cmd /C " & CHR(34) & "echo Make: 		" & Make  & " >> " & DriveLetter & "\Windows\temp\mailbody ", 0, True
	oSH.RUN"cmd /C " & CHR(34) & "echo Model: 		" & Model  & " >> " & DriveLetter & "\Windows\temp\mailbody ", 0, True
	oSH.RUN"cmd /C " & CHR(34) & "echo Product: 	" & Product  & " >> " & DriveLetter & "\Windows\temp\mailbody ", 0, True
	oSH.RUN"cmd /C " & CHR(34) & "echo Date: 		" 		& Date & 	" >> " & DriveLetter & "\Windows\temp\mailbody ", 0, True
	oSH.RUN"cmd /C " & CHR(34) & "echo Time: 		" & Time & " >> " & DriveLetter & "\Windows\temp\mailbody ", 0, True
	oSH.RUN"cmd /C " & CHR(34) & "echo _______________________________________________________________" & 	">> " & DriveLetter & "\Windows\temp\mailbody ", 0, True
	oSH.RUN"cmd /C " & CHR(34) & "echo." & 	">> " & DriveLetter & "\Windows\temp\mailbody ", 0, True
	oSH.RUN"cmd /C " & CHR(34) & "echo Task Sequence variable Info" & ">> " & DriveLetter & "\Windows\temp\mailbody", 0, True
	oSH.RUN"cmd /C " & CHR(34) & "echo _______________________________________________________________" & 	">> " & DriveLetter & "\Windows\temp\mailbody ", 0, True
	oSH.RUN"cmd /C " & CHR(34) & "echo." & 	">> " & DriveLetter & "\Windows\temp\mailbody ", 0, True
	oSH.RUN"cmd /C " & CHR(34) & "echo SMSTSPackageName:	" & SMSTSPackageName & 	">> " & DriveLetter & "\Windows\temp\mailbody ", 0, True
	oSH.RUN"cmd /C " & CHR(34) & "echo SMSTSCurrentActionName:	" & SMSTSCurrentActionName & 	">> " & DriveLetter & "\Windows\temp\mailbody ", 0, True
	oSH.RUN"cmd /C " & CHR(34) & "echo SMSTSBootUEFI:		" & SMSTSBootUEFI & 	">> " & DriveLetter & "\Windows\temp\mailbody ", 0, True
	oSH.RUN"cmd /C " & CHR(34) & "echo SMSTSLaunchMode:	" & SMSTSLaunchMode & 	">> " & DriveLetter & "\Windows\temp\mailbody ", 0, True
	oSH.RUN"cmd /C " & CHR(34) & "echo SMSTSInWinPE:		" & SMSTSInWinPE & 	">> " & DriveLetter & "\Windows\temp\mailbody ", 0, True
	oSH.RUN"cmd /C " & CHR(34) & "echo SMSTSSiteCode:		" & SMSTSSiteCode & 	">> " & DriveLetter & "\Windows\temp\mailbody ", 0, True
	oSH.RUN"cmd /C " & CHR(34) & "echo _______________________________________________________________" & 	">> " & DriveLetter & "\Windows\temp\mailbody ", 0, True
	oSH.RUN"cmd /C " & CHR(34) & "echo." & 	">> " & DriveLetter & "\Windows\temp\mailbody ", 0, True
	oSH.RUN"cmd /C " & CHR(34) & "echo Network Info" & ">> " & DriveLetter & "\Windows\temp\mailbody", 0, True
	oSH.RUN"cmd /C " & CHR(34) & "echo _______________________________________________________________" & 	">> " & DriveLetter & "\Windows\temp\mailbody ", 0, True
	oSH.RUN"cmd /C " & CHR(34) & "netsh int ip show config  >> " & DriveLetter & "\Windows\temp\mailbody " & CHR(34), 0, True
' 	to see what the email will contain without emailing anything unrem the next two lines
'	oSH.RUN"cmd /C " & CHR(34) & "notepad " & DriveLetter & "\Windows\temp\mailbody", 0, True
'	wscript.quit
	LogText "About to send the following email..." 
	Const ForReading = 1
	Set fso = CreateObject("Scripting.FileSystemObject")
	Set TextToRead     = fso.OpenTextFile(DriveLetter & "\Windows\temp\mailbody", ForReading)
	Do Until TextToRead.AtEndOfStream
  		LogText TextToRead.ReadLine
	Loop
	TextToRead.Close
End Function

Private Function CompressLogs(DriveLetter)
If objFSO.FileExists(DriveLetter & "\Windows\System32\mailer\rar.exe") then
	strCMD=DriveLetter & "\Windows\System32\mailer\rar.exe a " & DriveLetter & "\Windows\temp\osdlogs\osdlogs.rar " & DriveLetter & "\Windows\temp\osdlogs"
	LogText "About to run " & strCMD
	oSH.Run strCMD, 0, True
	Else 
	LogText "Rar.exe was not found, aborting MailLog script."
	Wscript.quit
End if
End Function

Private Function EmailLogs(DriveLetter)
if objFSO.FileExists(DriveLetter & "\Windows\System32\mailer\blat.exe") then
	strCMD=DriveLetter & "\Windows\System32\mailer\blat.exe -install " & MailServer & " -port " & MailPort & " -f " & MailFrom & " -u " & MailUser & " -pw " & MailPassword
	LogText "About to run " & strCMD
	oSH.Run strCMD, 0, True
	strCMD=DriveLetter & "\Windows\System32\mailer\blat.exe " & DriveLetter & "\Windows\temp\mailbody -to " & MailTo & " -subject " & chr(34) & "OSD Logs from " & strComputerName & chr(34) & " -attach " & chr(34)  &DriveLetter & "\Windows\temp\osdlogs\osdlogs.rar" & chr(34)
	LogText "About to run " & strCMD
	oSH.Run strCMD, 0, True
	HideTSProgress()
	LogText "An email containing the SMSTS logfiles has been sent, informing user via cmd prompt popup message."
	wscript.echo "An email containing the SMSTS logfiles has been sent."
Else 
	LogText "Blat.exe was not found, aborting MailLog script."
	Wscript.quit
End if
End Function

Function CheckDriveLetter()
Set objFSO = CreateObject("Scripting.FileSystemObject")
If objFSO.FileExists("X:\windows\temp\smstslog\smsts.log") then
	CheckDriveLetter="X:"
else

a=Array("C","D","E","F")
	for each Drive in a
	'wscript.echo "Checking drive " & Drive & ": for Explorer.exe in the Windows folder..."
    		If objFSO.FileExists(Drive & ":\Windows\explorer.exe") then
			CheckDriveLetter=Drive & ":"
		'	wscript.echo "Explorer.exe was found"
		Else
		'	wscript.echo "Explorer.exe was not found on this drive"
		End if
	next		
End if
End Function

' =====================================================
' PrepLogFile Subroutine
' =====================================================

Sub PrepLogFile(DriveLetter)
	Dim objFSO
	Set objFSO = CreateObject("Scripting.FileSystemObject")
	Set wShShell = WScript.CreateObject("WScript.Shell")
	
	If objFSO.FileExists("X:\windows\temp\smstslog\smsts.log") then
		LogFileName =  "X:\windows\temp\smstslog\MailLog.log"
	ElseIf objFSO.FileExists(DriveLetter &"\Windows\CCM\LOGS\SMSTSLOG\smsts.log") then
		LogFileName = DriveLetter & "\Windows\CCM\LOGS\SMSTSLOG\MailLog.log"
	ElseIf objFSO.FileExists(DriveLetter &"\_SMSTaskSequence\LOGS\smsts.log") then
		LogFileName = DriveLetter & "\_SMSTaskSequence\LOGS\MailLog.log"
	Else
		LogFileName = DriveLetter & "\windows\ccm\logs\smstslog\MailLog.log"
	End If
	'wscript.echo "Creating MailLog.log in " & LogFileName
	
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
	logfile.writeline "    windows-noob.com MailLog Script   	"
	logfile.writeline "##############################################"
End Sub

' =====================================================
' LogText Subroutine
' =====================================================

Sub LogText (TextToLog)	
	'wscript.echo "" & TextToLog
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

' =====================================================
' HideTSProgress
' =====================================================

Function HideTSProgress()
	On error resume next
	' Hide the progress dialog
    		Set oTSProgressUI = CreateObject("Microsoft.SMS.TSProgressUI")
    		oTSProgressUI.CloseProgressDialog
    		Set oTSProgressUI = Nothing
	LogText "Hiding TS Progress"
End Function