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

# Variables declaration with user input
$rgname = Read-Host -Prompt "Enter the Resource group name where all the VMs are residing"
$textfilepath = Join-Path -Path $PSScriptRoot -ChildPath "devicelist.txt"
$diskSKU = "StandardSSD_LRS"


# Function to Update Azure VM Disk SKU
Function Update-AzureVMDiskSKU {
    param(
        [Parameter(Mandatory)]
        [string]$vmname,

        [Parameter(Mandatory)]
        [string]$diskskutype
    )
    
    try {
        # Retrieve the VM details along with its power state
        $vm = Get-AzVM -ResourceGroupName $rgname -Name $vmname -Status -ErrorAction "Stop"
        
        # Check if the VM is not deallocated; if it's running or stopped, deallocate it
        if ($vm.PowerState -ne "VM deallocated") {
            Stop-AzVM -ResourceGroupName $rgname -Name $vmname -Force -ErrorAction "Stop"
        }
        else {
            Write-Output "The VM '$vmname' is already in 'VM deallocated' state." 
        }

        # Get the OS Disk details for the VM
        $osDisk = Get-AzDisk -ResourceGroupName $rgname -DiskName $vm.StorageProfile.OsDisk.Name -ErrorAction "Stop"

        # Update the disk SKU
        $osDisk.Sku.Name = $diskskutype
        $null = Update-AzDisk -ResourceGroupName $rgname -DiskName $osDisk.Name -Disk $osDisk -ErrorAction "Stop" | Out-Null
        Write-Output "The OS disk SKU for VM '$vmname' has been updated to '$($osDisk.Sku.Name)' type."

    }
    catch {
        Write-Error "Failed to update disk SKU for VM: '$vmname'.`nError: $_"
    }
}

# Check if the file exists
if (-Not (Test-Path -Path $textfilepath)) {
    Write-Error "The file '$textfilepath' does not exist. Please ensure the file path is correct."
    exit
}

# Process each VM name from the file
$vmnamelist = Get-Content -Path $textfilepath
Foreach ($vmname in $vmnamelist) {
    if (-Not [string]::IsNullOrWhiteSpace($vmname)) {
        Update-AzureVMDiskSKU -vmname $vmname -diskskutype $diskSKU
    }
    else {
        Write-Error "VM name is empty in the file. Skipping entry."
    }
}
