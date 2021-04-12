function cloneConfig {  # this function uses a .json file template to pull the inputs from and automatically fill the variables

    $conf = (Get-Content -Raw -Path $configuration_path | ConvertFrom-Json)
    # converts the .json file being used into a readable format for the .ps1 file

    try {
        $VIserver = $conf.vcenter_server  # pipes the vCenter server input from the .json file into the variable
        Connect-VIServer -Server $VIserver -ErrorAction Stop  # connects to the vCenter server
    } catch {
        Write-Output "ISSUE: $PSItem"
        Break
    }
    
    try {
        $BaseLocation = $conf.base_folder  # pipes the folder location of the VMs from the .json file into the variable
        
        Write-Host "Here are the current Base VMs:"
        Get-VM -Location $BaseLocation -ErrorAction Stop | Format-Table Name  # formats the VMs in to table for a readable format 
        $basevm = Read-Host "Enter the name of the Base VM to clone"  # asks the user to input what VM they want to use from the table
    } catch {
        Write-Output "ISSUE: $PSItem"
        Break
    }
    
    $CloneType = $conf.clone_type  # pipes the clone type of the VM from the .json file into the variable
    
    $vmhost = $conf.esxi_server  # pipes the ESXi server to send the clone from the .json file into the variable
    
    $network = $conf.preferred_network  # pipes the preferred network for the clone from the .json file into the variable
    
    $dstore = $conf.preferred_datastore  # pipes the preferred datastore to put the clone on from the .json file into the variable
    
    $CloneName = Read-Host "Enter a Name for the Clone"  # asks the user to input a name for the clone
    
    if($CloneType -eq "F")  # if the clone type the user chosen is a 'Full Clone'
    { 
        try {
            Write-Host "Creating Full Clone of ${basevm}:"
            New-VM -Name $CloneName -VM $basevm -VMHost $vmhost -Datastore $dstore -ErrorAction Stop  # creates the full clone of a VM 
            Get-VM $CloneName | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $network -ErrorAction Stop  # sets the network adapter of the VM
        } catch {
            Write-Output "ISSUE: $PSItem"
            Break
        }
    }
    
    if($CloneType -eq "L")  # if the clone type the user chosen is a 'Linked Clone'
    {
        try {
            $snapshot = Get-Snapshot -VM $basevm -Name "Base"  # pipes the base snapshot of the VM being cloned 
    
            Write-Host "Creating Linked Clone of ${basevm}:"
            New-VM -Name $CloneName -VM $basevm -LinkedClone -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $dstore -ErrorAction Stop  # creates the linked clone based off of a VM snapshot
            Get-VM $CloneName | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $network -ErrorAction Stop  # sets the network adapter of the VM
        } catch {
            Write-Output "ISSUE: $PSItem"
            Break
        }
    }
}

function cloneInteractive {  # this function is for when a user wants to manually input the variables for cloning the VM
    try {
        $VIserver = Read-Host "Enter vCenter Hostname or IP Address"  # asks the user to input the vCenter hostname or IP Address of the vCenter server they want to connect to
        Connect-VIServer -Server $VIserver -ErrorAction Stop  # connects to the vCenter server
    }
    catch {
        Write-Output "ISSUE: $PSItem"
        Break
    }

    try {
        $BaseLocation = Read-Host "Enter folder name for Base VMs"  # asks the user what folder they would like to enter
        
        Write-Host "Here are the current Base VMs:"
        Get-VM -Location $BaseLocation -ErrorAction Stop | Format-Table Name  # pull and lists the VM located in the folder
        $basevm = Read-Host "Enter the name of the Base VM to clone"  # asks the user to name a VM they would like to clone
    }
    catch {
        Write-Output "ISSUE: $PSItem"
        Break
    }

    $CloneType = Read-Host "[F]ull Clone or [L]inked Clone"  # asks the user if they want a 'Full' or 'Linked' Clone

    Write-Host "Here are the current VM Hosts on the vCenter Server:"
    Get-VMHost | Format-Table Name  # pulls and formats the list of VM Hosts on the connected vCenter Server
    $vmhost = Read-Host "Enter the VM Host to place the Clone"  # asks the user to name a VM Host tp place the clone

    Write-Host "Here are the current Port Groups:"
    Get-VirtualPortGroup | Format-Table name  # pulls and formats the list of Port Groups (network adapters) on the connected vCenter Server
    $network = Read-Host "Enter Network Adapter Assignment"  # asks the user to name a netowrk adpater to place the clone

    Write-Host "Here are the current Datastores on the Host:"
    Get-Datastore | Format-Table Name  # pulls and formats the list of datastores on the connected vCenter Server
    $dstore = Read-Host "Enter the name of the Datastore to place the Clone"  # asks the user to name a datastore to place the clone

    $CloneName = Read-Host "Enter a Name for the Clone"  # asks the user to input a name for the clone

    if($CloneType -eq "F")  # if the clone type the user chosen is a 'Full Clone'
    { 
        try {
            Write-Host "Creating Full Clone of ${basevm}:"
            New-VM -Name $CloneName -VM $basevm -VMHost $vmhost -Datastore $dstore -ErrorAction Stop  # creates the full clone of a VM 
            Get-VM $linkedname | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $network -ErrorAction Stop  # sets the network adapter of the VM
        }
        catch {
            Write-Output "ISSUE: $PSItem"
            Break
        }
    }

    if($CloneType -eq "L")  # if the clone type the user chosen is a 'Linked Clone'
    {
        try {
            $snapshot = Get-Snapshot -VM $basevm -Name "Base"  # pipes the base snapshot of the VM being cloned

            $linkedname = "{0}.linked" -f $CloneName  # renames the name of the clone to addd '.linked' at the end

            Write-Host "Creating Linked Clone of ${basevm}:"
            New-VM -Name $linkedname -VM $basevm -LinkedClone -ReferenceSnapshot $snapshot -VMHost $vmhost -Datastore $dstore -ErrorAction Stop  # creates the linked clone based off of a VM snapshot
            Get-VM $linkedname | Get-NetworkAdapter | Set-NetworkAdapter -NetworkName $network -ErrorAction Stop  # sets the network adapter of the VM
        }
        catch {
            Write-Output "ISSUE: $PSItem"
            Break
        }
    }
}

$configuration_path = "Management Automation/cloner.json"  # the path to the .json file being used as a template when variable is used
$interactive = $true  # states that the following functions are going to be interactive when variable is used
$conf = ""  # a blank variable for the .json configuration file

if (Test-Path $configuration_path) {
    Write-Host "Using a Saved Configuration File:"
    $interactive = $false
    $conf = (Get-Content -Raw -Path $configuration_path | ConvertFrom-Json)
    cloneConfig
} elseif ($interactive) {
    Write-Host "Interactive Mode"
    cloneInteractive
}
