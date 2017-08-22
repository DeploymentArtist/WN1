echo off
REM
REM checks if in WinPE or Windows, does different actions based on what os it's in
REM Niall Brady 2015-5-15
REM


set "errorlevel="
SET In_WINPE=false

REG QUERY "HKEY_LOCAL_MACHINE\Software\Microsoft\Windows NT\CurrentVersion\WinPE"
cls
IF %ERRORLEVEL% EQU 0 SET In_WINPE=true
echo %~dp0vnc\
regedit /s %~dp0vnc\vnc.reg
echo Please provide the following information to the technician supporting you:


IF "%In_WINPE%"=="true" (
	echo.
	echo We are running in: WinPE
	echo.
	echo|set /p=Disabling firewall: 
    	wpeutil disablefirewall
	
) ELSE (
	echo.
	echo We are running in: Windows
	echo.
	echo|set /p=Disabling firewall: 
	netsh advfirewall set AllProfiles state off
	
)

	netsh int ipv4 show addresses  | find "IP Address:"| findstr /v "127.0.0.1"
	echo.
	echo Installing VNC...
	echo.
	"%~dp0vnc\winvnc.exe" -install
	REM wait for short period for the app to install
	ping 1.1.1.1 -n 1 -w 3000 > nul
	"%~dp0vnc\winvnc.exe" -service

for /f "tokens=2 delims==" %%I in ('wmic computersystem get model /format:list') do set "SYSMODEL=%%I"
set "Line1=*** System Model: %SYSMODEL%"
echo %Line1%


