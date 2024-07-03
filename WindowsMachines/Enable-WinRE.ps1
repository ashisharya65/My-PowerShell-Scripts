
<#
.SYNOPSIS
    Enables Windows Recovery Environment (WinRE) if it is not already enabled.

.DESCRIPTION
    This script checks the current status of Windows Recovery Environment (WinRE) on the specified device.
    If WinRE is not enabled, it enables it. The script requires administrator privileges to execute.

.PARAMETER devicename
    The name of the device where WinRE status is checked and enabled if necessary.
    Defaults to the current computer name.

.EXAMPLE
    PS C:\> Enable-WinRE
    Checks and enables WinRE on the current computer if not already enabled.

.EXAMPLE
    PS C:\> Enable-WinRE -devicename "MyComputer"
    Checks and enables WinRE on the device named "MyComputer" if not already enabled.

.NOTES
    Author: Ashish Arya
    Date: 03-July-2024
    Requires: PowerShell 5.1 or later, administrator privileges
#>

# Function to enable Windows Recovery Environment (WinRE)
Function Enable-WinRE {
    param(
        # Accept an optional parameter for the device name, default to the current computer name
        $devicename = $env:Computername
    )

    Try {
        # Get the current status of WinRE by running the reagentc command and parsing the output
        $WinRE_Status = (reagentc /info | Select-String "Windows RE status:").Tostring().split(":")[1].trim()
        
        # Check if WinRE is not enabled
        if ($WinRE_Status -ne "Enabled") {
            # Output a message indicating that WinRE is being enabled
            Write-Output "WinRE is not enabled on the $devicename. Hence enabling it."
            # Enable WinRE
            reagentc /enable
        }
        Else {
            # Output a message indicating that WinRE is already enabled
            Write-Output "WinRE is already enabled on the $devicename."
        }
    }
    Catch {
        # Catch any errors that occur and output the error message
        $errmessage = $_.Exception.Message
        Write-Error $errmessage
    }
}

# Get the current Windows identity
$CurrentWindowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()

# Casting the WindowsIdentity object to WindowsPrincipalObject
$CurrentWindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($CurrentWindowsIdentity)

# Check if the current user has administrator privileges
if ($CurrentWindowsPrincipal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    # The user is an administrator, call the Enable-WinRE function
    Enable-WinRE
}
else {
    # The user is not an administrator, output a message indicating that admin privileges are required
    Write-Output "You have to launch PowerShell as an administrator to execute this script."
}
