Set env = CreateObject("Microsoft.SMS.TSEnvironment")
For each v in env.GetVariables
   WScript.Echo v & " = " & env(v)
Next 