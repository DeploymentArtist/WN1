$DataDrive="E:"
New-SmbShare –Name Hidden$ –Path $DataDrive\Hidden -ReadAccess CM_HL
icacls $DataDrive\Hidden /grant '"CM01\CM_HL":(OI)(CI)(R)'