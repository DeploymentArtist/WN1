echo off
REM
REM checks if in WinPE or Windows, does different actions based on what os it's in
REM Niall Brady 2015-5-24
REM


set "errorlevel="
SET In_WINPE=false
REG QUERY "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\WinPE"
cls

IF %ERRORLEVEL% EQU 0 SET In_WINPE=true

IF "%In_WINPE%"=="true" (echo Setting registry keys....
reg add "HKCU\Software\Classes\.lo_" /f /t REG_SZ /d "Log.File"
reg add "HKCU\Software\Classes\.log" /f /t REG_SZ /d "Log.File"
reg add "HKCU\Software\Classes\Log.File\shell\open\command" /f /t REG_SZ /d "\"X:\sms\bin\x64\CMTrace.exe\" \"^%%1\"

if exist X:\Windows\Temp\SMSTSLOG\smsts.log (echo In WinPE, the X:\Windows\Temp\SMSTSLOG\smsts.log file exists, opening it in CMTrace &  X:\sms\Bin\x64\CMtrace.exe X:\Windows\Temp\SMSTSLOG\smsts.log) else (echo Could not find the smsts.log file.)

) ELSE if exist C:\_SMSTaskSequence\LOGS\smsts.log (echo In Windows, the C:\_SMSTaskSequence\LOGS\smsts.log file exists, opening it in CMTrace & CMtrace.exe C:\_SMSTaskSequence\LOGS\smsts.log) else (if exist C:\Windows\CCM\LOGS\SMSTSLOG\smsts.log (echo In Windows, the C:\Windows\CCM\LOGS\SMSTSLOG\smsts.log file exists, opening it in CMTrace & CMtrace.exe C:\Windows\CCM\LOGS\SMSTSLOG\smsts.log) else (echo Could not find the smsts.log file with the CCM client.))
)
Echo Exiting ViewLog.