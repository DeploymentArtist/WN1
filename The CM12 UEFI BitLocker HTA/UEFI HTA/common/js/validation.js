// OSD Deployment HTA for multiple Operating Systems using System Center 2012 R2
// (c) niall@windows-noob.com  2014/12/31
// 

var oTimer;

function OnLoad()
{	
	var WShell 			= new ActiveXObject("WScript.Shell");
	var fso 			= new ActiveXObject("Scripting.FileSystemObject");
	var oEnvironment 	= new ActiveXObject("Microsoft.SMS.TSEnvironment");
	var oTSProgressUI 	= new ActiveXObject("Microsoft.SMS.TSProgressUI");
	oTSProgressUI.CloseProgressDialog();
	
	// populate oEnvironment("OSDComputerName")
	GetComputerName ();
	// verify if the auto populated value exists in AD
	compCheck (oEnvironment("OSDComputerName"));
	// populate the computername field
	document.getElementById('Item1_Text_1').value = oEnvironment("OSDComputerName");
	// populate the Restore options dropdown
	populateUSMTDropList()
	GetResourceID()
	
	//document.getElementById('DIV_MakeModel').innerHTML = ("Detected hardware: ") + oEnvironment("Make") + " " + oEnvironment("Model") + " " + "(" + oEnvironment("SerialNumber").substr(0, 10) + ")";
	//document.getElementById('DIV_TaskSequence').innerHTML = ("Task Sequence: ") +oEnvironment("Task Sequence: ") + oEnvironment("_SMSTSPackageName");
	document.title = "CM12 UEFI BitLocker HTA";
}

function populateUSMTDropList()
{
	var WShell = new ActiveXObject("WScript.Shell");
	var fso = new ActiveXObject("Scripting.FileSystemObject");
	var oEnvironment = new ActiveXObject("Microsoft.SMS.TSEnvironment");
	 
	sHTML = "<option value='NULL'>No Restore</option>\n";
	sHTML = sHTML + "<option value='SMP'>SMP (Requires Computer Association)</option>\n";
	sUsmtStorePath = "\\\\" + oEnvironment("BackupServer") + "\\" + oEnvironment("USMTStoreShare");

	if(fso.FolderExists(sUsmtStorePath))
	{
		var SubFolders = new Enumerator(fso.GetFolder(sUsmtStorePath).SubFolders);
		for(SubFolders.moveFirst();!SubFolders.atEnd();SubFolders.moveNext())
		{
			var folder = SubFolders.item();
			sLabel = folder.name ;
			sValue = folder.name;
			if (folder.name.toUpperCase() != "X86" && folder.name.toUpperCase() != "X64") 
				sHTML = sHTML + "<option value='" + sValue + "'>" + sLabel + "</option>\n" ;
		}		
	}	
	sHTML = "<select id='shareDropDown' name='shareDropDown'>\n" + sHTML + "</select>";
	document.getElementsByName('divUSMTDropDown').item(0).innerHTML = sHTML;
}

function CheckComputerName (strCaller)
{
	var WShell = new ActiveXObject("WScript.Shell");
	var oEnvironment = new ActiveXObject("Microsoft.SMS.TSEnvironment");
		//alert ("cscript //NoLogo " + GetScriptRoot() + "\\custom\\checkcomputername.wsf /computername:" + strCaller );
	var oExec = WShell.Run ("cscript //NoLogo " + GetScriptRoot() + "\\custom\\checkcomputername.wsf /ComputerName:" + strCaller , 0, true);
		// if you want to debug the web service not working unrem the below line and rem the above line, note set /debug:false after testing is complete.
		//var oExec = WShell.Run ("cscript //NoLogo " + GetScriptRoot() + "\\custom\\checkcomputername.wsf /ComputerName:" + strCaller + " /debug:true", 0, true);
	return oEnvironment("strCompAccount");	
}

function GetComputerName ()
{
	var WShell = new ActiveXObject("WScript.Shell");
	var oEnvironment = new ActiveXObject("Microsoft.SMS.TSEnvironment");
	var oExec = WShell.Run ("cscript //NoLogo " + GetScriptRoot() + "\\Custom\\GetComputerName.wsf", 0, true);
	return oEnvironment("OSDComputerName");
}

function GetScriptRoot ()
{
	var oEnvironment = new ActiveXObject("Microsoft.SMS.TSEnvironment");
	return oEnvironment("SCRIPTROOT");
}

