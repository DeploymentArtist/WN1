strComputer = "." 
Set objWMIService = GetObject("winmgmts:\\" & strComputer & "\root\CIMV2\Security\MicrosoftTpm") 
Set colItems = objWMIService.ExecQuery( _
    "SELECT * FROM Win32_Tpm",,48) 
For Each objItem in colItems 
    Wscript.Echo "-----------------------------------"
    Wscript.Echo "Win32_Tpm instance"
    Wscript.Echo "-----------------------------------"
    Wscript.Echo "IsActivated_InitialValue: " & objItem.IsActivated_InitialValue
    Wscript.Echo "IsEnabled_InitialValue: " & objItem.IsEnabled_InitialValue
    Wscript.Echo "IsOwned_InitialValue: " & objItem.IsOwned_InitialValue
    Wscript.Echo "ManufacturerId: " & objItem.ManufacturerId
    Wscript.Echo "ManufacturerVersion: " & objItem.ManufacturerVersion
    Wscript.Echo "ManufacturerVersionInfo: " & objItem.ManufacturerVersionInfo
    Wscript.Echo "PhysicalPresenceVersionInfo: " & objItem.PhysicalPresenceVersionInfo
    Wscript.Echo "SpecVersion: " & objItem.SpecVersion
Next

    Wscript.Echo "if No output then Win32_Tpm instance not enabled ?"
