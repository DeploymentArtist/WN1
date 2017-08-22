' This script attempts to verify if there is suitable storage available and then checks that a suitable 
' network connection exists in WinPE, it is designed to run before the task sequence engine starts.
' 
' To use, add one or more servers to the ServersToPing array and it will ping each in turn, if all fail then it will trigger the failure message
' The failure message contains network pnp device ID's for detected nics based on a WMI search term of Network, Ether or Lan in addition to basic troubleshooting information.
'
' niall brady windows-noob.com (c) 2015/6/3
'
On Error Resume Next
DIM objShell, WshNetwork, sPingTarget, iNumberofFails, iFailureLimit, LogFileName, logfile, objFSO, objFile, outFile, CheckPartitions
Set WshNetwork = WScript.CreateObject("WScript.Network")
Set objShell = WScript.CreateObject( "WScript.Shell" )
' hide the CMD prompt..
strCMD = "x:\windows\system32\windowhide.exe " & Chr(34) & "cscript.exe CheckForNetwork.vbs" & Chr(34)
objShell.Run(strCMD)

PrepLogFile

LogText "init WinPE"
objShell.Run("x:\windows\system32\wpeinit -winpe"),1,true
Set objShell = Nothing
LogText "sleep 15 seconds for network to get up"
wscript.sleep 15000
LogText "check if there's any local storage"
CountSuitableHDD()
'wscript.quit

	if CountSuitableHDD=0 then 
		ListSataAdapters()
	else
	end if
		LogText "SATA checks were OK, will now start testing the network.."
		Do Until retry="giveup"
			iNumberofFails = 0	
			PingLoop()
			LogText "looping..."

			if iNumberofFails = iFailureLimit then
				ListNetworkAdapters()
			else
				LogText "The number of failures (" & iNumberofFails & ") was less than the set limit of (" & iFailureLimit & ") therefore continuing..."
			
				' If we got here, both storage and network are ok, 
				LogText "no problems found, starting normal Task Sequence env"
				Set objShell = WScript.CreateObject( "WScript.Shell" )
				objShell.Run("x:\windows\system32\winpeshl.exe"),1,true
				Set objShell = Nothing
				wscript.quit
			End if
		Loop 
wscript.quit

Function CountSuitableHDD()
	CheckForSata=0
	strComputer = "."
Set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
Set colDisks = objWMIService.ExecQuery ("SELECT * FROM Win32_LogicalDisk")
For Each objDisk in colDisks	
	if (objDisk.DriveType = 3) AND (objDisk.DeviceID <>"X:") then
		' AND (FileSystem = "NTFS") 
		' if we got here then the drive type is ok for use with SCCM
		LogText "DriveType: Local hard disk."
		CheckForSata=CheckForSata+1
	else
		' if we got here then the DriveType could not be determined, maybe not partitioned ?
		LogText "DeviceID: " & objDisk.DeviceID & " DriveType: could not be determined."	
		CheckPartitions = True
	End if
