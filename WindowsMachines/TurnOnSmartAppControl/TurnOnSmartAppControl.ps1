
<#
    .SYNOPSIS
    PowerShell script to turn on the Smart App control in Windows devices.

    .DESCRIPTION
    This script will force enable the Smart app control setting in Windows device.

    .NOTES
    Author : Ashish Arya
    Date   : 05-June-2023
#>

$Reglocation = "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy"

If ((Get-ItemProperty $Reglocation).VerifiedAndReputablePolicyState -ne 1) {
    Try {
        Set-ItemProperty $Reglocation -Name 'VerifiedAndReputablePolicyState' -Value 1 -Force -ErrorAction 'Stop'
        Write-Host "Turning on the Smart app control" -f 'Green'
    }
    Catch {
        Write-Error -Exception $_.Exception.Message
    }
}
Else {
    Write-Host "The Smart app control setting is already turned on" -f 'Cyan'
}
