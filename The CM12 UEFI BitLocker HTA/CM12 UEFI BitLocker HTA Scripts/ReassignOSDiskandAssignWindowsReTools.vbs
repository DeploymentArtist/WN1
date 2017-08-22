' On error resume next
' This script: niall@windows-noob.com (c) 2014/12/19
' This script is used to change the drive letter which is assigned to the BitLockered volume on UEFI systems
' and then to assign drive letter C: to the Windows RE Tools volume
'

' find the BitLockered volume (it should be drivetype=3, and with an unknown file system)
Set objWMIService = GetObject("winmgmts:\\.\root\cimv2") 
Set colItems = objWMIService.ExecQuery( _
    "SELECT * FROM Win32_LogicalDisk where DriveType = '3' and FileSystem != 'NTFS' and FileSystem != 'FAT32'",,48) 

For Each objItem in colItems 
    Wscript.Echo "DriveType: " 	& objItem.DriveType
    Wscript.Echo "FileSystem: " & objItem.FileSystem
    Wscript.Echo "Name: " 	& objItem.Name
target= objItem.Name
Next

Wscript.Echo "BitLockered drive detected as drive " & target

' Run diskpart
set objShell = WScript.CreateObject("WScript.Shell")
set objExec = objShell.Exec("diskpart.exe")

' commands to run in diskpart
strOutput = ExecuteDiskPartCommand("SEL DISK 0")
strOutput = ExecuteDiskPartCommand("SEL VOL " & target & " ") 
strOutput = ExecuteDiskPartCommand("REMOVE")
strOutput = ExecuteDiskPartCommand("ASSIGN LETTER = N:")
strOutput = ExecuteDiskPartCommand("RESCAN")
ExitDiskPart

Wscript.Echo "Changed drive letter " & target & " to drive N:"


'assign driveletter to Windows RE Tools now..
Set objWMIService = GetObject("winmgmts:\\.\root\cimv2")
Set colVolumes = objWMIService.ExecQuery ("Select * from Win32_Volume Where Label = 'Windows RE Tools'")

For Each objVolume in colVolumes
	objVolume.DriveLetter = "C:"
    objVolume.Put_
	Wscript.Echo "Windows RE Tools drive letter is now set to: " & objVolume.DriveLetter
	target2= objVolume.DriveLetter
Next

' Run diskpart
set objShell = WScript.CreateObject("WScript.Shell")
set objExec = objShell.Exec("diskpart.exe")

' commands to run in diskpart 
' make the partition a Primary partition type (it was Recovery)
strOutput = ExecuteDiskPartCommand("SEL DISK 0")
strOutput = ExecuteDiskPartCommand("SEL PAR 1") 
strOutput = ExecuteDiskPartCommand("SET ID=ebd0a0a2-b9e5-4433-87c0-68b6b72699c7")
strOutput = ExecuteDiskPartCommand("gpt attributes=0x8000000000000001") 
strOutput = ExecuteDiskPartCommand("rescan")
ExitDiskPart

Wscript.Echo "Changed drive letter " & target2 & " Partition type to Primary."
wscript.quit

Function ExecuteDiskPartCommand (strCommand)

    ' Run the command we want
    objExec.StdIn.Write strCommand & VbCrLf

    ' If we read the output now, we will get the one from previous command (?). As we will always
    ' run a dummy command after every valid command, we can safely ignore this
    Do While True
        IgnoreThis = objExec.StdOut.ReadLine & vbcrlf
		Wscript.echo "in diskpart doing: " & strCommand
        ' Command finishes when diskpart prompt is shown again
        If InStr(IgnoreThis, "DISKPART>") <> 0 Then Exit Do
    Loop

    ' Run a dummy command, so the next time we call this function and try to read output,
    ' we can safely ignore the result
    objExec.StdIn.Write VbCrLf

    ' Read command's output
    ExecuteDiskPartCommand = ""
    Do While True
        ExecuteDiskPartCommand = ExecuteDiskPartCommand & objExec.StdOut.ReadLine & vbcrlf

        ' Command finishes when diskpart prompt is shown again
        If InStr(ExecuteDiskPartCommand, "DISKPART>") <> 0 Then Exit Do
    Loop

End Function

Sub ExitDiskPart
    ' Run exit command to exit the tool
    objExec.StdIn.Write "exit" & VbCrLf
End Sub

wscript.quit