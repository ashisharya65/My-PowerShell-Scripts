
<#
.SYNOPSIS
    Exports information about virtual machines (VMs) within Azure Availability Sets to a CSV file.

.DESCRIPTION
    This script retrieves VM information from Azure Availability Sets in a specified resource group. 
    It creates a custom object containing the Availability Set name and the associated VM names. 
    Finally, it exports this information to a CSV file.

.PARAMETER tenant
    Azure tenant ID.

.PARAMETER subscription
    Azure subscription name.

.PARAMETER resourcegroup
    Azure resource group name.

.OUTPUTS
    The script exports the Availability Set names and associated VM names to a CSV file located in the same directory as the script.

.NOTES
    - The script requires the Azure PowerShell module to be installed.
    - The CSV file will be named based on the script name (excluding the .ps1 extension).

.EXAMPLE
    .\Export-AvailabilitySetVMInfo.ps1 -tenant "your_tenant_id" -subscription "your_subscription_name" -resourcegroup "your_resource_group"
#>

# declaring parameters
param(
    $tenant,
    $subscription,
    $resourcegroup
)

# Connect to Azure account using provided tenant and subscription
Connect-Azaccount -tenant $tenant -subscription $subscription | Out-Null

# Retrieve Availability Set information
$AVSets = Get-AzAvailabilityset -ResourceGroupName $resourcegroup | Select-Object Name,VirtualMachinesReferences

# Initialize a list to store Availability Set and VM information
$AvSetVMInfo = [System.Collections.Generic.List[Object]]@()

# Iterate through each Availability Set
Foreach ($AS in $AVSets){
    # Retrieve VM names associated with the Availability Set
    $VMNames = Get-AzAvailabilityset -ResourceGroupName $resourcegroup -Name $($AS.Name) | `
                Select-Object -expandproperty VirtualMachinesReferences | `
                Foreach-Object { 
                    ($_.id -split "/")[8]
                }

    # Create a custom object with Availability Set and VM names
    $psobject = [pscustomobject]@{
        AvailabilitySet = $($AS.Name)
        VMName = $VMNames -join ", "
    }

    # Add the custom object to the list
    $AvSetVMInfo.Add($psobject) | Out-Null
}

# Define the CSV file path
$csvfilepath = Join-Path $PSScriptRoot "$($MyInvocation.MyCommand.Name.Replace('.ps1', '')).csv"

# Export the information to the CSV file
Write-Host "Exporting to CSV file" -foregroundcolor "Yellow"
$AVSetVmInfo | Export-Csv -path $csvfilepath -NoTypeInformation 
