     # script to remove drive letter from the "Windows RE Tools" drive for UEFI refresh scenarios
     # also removes any leftover SMS deployment files/folders if found.
     #
     # niall brady 2014/12/19
     #
   
     $ComputerName = $env:COMPUTERNAME
     $drivelabel = "Windows RE Tools"
     $disks = gwmi win32_logicaldisk -Filter "DriveType='3'"
     # create array of folders to delete
     $strfolders = @("_SMSTaskSequence", "_SmsTsWinPE", "SMSTSLOG")
    
     #
     write-host "The following disks were detected =" $disks
     # Look for disk with the desired label
     if ($targetdisk=gwmi win32_logicaldisk -Filter "VolumeName='$drivelabel'")     

     {      
        write-host "A disk with the label '$drivelabel' was " -nonewline
        Write-Host "found." -ForegroundColor Green
        $drive=$targetdisk.DeviceID
         
        # delete the deployment dirs if they exist
        foreach ($objItem in $strfolders) {
            if (Test-Path $drive\$objItem){
                #write-host "The path $drive\$objItem exists."
                Write-Host "Deployment dir '$drive\$objItem' found, removing ..." -nonewline
                $fso = New-Object -ComObject scripting.filesystemobject   
                $fso.DeleteFolder("$drive\$objItem*")
		        Write-Host "done!" -ForegroundColor Green
                } else {
                           # if the dir doesn't exist, write that fact and then continue the loop	    
	                       write-host "The path $drive\$objItem didn't exist, nothing to delete."    
                        }
        
      }


    # remove drive letter now....
    #     if ($targetdisk -ne $null) 
    #        {
    #            write-host "disk =" $targetdisk  
    #            $drive=$targetdisk.DeviceID
    #            write-host "Target drive letter identified as drive "   
    #            Write-Host " $drive." -ForegroundColor Green
    #            $drive2 = gwmi win32_volume -Filter "DriveLetter = '$drive'"
    #     
    #            if ($drive2 -ne $null) {
    #                write-host "About to remove the drive letter '$drive' from the drive with label '$drivelabel' from Computername: '$ComputerName'."
    #                # do the drive letter removal
    #                Set-WmiInstance -input $drive2 -Arguments @{DriveLetter=$null;Label=$Drivelabel} | Out-Null}
    #                # all done, now we can exit the script
    #                write-host "Disk cleaning operations complete, " -nonewline -ForegroundColor Green
    #        }
    #     write-host " ...continuing,"
        
     } 
       
         write-host "A disk with a Label matching " -ForegroundColor Red -nonewline
         write-Host "$drivelabel " -ForegroundColor Green -nonewline
         write-host "was not found, or it was found but had no drive letter assigned to it," -ForegroundColor Red

        # change the Windows RE Tools partition type and attributes via diskpart
        # assumes the Windows RE Tools recovery partition is the first partition of disk 0
        # I will make this more dynamic in the next version
        #
        NEW-ITEM –name diskpart.txt –itemtype file –force | OUT-NULL
        ADD-CONTENT –path diskpart.txt "SEL DISK 0"
        ADD-CONTENT –path diskpart.txt "SEL PAR 1"
        ADD-CONTENT –path diskpart.txt "DETAIL PAR"
        ADD-CONTENT –path diskpart.txt "SET ID=de94bba4-06d1-4d40-a16a-bfd50179d6ac"
        ADD-CONTENT –path diskpart.txt "gpt attributes=0x8000000000000001"
        ADD-CONTENT –path diskpart.txt "REMOVE"
        ADD-CONTENT –path diskpart.txt "RESCAN"
        ADD-CONTENT –path diskpart.txt "EXIT"


        #do the changes....

        $CHANGERETOOLSDISK=(DISKPART /S diskpart.txt)   
        
        # for debugging the output leave the below unremmed
        write-host "Diskpart output=" $CHANGERETOOLSDISK

      
      

          
       