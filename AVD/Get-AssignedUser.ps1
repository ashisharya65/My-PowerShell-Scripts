
<#
    .SYNOPSIS
    Powershell script to get the assigned user of the AVD.
    
    .DESCRIPTION
    This script displays the Assigned user of the AVD.
    
    .EXAMPLE
    .\Get-AVDAssignedUser -AVDName <AVDName>
    
    .NOTES
    Author : Ashish Arya
    Date   : 06-Feb-2024
#>

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
        $errormessage = $_.Exception.Message
        Write-Error $errormessage
        Break
    }
    
    # Getting the host pools
    $hostpools = Get-AzWvdHostPool | Foreach-Object {
        [PSCustomObject]@{
            hostpool      = $_.name
            resourcegroup = ($_.id -split "/")[4]
        }
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