function inpBoxUser_OnKeyUp(strCaller)
{
	if(oTimer != undefined)
		window.clearTimeout(oTimer);	
	strCaller = document.getElementById('item2_text_1').value
	oTimer = window.setTimeout("doADCheck('" + strCaller + "')", 1000);
}

function inpBoxComputer_OnKeyUp(strCaller)
{
	if(oTimer != undefined)
		window.clearTimeout(oTimer);	
	strCaller = document.getElementById('item1_text_1').value
	oTimer = window.setTimeout("compCheck('" + strCaller + "')", 1000);
}

function inpBoxSearch_OnKeyUp(strCaller)
{
	if(oTimer != undefined)
		window.clearTimeout(oTimer);
	strCaller = document.getElementById('searchstring_association').value
	oTimer = window.setTimeout("performeComputerSearch('" + strCaller + "')", 1000);
}

function DoesUserExist (strUserName)
{
	var WShell = new ActiveXObject("WScript.Shell");
	var oEnvironment = new ActiveXObject("Microsoft.SMS.TSEnvironment");
	var oExec = WShell.Run ("cscript //NoLogo " + GetScriptRoot() + "\\custom\\CheckUserName.wsf /LogonID:" + strUserName, 0, true);
	return oEnvironment("DoesUserExistResult");
}

function doADCheck(strCaller)
{
	DoesUserExist (strCaller);
	var oEnvironment = new ActiveXObject("Microsoft.SMS.TSEnvironment");
	strUserAccount = oEnvironment("DoesUserExistResult");
	
	if (strUserAccount == "false") {
		document.getElementById('item2_text_1').style.background = "#EC736A";
		document.getElementById('txtUserInfoNew').innerHTML = "No matching user account found";
	}
	else if(strUserAccount == "") {
		document.getElementById('item2_text_1').style.background = "#FFA61C";
		document.getElementById('txtUserInfoNew').innerHTML = "SERVER FAILURE";
	}
	else 
	{
		document.getElementById('item2_text_1').style.background = "#6EC6F0";
		document.getElementById('txtUserInfoNew').innerHTML = strCaller + " was found in AD";
	}
}

function compCheck(strCaller)
{
	//alert ('checking AD for = ' + strCaller );
	CheckComputerName (strCaller);
	// sets strCompAccount to true if in AD or False is not in AD
	// based on the above the text box will appear white, blue or red with text underneath.
	var oEnvironment = new ActiveXObject("Microsoft.SMS.TSEnvironment");
	strCompAccount = oEnvironment("ComputerAccountInAD");
	
	if (strCompAccount == "false") {
		document.getElementById('item1_text_1').style.background = "#EC736A";
		document.getElementById('txtComputerInfoNew').innerHTML = "No matching computer account found";
	}
	else if(strCompAccount == "SERVFAIL") {
		document.getElementById('item1_text_1').style.background = "#FFA61C";
		document.getElementById('txtComputerInfoNew').innerHTML = "SERVER FAILURE";
	}
	
	else 
	{
		document.getElementById('item1_text_1').style.background = "#6EC6F0";
		document.getElementById('txtComputerInfoNew').innerHTML = strCaller.toUpperCase() + " was found in AD";
	}
}

