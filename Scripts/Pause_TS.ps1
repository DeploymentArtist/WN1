#
# Pause a task sequence using PowerShell
# niall brady 2015/4/18
#
# Close the Task Sequence UI temporarily
# if you want to test this outside of a task sequence then rem out the two lines below
$TSProgressUI = New-Object -COMObject Microsoft.SMS.TSProgressUI
$TSProgressUI.CloseProgressDialog()
# popup the popup
[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
$OUTPUT= [System.Windows.Forms.MessageBox]::Show("To resume the task sequence please click on OK." , "Task Sequence PAUSED!")
# check for click
if ($OUTPUT -eq "OK" )
{

#..Exit from the pause

}
else
{
#..pause the task sequence
} 