<#
    .SYNOPSIS
    Powershell script to log off all the active sessions for users.
        
    .DESCRIPTION
    This script takes an array of users' UPNs and forcefully logs off their active sessions on all the AVDs from all the AVD host pools.
    This script requires a UPNList.txt file containing the users' User Principal Names (UPNs) to be located in the same directory as the script.

    .PARAMETER userUPN
    The user's userpricipalname.
    
    .PARAMETER subscription
    The Azure subcription name.
    
    .PARMETER tenantid
    The Azure tenant id.
    
    .INPUTS
    Array of users UPN.
    
    .OUTPUTS
    None. This script does not generate any specific output.
    
    .EXAMPLE
    .\LogOffSelectedUsersActiveSessions.ps1
    
    .NOTES
    Author : Ashish Arya
    Date   : 09 Feb 2024
#>
Function Handle-Error {
    Param([String]$ErrorMessage)
    Write-Host $ErrorMessage -ForegroundColor 'Red'
}

function Invoke-LogOff {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, HelpMessage = "Enter the user UPN")][string]$userUPN,
        [string]$username = [cultureinfo]::GetCultureInfo("en-US").TextInfo.ToTitleCase($userUPN.split(".")[0]),
        [string]$subscription = $env:AZURE_SUBSCRIPTION,
        [string]$tenantid = $env:AZURE_TENANT_ID
    )

    # Verifying if AZ and AVD PowerShell modules are installed or not
    @("Az", "Az.DesktopVirtualization") | ForEach-Object {
        If ($null -eq $(Get-InstalledModule -Name $_)) {
            Write-Host "$_ PowerShell module is not installed on your machine. Hence installing it."
            Install-Module $_ -Scope 'CurrentUser' -Force
        }
    }

    # Check if already connected to Azure
    $azureContext = Get-AzContext -ErrorAction SilentlyContinue
    # Connecting to Azure Subscription if not already connected
    if ($null -eq $azureContext) {
        Write-Host "`nConnecting to Azure..." -ForegroundColor "DarkYellow"
        Try {
            Connect-AzAccount -Tenant $tenantid -Subscription $subscription -ErrorAction Stop | Out-Null
            Write-Host "Successfully connected to your Azure tenant." -f 'DarkGreen'
        }
        Catch {
            Handle-Error -Errormessage $_.Exception.Message
            Break
        }
    }
    else {
        Write-Host "`nYou are already connected to your Azure tenant." -f "DarkGreen"
    }

    # Getting the host pools
    try {
        $hostPools = Get-AzWvdHostPool | ForEach-Object {
            [PSCustomObject]@{
                HostPool      = $_.Name
                ResourceGroup = ($_.Id -split "/")[4]
            }
        }
    }
    catch {
        Handle-Error -ErrorMessage $_.Exception.Message
    }

    # Looping through all host pools to get the Active sessions for the user
    $allSessions = foreach ($hp in $hostPools) {
        try {
            Get-AzWvdUserSession -HostPoolName $hp.HostPool -ResourceGroupName $hp.ResourceGroup -ea Stop `| 
            Where-Object { $_.UserPrincipalName -eq $userUPN } | ForEach-Object {
                [PSCustomObject]@{
                    Name          = $_.Name.Split("/")[1]
                    User          = $username
                    SessionId     = $_.Name.Split("/")[-1]
                    HostPool      = $hp.HostPool
                    ResourceGroup = $hp.ResourceGroup
                }
            }
        }
        catch {
            Handle-Error -ErrorMessage $_.Exception.Message
        }
    }

    # Displaying all the active user sessions
    if ($allSessions.Count -eq 0) {
        Write-Host ("`nThere are no active sessions. Hence, exiting the script...`n") -ForegroundColor 'DarkYellow'
        return
    }
    else {
        $count = 0
        Write-Host "`nBelow are the active AVD sessions with $username's name."
        foreach ($session in $allSessions) {
            $count++
            Write-Host "$count. $($session.Name)" -ForegroundColor 'Cyan'
        }

        # Clearing all the sessions forcefully
        try {
            $allSessions | ForEach-Object {
                Remove-AzWvdUserSession -HostPoolName $_.HostPool -ResourceGroupName $_.ResourceGroup `
                    -SessionHostName $_.Name -Id $_.SessionId -Force
            }
            Write-Host "`nAll active sessions of $username has been successfully cleared.`n" -ForegroundColor "DarkGreen"
        }
        catch {
            Handle-Error -ErrorMessage $_.Exception.Message
        }
    }
}

$UPNList = Get-Content -path "$PSScriptRoot\UPNList.txt"
Foreach ($UPN in $UPNList) {
    Invoke-LogOff -userUPN $UPN
}
