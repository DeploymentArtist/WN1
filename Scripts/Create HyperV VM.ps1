#
# create a hyperV Virtual machine
# niall brady 2015/4/13
#
$Name =  Read-Host "Please enter the Virtual Machine name "
if ($Name -eq ""){$Name="New Virtual Machine"} ; if ($Name -eq $NULL){$Name="New Virtual Machine"}
$MemoryStartupBytes = 2048MB
$Generation = 2 # Gen 2 for UEFI
$BootDevice = "NetworkAdapter"
if ($Generation -eq "1"){$BootDevice="LegacyNetworkAdapter"}
$ComputerName = "Localhost"
$Path = "C:\VMs\$Name"
$NewVHDPath = $Path + "\$Name.vhdx"
# if ($Generation -eq "1"){$NewVHDPath = $Path + "\$Name.vhd"}
$SwitchName = "Internal"
$NewVhdSizeBytes = 127GB
# check if DIR to store the VM already exists, otherwise create it
 if (Test-Path $Path){
                
                Write-Host "HyperV virtual machine directory: '$Path' already exists, please remove and try again or use a different Virtual Machine name, aborting ..." -nonewline
		        break
                } else {
                            # if the dir doesn't exist, write that fact and then continue the loop	    
	                        write-host "The path '$Path' didn't exist, creating."    
                            New-Item $Path -type directory
                        }

# create the VM
New-VM -Name $Name -MemoryStartupBytes $MemoryStartupBytes -Generation $Generation -BootDevice $BootDevice -ComputerName $ComputerName -NewVHDPath $NewVHDPath -NewVhdSizeBytes $NewVhdSizeBytes -SwitchName $SwitchName -Verbose