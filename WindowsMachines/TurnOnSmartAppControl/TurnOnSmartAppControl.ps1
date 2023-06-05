
<#
    .SYNOPSIS
    PowerShell script to turn on the Smart App control in Windows devices.

    .DESCRIPTION
    This script will forcefully turned on the Smart app control setting in Windows devices.

    .NOTES
    Author : Ashish Arya
    Date   : 05-June-2023
#>

$Reglocation = "HKLM:\SYSTEM\CurrentControlSet\Control\CI\Policy"

If ((Get-ItemProperty $Reglocation).VerifiedAndReputablePolicyState -ne 1){
    Set-ItemProperty $Reglocation -Name VerifiedAndReputablePolicyState -Value 1 -force
Write-Host "Smart App control has been turned on." -f 'Green'
}Else{
    Write-Host "The Smart app control is already in turned on state." -f 'Cyan'
}