function populateTaskSequenceDropList()
{
	var WShell = new ActiveXObject("WScript.Shell");
	var fso = new ActiveXObject("Scripting.FileSystemObject");
	var oEnvironment = new ActiveXObject("Microsoft.SMS.TSEnvironment");
	
	// these variables should be populated in the task sequence, must have at least OSName1 defined. I'm leaving them here for debugging purposes
		//oEnvironment("OSName1") = "Windows 7 X64";
		//oEnvironment("OSName2") = "Windows 8.1 X64";
		//oEnvironment("OSName3") = "Windows Server2012R2";
		//oEnvironment("Tooltip1") = "Use the drop down menu to select from either a Windows 7 x64<BR> image .";
		//oEnvironment("Tooltip2") = "The computer will be reinstalled and data will be retained. Selecting to Run an Extensive<br> Checkdisk will perform an extensive check on the hard disc. This can take a long time to<br> complete so please  only select this option if you think the hard disc contains errors.";
		//alert ('Tooltip1=' + oEnvironment("TSTooltip1"));
	sHTML = "<option value='OSValue1'>" + oEnvironment("OSName1") + "</option>\n";
		if(oEnvironment("OSName2"))
			{sHTML = sHTML + "<option value='OSValue2'>" + oEnvironment("OSName2") + "</option>\n";
		}
	if(oEnvironment("OSName3"))
		{sHTML = sHTML + "<option value='OSValue3'>" + oEnvironment("OSName3") + "</option>\n";
		}
	sHTML = "<select id='ImageDropDown' name='ImageDropDown'>\n" + sHTML + "</select>";
	sHTML = sHTML + "<div class='coupontooltip' style = 'border:1px solid black; padding: 10px;'>\n";
	sHTML = sHTML + oEnvironment("Tooltip1");
	sHTML = sHTML + "</div>\n";	
	//document.getElementsByName('tblNewDetails').item(0).innerHTML = sHTML;
	
	// process the refresh bits...
	
	sHTML = "<option value='OSValue1'>" + oEnvironment("OSName1") + "</option>\n";
	if(oEnvironment("OSName2"))
		{sHTML = sHTML + "<option value='OSValue2'>" + oEnvironment("OSName2") + "</option>\n";
		}
	if(oEnvironment("OSName3"))
		{sHTML = sHTML + "<option value='OSValue3'>" + oEnvironment("OSName3") + "</option>\n";
		}
	sHTML = "<select id='ImageDropDownRefresh' name='ImageDropDownRefresh'>\n" + sHTML + "</select>";
	sHTML = sHTML + "<div class='coupontooltip' style = 'border:1px solid black; padding: 10px;'>\n";
	sHTML = sHTML + oEnvironment("Tooltip2");
	sHTML = sHTML + "</div>\n";	
	sHTML = sHTML + "<input name='ckBoxChkdsk' type='checkbox' id='ckBoxChkdsk'>Run Extensive Checkdisk\n";
	//document.getElementsByName('tblRefreshDetails').item(0).innerHTML = sHTML;	
}



function radioBtnChanged()
{
	if(document.getElementsByName('radio1').item(0).checked)
				{
				var oEnvironment = new ActiveXObject("Microsoft.SMS.TSEnvironment");
				oEnvironment("BitLockervalue") 		=	"128"
				}
			else
				{
				var oEnvironment = new ActiveXObject("Microsoft.SMS.TSEnvironment");
				oEnvironment("BitLockervalue") 		=	"256"
				}
}

function Backup()
{
	if(window.confirm("Please make sure your selections are ok before proceeding." ))
	{
		var oEnvironment 				= new ActiveXObject("Microsoft.SMS.TSEnvironment");
		oEnvironment("DeploymentType") 	= "BACKUPOLD"
		oEnvironment("DOCHKDSK") 		= document.getElementById('ckCHKDSK').checked;
		oEnvironment("DOECHKDSK") 		= document.getElementById('eckCHKDSK').checked;
		oEnvironment("DoBackup") 		= document.getElementById('ckBoxFullBackup').checked;
		oEnvironment("DoBackupNetwork") = document.getElementById('ckBoxFullBackupNetwork').checked;
		oEnvironment("DoOffline") 		= document.getElementById('ckBoxDoOffline').checked;
		ExitHTA();	
	}

	else
		document.execCommand("Refresh");
}

