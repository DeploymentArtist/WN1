'===============================================================================
'
' This script lists the access control entries (ACE's) configured on 
' Trusted Platform Module (TPM) and BitLocker Drive Encryption (BDE) schema objects 
' for the top-level domain.
'
' You can use this script to check that the correct permissions have been set and
' to remove TPM and BitLocker ACE's from the top-level domain.
'
' 
' Last Updated: 1/30/2006
' Last Reviewed: 9/24/2009
'
' Microsoft Corporation
'
' Disclaimer
' 
' The sample scripts are not supported under any Microsoft standard support program
' or service. The sample scripts are provided AS IS without warranty of any kind. 
' Microsoft further disclaims all implied warranties including, without limitation, 
' any implied warranties of merchantability or of fitness for a particular purpose. 
' The entire risk arising out of the use or performance of the sample scripts and 
' documentation remains with you. In no event shall Microsoft, its authors, or 
' anyone else involved in the creation, production, or delivery of the scripts be 
' liable for any damages whatsoever (including, without limitation, damages for loss 
' of business profits, business interruption,loss of business information, or 
' other pecuniary loss) arising out of the use of or inability to use the sample 
' scripts or documentation, even if Microsoft has been advised of the possibility 
' of such damages.
'
' Version 1.0.1 - Tested and re-released for Windows 7 and Windows Server 2008 R2
' 
'===============================================================================

' --------------------------------------------------------------------------------
' Usage
' --------------------------------------------------------------------------------

Sub ShowUsage
   Wscript.Echo "USAGE: List-ACEs"
   Wscript.Echo "List access permissions for BitLocker and TPM schema objects"
   Wscript.Echo ""
   Wscript.Echo "USAGE: List-ACEs -remove"
   Wscript.Echo "Removes access permissions for BitLocker and TPM schema objects"
   WScript.Quit
End Sub


' --------------------------------------------------------------------------------
' Parse Arguments
' --------------------------------------------------------------------------------

Set args = WScript.Arguments

Select Case args.Count
  
  Case 0
      ' do nothing - checks for ACE's 
      removeACE = False
      
  Case 1
    If args(0) = "/?" Or args(0) = "-?" Then
      ShowUsage
    Else 
      If UCase(args(0)) = "-REMOVE" Then
            removeACE = True
      End If
    End If

  Case Else
    ShowUsage

End Select

' --------------------------------------------------------------------------------
' Configuration of the filter to show/remove only ACE's for BDE and TPM objects
' --------------------------------------------------------------------------------

'- ms-TPM-OwnerInformation attribute
SCHEMA_GUID_MS_TPM_OWNERINFORMATION = "{AA4E1A6D-550D-4E05-8C35-4AFCB917A9FE}"

'- ms-FVE-RecoveryInformation object
SCHEMA_GUID_MS_FVE_RECOVERYINFORMATION = "{EA715D30-8F53-40D0-BD1E-6109186D782C}"

' Use this filter to list/remove only ACEs related to TPM and BitLocker

aceGuidFilter = Array(SCHEMA_GUID_MS_TPM_OWNERINFORMATION, _
                      SCHEMA_GUID_MS_FVE_RECOVERYINFORMATION)


' Note to script source reader:
' Uncomment the following line to turn off the filter and list all ACEs
'aceGuidFilter = Array()


' --------------------------------------------------------------------------------
' Helper functions related to the list filter for listing or removing ACE's
' --------------------------------------------------------------------------------

Function IsFilterActive()

    If Join(aceGuidFilter) = "" Then
       IsFilterActive = False
    Else 
       IsFilterActive = True
    End If

End Function


Function isAceWithinFilter(ace) 

    aceWithinFilter = False  ' assume first not pass the filte

    For Each guid In aceGuidFilter 

        If ace.ObjectType = guid Or ace.InheritedObjectType = guid Then
           isAceWithinFilter = True           
        End If
    Next

End Function

Sub displayFilter
    For Each guid In aceGuidFilter
       WScript.echo guid
    Next
End Sub


' --------------------------------------------------------------------------------
' Connect to Discretional ACL (DACL) for domain object
' --------------------------------------------------------------------------------

Set objRootLDAP = GetObject("LDAP://rootDSE")
strPathToDomain = "LDAP://" & objRootLDAP.Get("defaultNamingContext") ' e.g. dc=fabrikam,dc=com

Set domain = GetObject(strPathToDomain)

WScript.Echo "Accessing object: " + domain.Get("distinguishedName")
WScript.Echo ""

Set descriptor = domain.Get("ntSecurityDescriptor")
Set dacl = descriptor.DiscretionaryAcl


' --------------------------------------------------------------------------------
' Show Access Control Entries (ACE's)
' --------------------------------------------------------------------------------

' Loop through the existing ACEs, including all ACEs if the filter is not active

i = 1 ' global index
c = 0 ' found count - relevant if filter is active

For Each ace In dacl

 If IsFilterActive() = False or isAceWithinFilter(ace) = True Then

    ' note to script source reader:
    ' echo i to show the index of the ACE
    
    WScript.echo ">            AceFlags: " & ace.AceFlags
    WScript.echo ">             AceType: " & ace.AceType
    WScript.echo ">               Flags: " & ace.Flags
    WScript.echo ">          AccessMask: " & ace.AccessMask
    WScript.echo ">          ObjectType: " & ace.ObjectType
    WScript.echo "> InheritedObjectType: " & ace.InheritedObjectType
    WScript.echo ">             Trustee: " & ace.Trustee
    WScript.echo ""


    if IsFilterActive() = True Then
      c = c + 1

      ' optionally include this ACE in removal list if configured
      ' note that the filter being active is a requirement since we don't
      ' want to accidentially remove all ACEs

      If removeACE = True Then
        dacl.RemoveAce ace  
      End If

    end if

  End If 

  i = i + 1

Next


' Display number of ACEs found

If IsFilterActive() = True Then

  WScript.echo c & " ACE(s) found in " & domain.Get("distinguishedName") _
                 & " related to BitLocker and TPM" 'note to script source reader: change this line if you configure your own filter

  ' note to script source reader: 
  ' uncomment the following lines if you configure your own filter
  'WScript.echo ""
  'WScript.echo "The following filter was active: "
  'displayFilter
  'Wscript.echo ""

Else

  i = i - 1
  WScript.echo i & " total ACE(s) found in " & domain.Get("distinguishedName")
  
End If


' --------------------------------------------------------------------------------
' Optionally remove ACE's on a filtered list
' --------------------------------------------------------------------------------

if removeACE = True and IsFilterActive() = True then

  descriptor.DiscretionaryAcl =  dacl
  domain.Put "ntSecurityDescriptor", Array(descriptor)
  domain.setInfo

  WScript.echo c & " ACE(s) removed from " & domain.Get("distinguishedName")

else 

  if removeACE = True then

    WScript.echo "You must specify a filter to remove ACEs from " & domain.Get("distinguishedName") 
 
 end if


end if
