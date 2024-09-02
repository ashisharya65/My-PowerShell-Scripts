<#
.SYNOPSIS
    This script updates the disk SKU of Azure Virtual Machines (VMs) from their current type to Premium SSD.

.DESCRIPTION
    The script reads a list of VM names from a text file and updates each VM's OS disk SKU to Premium SSD (Premium_LRS).
    It checks if the VM is deallocated before making changes to ensure the disk can be updated.
    The script is particularly useful for batch updating multiple VMs within a specific resource group.

.PARAMETER rgname
    The name of the resource group where the VMs reside.

.PARAMETER textfilepath
    The file path to the text file containing the list of VM names.

.PARAMETER vmnamelist
    The list of VM names extracted from the text file.

.EXAMPLE
    # Run the script and follow the prompts:
    # This will update the disk SKU for all VMs listed in devicelist.txt to Premium SSD
    .\UpdateVMDiskSKU.ps1

.NOTES
    - Ensure that the VMs are compatible with Premium SSDs and that the VM size supports Premium SSDs.
    - This script requires the Azure PowerShell module.
#>

# Define the variables
$rgname = Read-Host -Prompt "Enter the Resource group name where all the VMs are residing"
$textfilepath = $psscriptroot + "\devicelist.txt"
$vmnamelist = Get-Content -path $textfilepath

# Check if the file exists
if (-Not (Test-Path -Path $textfilepath)) {
    Write-Error "The file $textfilepath does not exist. Please ensure the file path is correct."
    exit
}

# Function to update Azure VM disk size
Function Update-AzureVMDiskSKU {
    param(
        [Parameter(Mandatory)]
        $vmname
    )
    
    try {
        # Retrieve the VM details along with its power state
        $vm = Get-AzVM -ResourceGroupName $rgname -Name $vmname -Status -ErrorAction Stop
        
        # Check if the VM is not deallocated; if it's running or stopped, deallocate it
        if ($vm.PowerState -ne "VM deallocated") {
            Stop-AzVM -ResourceGroupName $rgname -Name $vmname -Force -ErrorAction Stop
        }

        # Get the OS Disk details for the VM
        $osDisk = Get-AzDisk -ResourceGroupName $rgname -DiskName $vm.StorageProfile.OsDisk.Name -ErrorAction Stop

        # Update the disk SKU to Premium SSD (Premium_LRS)
        $osDisk.Sku.Name = "Premium_LRS"
        Update-AzDisk -ResourceGroupName $rgname -DiskName $osDisk.Name -Disk $osDisk -ErrorAction Stop

        Write-Output "Successfully updated disk SKU for $($vmname) VM to Premium SSD."

    }
    catch {
        Write-Error "Failed to update disk SKU for VM: $vmname.`nError: $_"
    }

}

# Looping through all VM names and updating their disk SKU to premium SSD
Foreach ($vmname in $vmnamelist) {
    if (-Not [string]::IsNullOrWhiteSpace($vmname)) {
        Update-AzureVMDiskSKU -vmname $vmname
    }
    else {
        Write-Error "VM name is empty in the file. Skipping entry."
    }
}