function Reinstall()
{
	if(window.confirm("Please make sure your selections are ok before proceeding." ))
	{
		var oEnvironment 					= new ActiveXObject("Microsoft.SMS.TSEnvironment");
		oEnvironment("DeploymentType") 		=	"REFRESH"
		var regionDrop 						= document.getElementById('RefreshregionDropDown');
		regionValue 						= regionDrop.options[regionDrop.selectedIndex].value;
		var languageDrop 					= document.getElementById('RefreshlanguageDropDown');
		languageValue 						= languageDrop.options[languageDrop.selectedIndex].value;
		//alert('regionValue,languageValue=' + regionValue + languageValue);
		// added code to give targetUser a value if none entered
			if(document.getElementById('item2_text_1').value)
				targetUser = document.getElementById('item2_text_1').value;
			else
				targetUser = " ";
			// added code to give targetComputer a value if none entered
			if(document.getElementById('item1_text_1').value)
				targetComputer = document.getElementById('item1_text_1').value;
			else
				targetComputer = oEnvironment("OSDCOMPUTERNAME");
		//AUTOComputerName = document.getElementById('ComputerNewckBoxAUTO-ComputerName').checked;
		SCEPvalue= document.getElementById('SCEPckBoxRefresh').checked;		
		EnableBitLockerRefresh = document.getElementById('RefreshckBoxEnableBitlocker').checked;
		oEnvironment("RegionValue") = regionValue;
		oEnvironment("LanguageValue") = languageValue;
		oEnvironment("TARGETUSER") = targetUser;
        oEnvironment("OSDCOMPUTERNAME") = targetComputer;
		//oEnvironment("AUTOComputerName") = AUTOComputerName;
		oEnvironment("SCEPvalue") = SCEPvalue;
		oEnvironment("EnableBitLockerRefresh") = EnableBitLockerRefresh;
		ExitHTA();
	}

	else
		document.execCommand("Refresh");
}
function NewComputer()
{
	if(window.confirm("Please make sure your selections are ok before proceeding." ))
	{
		var oEnvironment 					= new ActiveXObject("Microsoft.SMS.TSEnvironment");
		oEnvironment("DeploymentType") 		=	"NEWCOMPUTER"
		var regionDrop 						= document.getElementById('regionDropDown');
		regionValue 						= regionDrop.options[regionDrop.selectedIndex].value;
		var languageDrop 					= document.getElementById('languageDropDown');
		languageValue 						= languageDrop.options[languageDrop.selectedIndex].value;
		var usmtdrop 						= document.getElementById('shareDropDown');
		// alert('regionValue,languageValue=' + regionValue + languageValue);
		// added code to give targetUser a value if none entered
			if(document.getElementById('item2_text_1').value)
				targetUser = document.getElementById('item2_text_1').value;
			else
				targetUser = " ";
		// added code to give targetComputer a value if none entered
			if(document.getElementById('item1_text_1').value)
				targetComputer = document.getElementById('item1_text_1').value;
			else
				targetComputer = oEnvironment("OSDCOMPUTERNAME");
		//AUTOComputerName = document.getElementById('ComputerNewckBoxAUTO-ComputerName').checked;
		usmtvalue = usmtdrop.options[usmtdrop.selectedIndex].value;
		SCEPvalue= document.getElementById('SCEPckBoxNew').checked;		
		EnableBitLockerNew = document.getElementById('NewComputerckBoxEnableBitlocker').checked;
		PreProvBitLockerValue = document.getElementById('ckBoxPreProvBitLocker').checked;
		if(document.getElementById('item1_0_radio').checked)
				{
				oEnvironment("BitLockervalue") 		=	"128"
				}
			else
				{
				oEnvironment("BitLockervalue") 		=	"256"
				}
			
		
        oEnvironment("RegionValue") = regionValue;
		oEnvironment("LanguageValue") = languageValue;
		oEnvironment("TARGETUSER") = targetUser;
        oEnvironment("OSDCOMPUTERNAME") = targetComputer;
		//oEnvironment("AUTOComputerName") = AUTOComputerName;
		oEnvironment("SCEPvalue") = SCEPvalue;
		oEnvironment("EnableBitLockerNew") = EnableBitLockerNew;
		oEnvironment("PreProvBitLockerValue") = PreProvBitLockerValue;
		oEnvironment("uddir") = usmtvalue;
		
		ExitHTA();
	}

	else
		document.execCommand("Refresh");
}

function Reboot()
{
	var WShell = new ActiveXObject("WScript.Shell");
	if(window.confirm("Ok to reboot?"))
		WShell.Run ("wpeutil reboot",0, true);	
}

function Shutdown()
{
	var WShell = new ActiveXObject("WScript.Shell");
	if(window.confirm("Ok to Exit?"))
		WShell.Run ("wpeutil shutdown",0, true);		
}

function commandPrompt()
{
var WShell = new ActiveXObject("WScript.Shell");
//	if(window.confirm("Open Command Prompt?"))
		WShell.Run ("cmd.exe /k",1, true);
}

function cmtrace()
{
var WShell = new ActiveXObject("WScript.Shell");
//	if(window.confirm("Open Command Prompt?"))
		WShell.Run ("cmd.exe /k viewlog.cmd",1, true);
}
function showreport()
{
	var oEnvironment = new ActiveXObject("Microsoft.SMS.TSEnvironment");
		alert(oEnvironment("UUID"));	
}

