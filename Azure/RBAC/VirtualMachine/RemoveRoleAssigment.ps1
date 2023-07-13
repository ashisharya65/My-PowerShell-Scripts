<#
   .SYNOPSIS
    PowerShell script to remove a role assignment from an Azure VM
    
    .DESCRIPTION
    This script will remove the user role assignment from an Azure VM.
   
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

Try { 
    Set-AzContext -Subscription $SubscriptionID | Out-Null
}
Catch {
    Write-Error $_.Exception.Message
    Break;
}

# Collating all the details
$RemoveAzRoleAssigment = @{
    "SignInName"         = $UserUPN
    "RoleDefinitionName" = $Role
    "Scope"              = "/subscriptions/$($SubscriptionID)/resourceGroups/$($ResourceGroupName)/providers/Microsoft.Compute/virtualMachines/$($VMName)"
}

# Removing the role assignment
Write-Host "`nRemoving the role assignment.." -ForegroundColor 'DarkCyan'
Try {
    Remove-AzRoleAssignment @RemoveAzRoleAssigment | Out-Null
    Write-Host "$($Role) Azure role assignment was removed on $($VMName) VM for $($UserUPN.Split("@")[0]) user.`n" -ForegroundColor 'Green'
}
Catch {
    Write-Error $_.Exception.Message
    Break;
}


########################################################################################################################################################################
################################################################################ END ###################################################################################
########################################################################################################################################################################
