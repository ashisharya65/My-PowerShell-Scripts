
<#
.SYNOPSIS
    Powershell script to sign out user's active session from the AVDs.
.DESCRIPTION
    This script displays the user's active sessions across all AVD host pools 
    and prompts the user to enter the specific AVD for clearing the session.
.NOTES
    Author : Ashish Arya
    Date  : 23 Jan 2024
#>

# declaring variables
[CmdletBinding()]
param(
    [Parameter(Mandatory, HelpMessage = "Enter the user's UPN")] $userUPN,
    $username = [cultureinfo]::GetCultureInfo("en-US").TextInfo.ToTitleCase($userUPN.split(".")[0]),
    $subscription = $env:AZURE_SUBSCRIPTION,
    $tenant = $env:AZURE_TENANT_ID
)

# Verifying if AZ and AVD powershell modules are installed or not
@("Az", "Az.DesktopVirtualization") | ForEach-Object {
    If ($null -eq $(Get-InstalledModule -Name $_)) {
        Write-Host "$_ powershell module is not installed on your machine. Hence installing it."
        Install-Module $_ -Scope 'CurrentUser' -Force
    }
}

# Connecting to Azure Subscription
Start-Sleep 1
Write-host "`nConnecting to Azure..." -ForegroundColor "DarkYellow"
Start-Sleep 1
Try {
    connect-Azaccount -Tenant $tenant -Subscription $subscription -ea 'stop' | Out-Null
    Start-Sleep 2
    Write-Host "You were successfully connected to your Azure account." -f 'Green'
}
Catch {
    $errormessage = $_.Exception.Message
    Write-Error $errormessage
}

# Getting the host pools
$hostpools = Get-AzWvdHostPool | Foreach-Object {
    [PSCustomObject]@{
        hostpool      = $_.name
        resourcegroup = ($_.id -split "/")[4]
    }
}

# Looping through all hostpools to get the Active sessions for the user
$allsessions = @()
Foreach ($hp in $hostpools) {
    $sessions = Get-AzWvdUserSession -HostPoolName $hp.hostpool -ResourceGroupName $hp.resourcegroup
    Foreach ($session in $sessions) {
        If ($session.userPrincipalName -eq $userUPN) {
            $avdname = $session.name.split("/")[1]
            $psobject = [PSCustomObject]@{
                name          = $avdname
                user          = $Username
                sessionid     = $session.name.split("/")[-1]
                hostpool      = $hp.hostpool
                resourcegroup = $hp.resourcegroup
            }

            $allsessions += $psobject
        }
    }
}

Write-Host "`n###################################################################" -ForegroundColor 'Green'
Write-Host "# $username's active AVD sessions #" -ForegroundColor "Green"
Write-Host "###################################################################`n" -ForegroundColor "Green"

# Displaying all the active user sessions
$count = 0
if ($allsessions.Count -eq 0) {
    Write-Host ("There are no active user sessions.Hence, exiting the script...`n") -ForegroundColor "DarkYellow"
    Start-Sleep 1
    Exit
}
else {
    For ($i = 0; $i -lt $allsessions.count; $i++) {
        $Count += 1
        If ($allsessions.count -eq 1) {
            Write-Host ("$($allsessions[$i].name)") -ForegroundColor "Cyan"
        }
        ElseIf ($allsessions.count -gt 1) {
            Write-Host ("$count. $($allsessions[$i].name)") -ForegroundColor "Cyan"
        }
    }
}

# Prompting the user to choice if he/she wants his/her active session removed from the concerned AVD
Write-Host
Foreach ($s in $allsessions) {
    $choice = Read-Host -prompt "Do you want to clear user's session from one of the AVDs - (y/n)"
    Write-Host
    switch ($choice) {
        "y" {
            $AVD = Read-Host -Prompt "Enter the name of the AVD from which you want to remove the user's session"
            Remove-AzWvdUserSession -HostPoolName "$($s.hostpool)" -ResourceGroupName "$($s.resourcegroup)" -SessionHostName "$AVD" -Id "$($s.sessionid)" -Force
            Write-Host "`n$username's session was successfully removed from the AVD $($AVD).`n" -ForegroundColor 'Green'
        }
        "n" {
            Write-Host "You have selected 'n' so exiting the script..`n" -ForegroundColor 'DarkYellow'
            Exit
        }
    }
}