function GetSCCMAssignedSite()
{
	var WShell = new ActiveXObject("WScript.Shell");
	var oEnvironment = new ActiveXObject("Microsoft.SMS.TSEnvironment");
	var oExec = WShell.Run ("cscript //NoLogo " + GetScriptRoot() + "\\custom\\sitecode.wsf", 0, true);
	return oEnvironment("SiteCode");
} 

function IsComputerKnown()
{
	var WShell = new ActiveXObject("WScript.Shell");
	var oEnvironment = new ActiveXObject("Microsoft.SMS.TSEnvironment");
	var oExec = WShell.Run ("cscript //NoLogo " + GetScriptRoot() + "\\custom\\IsComputerKnown.wsf", 0, true);
	return oEnvironment("IsComputerKnown");
} 

function GetResourceID()
{
	var WShell = new ActiveXObject("WScript.Shell");
	var oEnvironment = new ActiveXObject("Microsoft.SMS.TSEnvironment");
	var oExec = WShell.Run ("cscript //NoLogo " + GetScriptRoot() + "\\custom\\GetResourceID.wsf", 0, true);
	return oEnvironment("GetResourceID");
} 

function getUserFriendlyBoolValue( value ) {
	if ( value )
		return "Yes";
	else
	 return "No";
}
 	var ositecode = GetSCCMAssignedSite();
	var oIsComputerKnown = IsComputerKnown();
   	var oGetComputerName = GetComputerName();
	var oGetResourceID = GetResourceID();
	var oPopup = window.createPopup();
    
    function openPopup() {
        // The popup object exposes the document object and its
        // properties.
	
	var oEnvironment = new ActiveXObject("Microsoft.SMS.TSEnvironment");
        var arr = new Array();
        arr[arr.length] = '<p>';
        arr[arr.length] = '<div style="border: 2px solid black; background-color: #efefef; margin: 10px 10px 10px 10px;">';
        arr[arr.length] = '<h2>Deployment Information<\/h2>';
        arr[arr.length] = '<table style="background-color: #ffffff; margin: 10px 10px 10px 10px;" width="90%" cellpadding="0" cellspacing="0">';
        arr[arr.length] = '<tr>';
        arr[arr.length] = '<td>Computername<\/td>';
        arr[arr.length] = '<td>' + oEnvironment("OSDCOMPUTERNAME") + '<\/td>';
        arr[arr.length] = '<\/tr>';
        arr[arr.length] = '<tr>';
        arr[arr.length] = '<td>Computername in SCCM<\/td>';
        arr[arr.length] = '<td>' + oEnvironment("GetComputerName") + '<\/td>';
        arr[arr.length] = '<\/tr>';
		arr[arr.length] = '<tr>';
        arr[arr.length] = '<td>Make<\/td>';
        arr[arr.length] = '<td>' + oEnvironment("Make") + '<\/td>';
        arr[arr.length] = '<\/tr>';
		arr[arr.length] = '<tr>';
        arr[arr.length] = '<td>Model<\/td>';
        arr[arr.length] = '<td>' + oEnvironment("MODEL") + '<\/td>';
        arr[arr.length] = '<\/tr>';
        arr[arr.length] = '<tr>';
        arr[arr.length] = '<td>Memory<\/td>';
        arr[arr.length] = '<td>' + oEnvironment("Memory") + '<\/td>';
        arr[arr.length] = '<\/tr>';
        arr[arr.length] = '<tr>';
        arr[arr.length] = '<td>Is On Battery<\/td>';
        arr[arr.length] = '<td>' + oEnvironment("IsOnBattery") + '<\/td>';
        arr[arr.length] = '<\/tr>';
        arr[arr.length] = '<tr>';
		arr[arr.length] = '<td>Is UEFI<\/td>';
        arr[arr.length] = '<td>' + oEnvironment("IsUEFI") + '<\/td>';
        arr[arr.length] = '<\/tr>';
		arr[arr.length] = '<tr>';
		arr[arr.length] = '<td>Is Encrypted<\/td>';
        arr[arr.length] = '<td>' + oEnvironment("Drive_Protected") + '<\/td>';
        arr[arr.length] = '<\/tr>';
        arr[arr.length] = '<tr>';
		arr[arr.length] = '<td>Is VM<\/td>';
        arr[arr.length] = '<td>' + oEnvironment("IsVM") + '<\/td>';
        arr[arr.length] = '<\/tr>';
        arr[arr.length] = '<tr>';
		arr[arr.length] = '<td>Virtual Platform<\/td>';
        arr[arr.length] = '<td>' + oEnvironment("VMPlatform") + '<\/td>';
        arr[arr.length] = '<\/tr>';
        arr[arr.length] = '<tr>';
        arr[arr.length] = '<td>Asset Tag<\/td>';
        arr[arr.length] = '<td>' + oEnvironment("AssetTag") + '<\/td>';
        arr[arr.length] = '<\/tr>';
		arr[arr.length] = '<tr>';
        arr[arr.length] = '<td>Serial Number<\/td>';
        arr[arr.length] = '<td>' + oEnvironment("SERIALNUMBER") + '<\/td>';
        arr[arr.length] = '<\/tr>';
        arr[arr.length] = '<tr>';
        arr[arr.length] = '<td>IP Address<\/td>';
        arr[arr.length] = '<td>' + oEnvironment("IPADDRESS001") + '<\/td>';
        arr[arr.length] = '<\/tr>';
        arr[arr.length] = '<tr>';
        arr[arr.length] = '<td>MAC Address<\/td>';
        arr[arr.length] = '<td>' + oEnvironment("MACADDRESS001") + '<\/td>';
        arr[arr.length] = '<\/tr>';
        arr[arr.length] = '<tr>';
        arr[arr.length] = '<td>UUID<\/td>';
        arr[arr.length] = '<td>' + oEnvironment("UUID") + '<\/td>';
        arr[arr.length] = '<\/tr>';
      	arr[arr.length] = '<tr>';
        arr[arr.length] = '<td>Client Identity<\/td>';
        arr[arr.length] = '<td>' + oEnvironment("_SMSTSClientIdentity") + '<\/td>';
        arr[arr.length] = '<\/tr>';
        arr[arr.length] = '<tr>';
        arr[arr.length] = '<td>Assigned Site Code<\/td>';
		arr[arr.length] = '<td>' + oEnvironment("SiteCode") + '<\/td>';
        arr[arr.length] = '<\/tr>';
		arr[arr.length] = '<tr>';
        arr[arr.length] = '<td>This computer is known:<\/td>';
        arr[arr.length] = '<td>' + oEnvironment("IsComputerKnown") + '<\/td>';
        arr[arr.length] = '<\/tr>';
		arr[arr.length] = '<tr>';
        arr[arr.length] = '<td>The ResourceID is:<\/td>';
        arr[arr.length] = '<td>' + oEnvironment("GetResourceID") + '<\/td>';
        arr[arr.length] = '<\/tr>';
        arr[arr.length] = '<\/table>';
        arr[arr.length] = 'Click outside this window to close it.';
        arr[arr.length] = '<\div>';
        arr[arr.length] = '<\p>';
    
        var oPopBody = oPopup.document.body;
        // The following HTML populates the popup object with a string.
        oPopBody.innerHTML = arr.join('');
        // Parameters of the show method are in the following order: x-coordinate,y-coordinate, width, height, and the element to which the x,y 
        // coordinates are relative. Note that this popup object is displayed relative
	// to the body of the document.
        oPopup.show(68,0,620,535, document.body);
    }
		
