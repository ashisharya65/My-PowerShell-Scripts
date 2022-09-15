
<#
    .SYNOPSIS
    Get creation date of Virtual Machines in a resource group of your Azure subscription.

    .DESCRIPTION
    Using this script you can get the creation date of all the VMS with in a resrouce group of your Azure subscription.

    .EXAMPLE
    .\Get-VMCreationDate -Subscriptionid <Subscription id> -ResourceGrouplocation <location of Resource group>
    
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
        $ResourceGrouplocation
    )

    $token = Get-AzAccessToken

    $authHeader = @{
        'Content-Type'  = 'application/json'
        'Authorization' = 'Bearer ' + $token.Token
    }
    
    $resources = Invoke-RestMethod -Uri https://management.azure.com/subscriptions/$subid/providers/Microsoft.Compute/locations/$location/virtualMachines?api-version=2022-03-01 `
        -Method GET -Headers $authHeader

    $resources.value | ForEach-Object {
        [psobject]@{
            VMName      = $_.name
            TimeCreated = $_.properties.timeCreated
        }
    } | Select-Object VMName, TimeCreated

}

