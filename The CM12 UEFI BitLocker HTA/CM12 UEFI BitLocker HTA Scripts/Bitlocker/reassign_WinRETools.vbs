' On error resume next
' This script: Niall Brady, 2014/12/415
' This script sets the Windows RE Tools volume back to Recovery
'

' Find the recovery drive letter
Set objWMIService = GetObject("winmgmts:\\.\root\cimv2") 
Set colItems = objWMIService.ExecQuery("select * from Win32_LogicalDisk where DriveType=3 and DeviceID !='X:' and FileSystem = 'NTFS'",,48) 

For Each objItem in colItems 
    Wscript.Echo "DriveType: " 	& objItem.DriveType
    Wscript.Echo "FileSystem: " & objItem.FileSystem
    Wscript.Echo "Name: " 	& objItem.Name
target2= objItem.Name
Next

Wscript.Echo "Windows Recovery Tools detected as drive " & target2

' Run diskpart
set objShell = WScript.CreateObject("WScript.Shell")
set objExec = objShell.Exec("diskpart.exe")

' commands to run in diskpart
strOutput = ExecuteDiskPartCommand("SEL DISK 0")
strOutput = ExecuteDiskPartCommand("SEL VOL " & target2 & " ") 
strOutput = ExecuteDiskPartCommand("SET ID=de94bba4-06d1-4d40-a16a-bfd50179d6ac")
strOutput = ExecuteDiskPartCommand("REMOVE")
strOutput = ExecuteDiskPartCommand("RESCAN")
strOutput = ExecuteDiskPartCommand("LIST VOL")
ExitDiskPart

Wscript.Echo "Changed drive letter " & target2 & " Partition type to Recovery."

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