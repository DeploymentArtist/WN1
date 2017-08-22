' windows-noob.com (c) niall@windows-noob.com 2015/5/11.
' script to create a x:\hidden.txt file, will terminate the cmd.exee process once finished.
' the existence of the hidden.txt file will be checked for by the prestart command (check_hidden.vbs) and if it exists we display a prompt for a list of hidden task sequences deployment IDs
' the list of DeploymentId's is taken directly from a couple of files stored in a share \\server\share$ which you must maintain.
' see http://www.windows-noob.com/forums/index.php?/topic/4045-system-center-2012-configuration-manager-guides/ for details


Dim oSH
Set oSH = CreateObject("Wscript.Shell")
oSH.RUN"cmd /C " & CHR(34) &"netsh int ip show config Local > X:\hidden.txt " & CHR(34), 0, True
'wscript.echo "X:\Hidden.txt created !"
MsgBox "DEVEL mode Enabled !" 
' the code below will kill only the last launched process
' we do not want to kill the first cmd.exe as that may be attached to winpeshl and will reboot the computer
'
Set objFS=CreateObject("Scripting.FileSystemObject")
Set objArgs = WScript.Arguments
strProcess = "cmd.exe"
strComputer = "."
Set objWMIService = GetObject("winmgmts:{impersonationLevel=impersonate}!\\" & strComputer & "\root\cimv2")
' call WMI service Win32_Process 
Set colProcessList = objWMIService.ExecQuery("Select * from Win32_Process Where Name = '"&strProcess&"'")
t=0
For Each objProcess in colProcessList
    ' do some fine tuning on the process creation date to get rid of "." and "+"
    s = Replace( objProcess.CreationDate ,".","")
    s = Replace( objProcess.CreationDate ,"+","")
    ' Find the greatest value of creation date
    If s > t Then
        t=s
        strLatestPid = objProcess.ProcessID
    End If    
Next
'WScript.Echo "latest: " & t , strLatestPid
'Call WMI to terminate the process using the found process id above
Set colProcess = objWMIService.ExecQuery("Select * from Win32_Process where ProcessId =" & strLatestPid)
For Each objProcess in colProcess
    objProcess.Terminate()
Next