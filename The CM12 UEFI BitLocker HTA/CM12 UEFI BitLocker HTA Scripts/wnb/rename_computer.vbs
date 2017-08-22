Dim sNewComputerName, oTaskSequence, sTSMachineName
Set oTaskSequence = CreateObject ("Microsoft.SMS.TSEnvironment")

 

' Get the name the computer is set to receive and truncate to first 6 letters
' sTSMachineName = oTAskSequence("_SMSTSMachineName")
sTSMachineName = oTAskSequence("OSDComputerName")
sTSMachineName  = lcase(left(sTSMachineName,6))

 

If sTSMachineName = "minint" Then
    ' The wscript.echo commands are logged in SMSTS.log for troubleshooting.
    ' They are not displayed to the end user.
    wscript.echo "Detected that the computer name is scheduled to receive a random value.  Prompting user to input a standard name."
 
    sNewComputerName = InputBox ("Please enter a standard computer name." & VbCrLf & VbCrLf & "Machine names must be 3-14 characters, and include a-z, A-Z, 0-9, ONLY."  & VbCrLf & VbCrLf & "Example:  colb104stf01", "Computer Name", , 200,200)

 oTaskSequence("OSDComputerName") = sNewComputerName
    wscript.echo "Set Task Sequence variable OSDComputerName to: " & sNewComputerName
Else
    wscript.echo "Computer set to receive a standard name, continuing as is."
End If