function searchcomputer(searchstring ) {
	var WShell = new ActiveXObject("WScript.Shell");
	var oEnvironment = new ActiveXObject("Microsoft.SMS.TSEnvironment");
	oEnvironment("SearchString")=searchstring;
	var oExec = WShell.Run ("cscript //NoLogo " + GetScriptRoot() + "\\custom\\searchcomputerbyname.wsf", 0, true);
	return oEnvironment("search_Computer");
	}
	
function performeComputerSearch() {
        var searchString = '';
        var searchTextBox = document.getElementById('searchstring_association');
        var searchReturnedResult = false;

        /* 
        Clear the drop down from previous searches and add the first default element to the drop down. 
        ----------------------------------------------------------------------------------------------- 
        */

        var el = document.getElementById("destinationComputerList");

        /* Clear drop down list. */
        while(el.options.length > 0)
            el.options.remove(0);


        /* Create first element, showing that the user has to select an element from the drop down list. */
        var opt1 = document.createElement("option");
        el.options.add(opt1);
        opt1.text = 'Select Destination';
        opt1.value = '';

 
        /* 
        --------------------------------------------------------------------------------------------------
        Drop down cleared and first default value is added. 
        */

        if( searchTextBox != null ) {
            searchString = searchTextBox.value;
            if( searchString != '' ) {
                

				searchcomputer(searchString );
		var oEnvironment = new ActiveXObject("Microsoft.SMS.TSEnvironment");
		var currentComputerResourceId = oEnvironment("GetResourceId");
        /* When web service returns process the result. */
        var html = new ActiveXObject("Microsoft.XMLDOM");

		/* Here extract the result from the oEnviroment , remeber to create the oEnviorment object if it's not created before. */
		var result = oEnvironment("search_Computer");
		// alert(result);
        	
    
        html.loadXML(result);


               /* Retrive all the computers in the search result. */
        var anodes = html.selectNodes("//Resource");
         

                /* Create drop down elements base on the */
                
        for (var i=0; i < anodes.length; i++){
        var obsolete = anodes(i).selectSingleNode("Obsolete").text;
		var resourceid = anodes(i).selectSingleNode("ResourceID").text;
                    if( obsolete == 'false' && currentComputerResourceId != resourceid ) {
                        /* Computer is not Obsolete, added it to the drop down. */
                        var name = anodes(i).selectSingleNode("Name").text;    
                        var SMSUniqueIdentifier= anodes(i).selectSingleNode("ResourceID").text;
                        var opt = document.createElement("option");
						// Add an Option object to Drop Down/List Box
                        el.options.add(opt);
                        // Assign text and value to Option object
                        opt.text =  'ResourceID: ' + SMSUniqueIdentifier + ',   Name: ' + name;
                        opt.value = resourceid;

                        searchReturnedResult = true;
						
                    }
                }            

            }
            if( searchReturnedResult == true ) 
			{	
			alert( "Query for '" + searchString + "' was successful, please review the Select Destination drop down menu." );
           }
		   if ( searchReturnedResult == false ) 
		   {
                alert( "Query for '" + searchString + "' didn't return any computer to make association with, please redefine your search string." );
            }

        }
    }