Next
LogText "CheckForSata = " & CheckForSata
' check if a disk was found as the first physical disk, but DriveType could not be determined..
if CheckPartitions = True then
Set objWMIService = GetObject("winmgmts:" & "{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
Set colDisks = objWMIService.ExecQuery ("SELECT * FROM Win32_DiskDrive")
	For Each objDisk in colDisks	
		if (objDisk.Name = "\\.\PHYSICALDRIVE0") AND (objDisk.InterfaceType <> "USB")then 
			' if we got here then the drive type is ok for use with SCCM
			LogText objDisk.Name & ": Disk was detected!"
			CheckForSata=CheckForSata+1
		else
		LogText objDisk.Name & ": No disk was detected."
		End if
	Next
End If
LogText "CheckForSata = " & CheckForSata
If CheckForSata >= 1 then
		LogText "A disk was detected, it may be not partitioned or it may have an unknown partition type. Partitioning will be handled by the task sequence therefore continuing.."
	else
end if
CountSuitableHDD=CheckForSata
End Function

Function PingLoop()
On Error Resume Next

ServersToPing=Array("192.168.1.1","192.168.1.200","192.168.1.214")   
iFailureLimit = uBound(ServersToPing) + 1
for each x in ServersToPing
    sPingTarget = x
	LogText("Attempting to ping: " + sPingTarget)
if Ping(sPingTarget) = True then
    LogText "Host " & sPingTarget & " contacted"
Else
    LogText "Host " & sPingTarget & " could not be contacted"
	LogText "Number of fails= " & iNumberofFails
End if
next

End Function


Function Ping(sPingTarget)
On Error Resume Next
Dim objPing, objRetStatus
    set objPing = GetObject("winmgmts:{impersonationLevel=impersonate}").ExecQuery _
      ("select * from Win32_PingStatus where address = '" & sPingTarget & "'")
If Err.Number <> 0 Then
  	LogText "HALT ! Couldn't connect to Win32_PingStatus, no ip ? " & "Error Description: " & Err.Description & "Error number: "  & Err.Number
	Err.Clear
	ListNetworkAdapters()
Else
    for each objRetStatus in objPing
        if IsNull(objRetStatus.StatusCode) or objRetStatus.StatusCode<>0 then
    Ping = False
	iNumberofFails = iNumberofFails + 1 
          '  LogText "Status code is " & objRetStatus.StatusCode
        else
            Ping = True
        end if
    next
End if
End Function 

Function ListSataAdapters()
On Error Resume Next
strComputer = "."
set tmpObj = GetObject("winmgmts:\\" & strComputer & "\root\cimv2").InstancesOf ("Win32_ComputerSystem")
	for each tmpItem in tmpObj
		MakeModel = trim(tmpItem.Manufacturer) & " " & trim(tmpItem.Model)
	next
Set tmpObj = Nothing
Set tmpItem = Nothing
' look for devices that match SATA, Raid, STORAGE, SCSI or SAS

Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")
Set colItems = objWMIService.ExecQuery("Select * from Win32_PNPEntity where (description LIKE '%sata%') OR (description LIKE '%raid%') OR (description LIKE '%Storage%') OR (description LIKE '%SCSI%') OR (description LIKE '%SAS%')",,48)
' hide USB devices or DeviceIDs matching ROOT

For Each objItem in colItems
	if (instr (objitem.Description, "USB") = 0) AND (instr (objitem.DeviceID, "ROOT") = 0) and (instr (objitem.DeviceID, "ISATAP") = 0)then
		SataResult=SataResult + ("Description: "  & objItem.Description & vbCrLf & "PNPDeviceID: " & objitem.DeviceID & vbCrLf & vbCrLf)
	end if
Next
LogText "Unable to find a valid internal storage device. Popping up message to user."
result = MsgBox ("Unable to find a valid internal storage device." & vbCrLf & vbCrLf & "Possible causes can be: " & vbCrLf & vbCrLf & "* Missing Storage drivers. " & vbCrLf & "* Missing HDD/SSD. " & vbCrLf & vbCrLf & "Please inform the person supporting you that the following hardware was detected: " & vbCrLf & vbCrLf & SataResult &"Computer: "& MakeModel & vbCrLf & vbCrLf & "Press [OK] to exit and reboot or press [Cancel] to open a CMD prompt to troubleshoot further."_
, vbOKCancel, "Warning: Unable to continue")

		Select Case result
		Case vbOK
				Set objShell = Nothing
				Reboot
		Case vbCancel
				Set objShell = WScript.CreateObject( "WScript.Shell" )
				objShell.Run("cmd.exe /s")
				msgbox "When you are finished, press [OK] to reboot"
				Reboot
		End Select
End function

Function ListNetworkAdapters()
On Error Resume Next
strComputer = "."
set tmpObj = GetObject("winmgmts:\\" & strComputer & "\root\cimv2").InstancesOf ("Win32_ComputerSystem")
	for each tmpItem in tmpObj
		MakeModel = trim(tmpItem.Manufacturer) & " " & trim(tmpItem.Model)
	next
Set tmpObj = Nothing
Set tmpItem = Nothing
' look for devices that match ETHER, NETWORK or LAN

Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")
Set colItems = objWMIService.ExecQuery("Select * from Win32_PNPEntity where (description LIKE '%ether%') OR (description LIKE '%network%') OR (description LIKE '%LAN%') OR (description LIKE '%Giga%')",,48)
' hide WIRELESS nics or DeviceIDs matching ROOT

For Each objItem in colItems
	if (instr (objitem.Description, "Wireless") = 0) AND (instr (objitem.DeviceID, "ROOT") = 0) AND (instr (objitem.Description, "Bluetooth") = 0) then
		NicResult=NicResult + ("Description: "  & objItem.Description & vbCrLf & "PNPDeviceID: " & objitem.DeviceID & vbCrLf & vbCrLf)
	end if
Next
LogText "Unable to find a valid network connection. Popping up message to user."
result = MsgBox ("Unable to find a valid network connection." & vbCrLf & vbCrLf & " Possible causes can be: " & vbCrLf & vbCrLf & "* Invalid or missing IP Address. " & vbCrLf & "* Network card/cable unplugged or damaged. " & vbCrLf & "* Network Switch not connected or malfunctioning. " & vbCrLf & "* Network drivers missing. " & vbCrLf & vbCrLf & "Please inform the person supporting you that the following hardware was detected: " & vbCrLf & vbCrLf & NicResult &"Computer: "& MakeModel & vbCrLf & vbCrLf & "Press [YES] to retry, press [NO] to exit and reboot or press [Cancel] to open a CMD prompt to troubleshoot further."_
, vbYESNOCancel, "Warning: Cannot contact the network")

		Select Case result
		Case vbYES
				Set objShell = Nothing
				retry="dontgiveup"
		Case vbNO
				Set objShell = Nothing
				retry="giveup"
				Reboot
		Case vbCancel
				Set objShell = WScript.CreateObject( "WScript.Shell" )
				objShell.Run("cmd.exe /s")
				msgbox "When you are finished, press [OK] to reboot"
				Reboot
		End Select

if retry="dontgiveup" then
'
else

' if we get here then NO Network card was detected using the query above, try again using a more generic query

Dim objWMIService, colItems
	Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\cimv2")
	Set colItems = objWMIService.ExecQuery("Select * from Win32_NetworkAdapter",,48)
' hide WIRELESS nics or DeviceIDs matching ROOT

For Each objItem in colItems
	if (instr (objitem.Description, "Wireless") = 0) AND (instr (objitem.PNPDeviceID, "ROOT") = 0) AND (instr (objitem.Description, "WAN") = 0)  AND (instr (objitem.Description, "Bluetooth") = 0) AND (instr (objitem.Description, "Virtual") = 0) then

NicResult=NicResult + ("Description: "  & objItem.Description & vbCrLf & "PNPDeviceID: " & objitem.PNPDeviceID & vbCrLf & vbCrLf)
end if
Next
LogText "Unable to find a valid network connection. Popping up message to user."
result = MsgBox ("Unable to find a valid network connection." & vbCrLf & vbCrLf & " Possible causes can be: " & vbCrLf & vbCrLf & "* Invalid or missing IP Address. " & vbCrLf & "* Network card/cable unplugged or damaged. " & vbCrLf & "* Network Switch not connected or malfunctioning. " & vbCrLf & "* Network drivers missing. " & vbCrLf & vbCrLf & "Please inform the person supporting you that the following hardware was detected: " & vbCrLf & vbCrLf & NicResult &"Computer: "& MakeModel & vbCrLf & vbCrLf & "Press [OK] to exit and reboot or press [Cancel] to open a CMD prompt to troubleshoot further."_
, vbYESNOCancel, "Warning: Cannot contact the network")

			Select Case result
		Case vbYES
				Set objShell = Nothing
				retry="dontgiveup"
		Case vbNO
				Set objShell = Nothing
				retry="giveup"
				Reboot
		Case vbCancel
				Set objShell = WScript.CreateObject( "WScript.Shell" )
				objShell.Run("cmd.exe /s")
				msgbox "When you are finished, press [OK] to reboot"
				Reboot
		End Select
End if
End Function

Sub Reboot
Set WshShell = WScript.CreateObject("WScript.Shell")
WshShell.Run "wpeutil reboot"
End Sub

' =====================================================
' PrepLogFile Subroutine
' =====================================================

Sub PrepLogFile
	
	Dim objFSO
	On Error Resume Next
	Set wShShell = WScript.CreateObject("WScript.Shell")
	Set objFSO = CreateObject("Scripting.FileSystemObject")
	LogDir = "X:\Windows\Temp\SMSTSLOG"
	LogFileName = LogDir + "\" + "CheckForNetwork.log"
	'create SMSTSLOG folder if it doesn't exist
	If Not objFSO.FolderExists(LogDir) Then
	wscript.echo LogDir & " doesn't exist, creating it..."
	CreatePath LogDir
	End If 
		If objFSO.FileExists(LogFileName) Then
			objFSO.DeleteFile(LogFileName) 
		End If
		Err.Clear
		Set logfile = objFSO.CreateTextFile(LogFileName)
		If Err.number <> 0 Then
			MsgBox "ERROR (" & Err.Number & ") Could not create logfile - exiting script"
			ExitScript 0
		End If
	
	logfile.writeline "Starting log at "  & Now()
	Err.Clear
End Sub

' =====================================================
' LogText Subroutine
' =====================================================

Sub LogText (TextToLog)
wscript.echo TextToLog
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
' Create Full Path of Log Dir
' =====================================================

Sub CreatePath(ByVal FullPath)
On Error Resume Next
Set fso = CreateObject("Scripting.FileSystemObject")
If Not fso.FolderExists(FullPath) Then
CreatePath fso.GetParentFolderName(FullPath)
fso.CreateFolder FullPath
If Err.number <> 0 Then
			MsgBox "ERROR (" & Err.Number & ") Could not create logdir X:\Windows\Temp\SMSTSLOG - exiting script"
			ExitScript 0
		End If
End If
End Sub




