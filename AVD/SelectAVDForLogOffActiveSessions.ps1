<#
    .SYNOPSIS
    Powershell script to log off the user's active session from the AVDs.
        
    .DESCRIPTION
    This script displays the user's active sessions on the Avds from all the AVD host pools 
    and prompts the user to select the specific AVD and logging off that session.

    .PARAMETER userUPN
    The user's userpricipalname.
    
    .PARAMETER subscription
    The Azure subcription name.
    
    .PARMETER tenantid
    The Azure tenant id.
    
    .INPUTS
    The program inputs for user's UPN, subcription and tenant id of your Azure tenant.
    
    .OUTPUTS
    None    
    
    .EXAMPLE
    .\SelectAVDForLogOffActiveSession.ps1
    
    .NOTES
    Author : Ashish Arya
    Date   : 23 Jan 2024
#>

function Handle-Error {
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
        Write-host "`nConnecting to Azure..." -ForegroundColor "DarkYellow"
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
        Write-host "`nYou are already connected to your Azure tenant." -f "DarkGreen"
    }


    # Getting the host pools
    $hostPools = Get-AzWvdHostPool | ForEach-Object {
        [PSCustomObject]@{
            HostPool      = $_.Name
            ResourceGroup = ($_.Id -split "/")[4]
        }
    }

    # Looping through all host pools to get the Active sessions for the user
    $allSessions = foreach ($hp in $hostPools) {
        Get-AzWvdUserSession -HostPoolName $hp.HostPool -ResourceGroupName $hp.ResourceGroup | Where-Object { $_.UserPrincipalName -eq $userUPN } | ForEach-Object {
            [PSCustomObject]@{
                Name          = $_.Name.Split("/")[1]
                User          = $username
                SessionId     = $_.Name.Split("/")[-1]
                HostPool      = $hp.HostPool
                ResourceGroup = $hp.ResourceGroup
            }
        }
    }

    # Displaying all the active user sessions
    if ($allSessions.Count -eq 0) {
        Write-Host ("`nThere are no active sessions of $username. Hence, exiting the script.`n") -ForegroundColor 'DarkYellow'
        return
    }
    elseif ($allSessions.Count -eq 1) {
        Write-Host "`n##############################################################" -ForegroundColor 'Green'
        Write-Host "`t`t$username's active AVD sessions" -ForegroundColor 'Green'
        Write-Host "##############################################################`n" -ForegroundColor 'Green'    
        Write-Host (" - $($AllSessions.Name)`n") -ForegroundColor 'DarkYellow'
    }
    else {
        $count = 0
        Write-Host "`n##############################################################" -ForegroundColor 'Green'
        Write-Host "`t`t$username's active AVD sessions" -ForegroundColor 'Green'
        Write-Host "##############################################################`n" -ForegroundColor 'Green'    
        foreach ($session in $allSessions) {
            $count++
            Write-Host "$count. $($session.Name)" -ForegroundColor 'Cyan'
        }
    }

    # Prompting the user to choose if they want their active session removed from the concerned AVD
    Write-Host
    foreach ($session in $allSessions) {
        $choice = Read-Host -Prompt "Do you want to clear user's session from $($session.Name) AVD - (y/n)"
        Write-Host
        switch ($choice) {
            "y" {
                $AVD = Read-Host -Prompt "Enter the name of the AVD from which you want to remove the user's session"
                Remove-AzWvdUserSession -HostPoolName $session.HostPool -ResourceGroupName $session.ResourceGroup -SessionHostName $AVD -Id $session.SessionId -Force
                Write-Host "`n$username's session was successfully removed from the AVD $($AVD).`n" -ForegroundColor 'Green'
            }
            "n" {
                Write-Host "You have selected 'n' so exiting the script..`n" -ForegroundColor 'DarkYellow'
                return
            }
        }
    }
}

Invoke-LogOff