function makeAssociation () {
        /* Make sure that the user has selected a destination computer. */

        var el = document.getElementById("destinationComputerList");
        var selectedresourceId = el.value;

        if( selectedresourceId == '' ) {
            /* User has not selected a computer to make association with. */
            alert('No destination computer selected' );

        } else {

            /* Call the other web service to make the association.  */
            //alert( 'The selected ResourceId  is: ' + selectedresourceId);
			
			var answer = makeAssosiationWebServiceCall(selectedresourceId);
			//alert( 'The reply from the webservice was: ' + answer);
		if(answer == "true" )
			{
				alert("Successfully Associated Computers");
				var oEnvironment = new ActiveXObject("Microsoft.SMS.TSEnvironment");
				oEnvironment("BackupSMP")= "True";
			} 
			else 
			{
				alert(answer + ' : UnSuccessfully Associated Computers');
			}
        } 
        
    }
	
function GetResourceID()
{
	var WShell = new ActiveXObject("WScript.Shell");
	var oEnvironment = new ActiveXObject("Microsoft.SMS.TSEnvironment");
	var oExec = WShell.Run ("cscript //NoLogo " + GetScriptRoot() + "\\custom\\GetResourceID.wsf", 0, true);
	return oEnvironment("GetResourceID");	
}	
function makeAssosiationWebServiceCall(dest)
{
	var WShell = new ActiveXObject("WScript.Shell");
	var oEnvironment = new ActiveXObject("Microsoft.SMS.TSEnvironment");
    oEnvironment("ReferenceComputerResourceId") = oEnvironment("GetResourceId");
    oEnvironment("DestinationComputerResourceId") = dest;
	var oExec = WShell.Run ("cscript //NoLogo " + GetScriptRoot() + "\\custom\\AddComputerAssociationbyID.wsf", 0, true);
	return oEnvironment("AddComputerAssociationByIDResult");
}

//** HARD EXIT Needed because unfortunately mshta.exe doesn't always obey a window.close()
function ExitHTA()
{
	var strcomputer = "."
	var objWMIService = GetObject("winmgmts:{impersonationlevel=impersonate}!\\\\" + strcomputer + "\\root\\cimv2");
	var colitems = new Enumerator(objWMIService.ExecQuery("SELECT * FROM Win32_Process WHERE Name = 'mshta.exe'"));
	for (; !colitems.atEnd(); colitems.moveNext()) {
	colitems.item().Terminate();
	}
}