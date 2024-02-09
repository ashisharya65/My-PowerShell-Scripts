
<#
    .SYNOPSIS
        Powershell script to log off the user's active session from the AVDs.
        
    .DESCRIPTION
        This script displays the user's active sessions across all AVD host pools 
        and prompts the user to enter the specific AVD for clearing the session.

    .PARAMETER userUPN
    The user's userpricipalname.
    
    .PARAMETER subscription
    The Azure subcription name.
    
    .PARMETER tenantid
    The Azure tenant id.
    
    .INPUTS
    The program inputs for user's UPN, subcription and tenant id of your Azure tenant.
    
    .OUTPUTS
    System.Collections.Generic.List. The program outputs the list of AVDs where the user session is currently active.
    
    .EXAMPLE
    .\LogOffUsersessionfromSelectedAVDs.ps1
    
    .NOTES
    Author : Ashish Arya
    Date  : 23 Jan 2024
#>

# declaring variables
[CmdletBinding()]
param(
    [Parameter(Mandatory, HelpMessage = "Enter the user's UPN")] $userUPN,
    $username = [cultureinfo]::GetCultureInfo("en-US").TextInfo.ToTitleCase($userUPN.split(".")[0]),
    [Parameter(Mandatory, HelpMessage = "Enter the subscription name")] $subscription,
   [Parameter(Mandatory, HelpMessage = "Enter the tenant id")] $tenantid
)

# Function to handle error
function Handle-Error {
    param([string]$Errormessage)
    Write-Host $Errormessage -ForegroundColor "Red"

}

# Verifying if AZ and AVD PowerShell modules are installed or not
@("Az", "Az.DesktopVirtualization") | ForEach-Object {
    If ($null -eq $(Get-InstalledModule -Name $_)) {
        Write-Host "$_ PowerShell module is not installed on your machine. Hence installing it."
        Install-Module $_ -Scope 'CurrentUser' -Force
    }
}

# Connecting to Azure Subscription
if(!([string]::IsNullOrEmpty($Connected))){
        Write-host "`nYou are already connected to your Azure tenant." -f "DarkGreen"
}
else{
     Write-host "`nConnecting to Azure..." -ForegroundColor "DarkYellow"
     Try {
         $Connected = connect-Azaccount -Tenant $tenantid -Subscription $subscription -ea 'stop'# | Out-Null
         Write-Host "Successfully connected to your Azure tenant." -f 'DarkGreen'
     }
     Catch {
         Handle-Error -Errormessage $_.Exception.Message
         Break
     }
}

# Getting the host pools
try {
    $hostpools = Get-AzWvdHostPool -Ea Stop | Foreach-Object {
        [PSCustomObject]@{
            hostpool      = $_.name
            resourcegroup = ($_.id -split "/")[4]
        }
    }
}
Catch {
    Handle-Error -Errormessage $_.Exception.Message
}


# Looping through all hostpools to get the Active sessions for the user
$allsessions = [System.Collections.Generic.List[Object]]@()
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

            $allsessions.Add($psobject) | Out-Null
        }
    }
}

Write-Host "`n###################################################################" -ForegroundColor 'Green'
Write-Host "# $username's active AVD sessions #" -ForegroundColor "Green"
Write-Host "###################################################################`n" -ForegroundColor "Green"

# Displaying all the active user sessions
$count = 0
if ($allsessions.Count -eq 0) {
    Write-Host ("There are no active user sessions. Hence, exiting the script...`n") -ForegroundColor "DarkYellow"
    Exit
}
else {
    For ($i = 0; $i -lt $allsessions.count; $i++) {
        $Count += 1
        if ($allsessions.count -eq 1) {
            Write-Host ("$($allsessions[$i].name)") -ForegroundColor "Cyan"
        }
        elseIf ($allsessions.count -gt 1) {
            Write-Host ("$count. $($allsessions[$i].name)") -ForegroundColor "Cyan"
        }
    }
}

# Prompting the user to choose if he/she wants his/her active session removed from the concerned AVD
Write-Host
Foreach ($s in $allsessions) {
    $choice = Read-Host -prompt "Do you want to clear the user's session from one of the AVDs - (y/n)"
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

