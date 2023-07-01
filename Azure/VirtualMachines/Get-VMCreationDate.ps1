
<#
    .SYNOPSIS
    Get creation date of Virtual Machines (VMs) from an Azure region within your Azure subscription.
    
    .DESCRIPTION
    This script will help you to get the creation date of all the VMS from an Azure region within your Azure subscription.

    .EXAMPLE
    .\Get-VMCreationDate.ps1 -Subscriptionid <Azure Subscription id> -location <Azure Region like Eastus etc.>
    
    .NOTES
    Author : Ashish Arya (@ashisharya65)
    Date   : 15-September-2022

#>

function Get-VMCreationDate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Subscriptionid,
        [Parameter(Mandatory)]
        $location
    )

    $token = Get-AzAccessToken

    $authHeader = @{
        'Content-Type'  = 'application/json'
        'Authorization' = 'Bearer ' + $token.Token
    }
    
    $result = Invoke-RestMethod -Uri https://management.azure.com/subscriptions/$subid/providers/Microsoft.Compute/locations/$location/virtualMachines?api-version=2022-03-01 `
        -Method GET -Headers $authHeader

    $result.value | ForEach-Object {
        [psobject]@{
            VMName      = $_.name
            TimeCreated = $_.properties.timeCreated
        }
    } | Select-Object VMName, TimeCreated

}



<# You will get output similar to the one mentioned below: 

VMName TimeCreated
------ -----------
DC1    6/27/2022 10:02:18 AM
DC2    6/27/2022 9:02:24 AM

#>
