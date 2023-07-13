<#
   .SYNOPSIS
    PowerShell script to Add a role assignment to an Azure VM
    
    .DESCRIPTION
    This script will add the user role assignment to an Azure VM.
   
    .NOTES
    Author : Ashish Arya 
    Date   : 14-July-2023
#>

# Variable declaration and initialization
param (
    [Parameter(Mandatory)] $UserUPN,
    [Parameter(Mandatory)] $VMName,
    [Parameter(Mandatory)] $SubscriptionID,
    [Parameter(Mandatory)] $ResourceGroupName,
    [Parameter(Mandatory)] $Role,
    $erroractionpreference = "Stop"
)

# Install the Az module if it is not installed
$AzModule = Get-InstalledModule | Where-Object { $_.Name -like "Az*" }
If ($null -eq $AzModule) {
    Write-Host "Az module is not installed on the machine. Hence installing it.." -ForegroundColor 'Yellow'
    Try {
        Install-Module Az -Scope CurrentUser -Force
    }
    Catch {
        Write-Error $_.Exception.Message
    }
}

# Connecting to the Azure Account
Connect-AzAccount | Out-Null

# Setting the AzContext to your susbcription
Try { 
    Set-AzContext -Subscription $SubscriptionID | Out-Null
}
Catch {
    Write-Error $_.Exception.Message
    Break;
}

# Collating all the details
$AddAzRoleAssigment = @{
    "SignInName"         = $UserUPN
    "RoleDefinitionName" = $Role
    "Scope"              = "/subscriptions/$($SubscriptionID)/resourceGroups/$($ResourceGroupName)/providers/Microsoft.Compute/virtualMachines/$($VMName)"
}

# Creating the role assignment
Write-Host "`nCreating the role assignment.." -ForegroundColor 'DarkCyan'
Try {
    New-AzRoleAssignment @AddAzRoleAssigment | Out-Null
    Write-Host "$($Role) Azure role assignment was created on $($VMName) VM for $($UserUPN.Split("@")[0]) user.`n" -ForegroundColor 'Green'
}
Catch {
    Write-Error $_.Exception.Message
    Break;
}


########################################################################################################################################################################
################################################################################ END ###################################################################################
########################################################################################################################################################################
