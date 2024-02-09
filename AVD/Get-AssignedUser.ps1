
<#
    .SYNOPSIS
    Powershell script to get the assigned user of the AVD.
    
    .DESCRIPTION
    This script displays the Assigned user of the AVD.

    .PARAMETER avdname
    The name of the AVD.
    
    .PARAMETER subcription
    The name of your Azure subscription.
    
    .PARAMETER tenantid
    Your tenant id.
    
    .INPUTS
    Prompts for AVD name, subscription name & tenantid
    
    .OUTPUTS
    System.String. You will be getting the Assigned user name for the input AVD.
    
    .EXAMPLE
    .\Get-AVDAssignedUser 
    
    .NOTES
    Author : Ashish Arya
    Date   : 06-Feb-2024
#>

# Function to handle errors
function Handle-Error {
    Param([string]$ErrorMessage)
    Write-Host $ErrorMessage -ForegroundColor "Red"
}

# Function to get the Assigned user
Function Get-AVDAssignedUser {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, HelpMessage = "Enter the AVD name")] $avdname,
         [Parameter(Mandatory, HelpMessage = "Enter the subscription name")] $subscription,
         [Parameter(Mandatory, HelpMessage = "Enter the tenant id")] $tenantid
    )

       
    # Verifying if AZ and AVD PowerShell modules are installed or not
    @("Az", "Az.DesktopVirtualization") | ForEach-Object {
        If ($null -eq $(Get-InstalledModule -Name $_)) {
            Write-Host "$_ PowerShell module is not installed on your machine. Hence installing it."
            Install-Module $_ -Scope 'CurrentUser' -Force
        }
    }

    # Connecting to Azure Subscription
    Write-host "`nConnecting to Azure..." -ForegroundColor "DarkYellow"
    Try {
        Connect-Azaccount -Tenant $tenantid -Subscription $subscription -ea 'stop' | Out-Null
        Write-Host "You were successfully connected to your Azure Tenant." -f 'Green'
    }
    Catch {
        Handle-Error -ErrorMessage $_.Exception.Message
        Break
    }
    
    # Getting the host pools
    try {
        $hostpools = Get-AzWvdHostPool -ea Stop | Foreach-Object {
            [PSCustomObject]@{
                    hostpool      = $_.name
                    resourcegroup = ($_.id -split "/")[4]
            }
        }
    }
    catch{
        Handle-Error -ErrorMessage $_.Exception.Message
    }
    
    # Looping through all the host pools to find the right AVD and print the Assigned user name
    foreach ($Hp in $hostpools) {
        $AssignedUser = (Get-AzWVDSessionHost -HostPoolName $Hp.hostpool -ResourceGroupName $Hp.resourcegroup -sessionhostname $avdname -ea 'SilentlyContinue').AssignedUser
        If (!([String]::IsnullorEmpty($AssignedUser))) {
            Write-Host "`n##############################################################" -f "Cyan"
            Write-Host "Assigned User: $($AssignedUser)" -f "Cyan"
            Write-Host "##############################################################`n" -f "Cyan"
            Break
        }
    }
}

# AVD assigned user function call
Get-AVDAssignedUser
