<#
.SYNOPSIS
    This script enables the setting to notify when a restart is required to finish updating.

.DESCRIPTION
    This function updates a specific registry key to enable restart notifications
    after Windows updates. It sets the 'RestartNotificationsAllowed2' property
    to '1' in the 'HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings' registry.

.PARAMETER None
    This script does not take any parameters.

.EXAMPLE
    PS C:\> .\Enable-UpdatesRestartAlert.ps1
    This command runs the script to enable restart notifications.

.NOTES
    Author : [Ashish Arya]
    Date   : [07-01-2025]
    Version: 1.0
#>
function Enable-UpdatesRestartAlert {
    param(
        $regkey = "HKLM:\SOFTWARE\Microsoft\WindowsUpdate\UX\Settings",
        $regkeyprop = "RestartNotificationsAllowed2"
    )
    Try {
        $splat = @{
            Path        = $regkey
            Name        = $regkeyprop
            Value       = 1
            Force       = $true
            ErrorAction = "Stop"
        }
        Set-ItemProperty @splat
    }
    catch {
        $err = $_.Exception.Message
        Write-Host "ERROR: Unable to update the registry key. $err."
    }
}

Enable-UpdatesRestartAlert
