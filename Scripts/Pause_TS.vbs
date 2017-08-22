'Script to tell the user that the task sequence is paused.
'windows-noob.com (c) August 2013.

'hide the Task Sequence Progress window

Set TsProgressUI = CreateObject("Microsoft.SMS.TsProgressUI")
TsProgressUI.CloseProgressDialog

'Popup Message

MsgBox "The task sequence is now paused." & chr(13) & "To resume the task sequence please click on OK.", 64,"Task Sequence PAUSED!"

wscript.quit(0)