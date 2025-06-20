<#
.SYNOPSIS
Generates a report of Intune-managed devices assigned to users listed in a CSV file.

.DESCRIPTION
This script connects to Microsoft Graph using the Microsoft Graph PowerShell SDK, reads a list of users from a CSV file,
retrieves the devices assigned to each user in Microsoft Intune, and displays progress using Write-Progress.
The final output is exported to a CSV file.

.PARAMETER CSVUserFilePath
The full path to the CSV file containing a list of users. The CSV must include a column named 'UPN'.

.PARAMETER ReportFilePath
The full path where the output CSV report will be saved.

.INPUTS
CSV file with a column named 'UPN' containing user principal names.

.OUTPUTS
A CSV file containing each user's UPN and the names of their assigned devices (if any).

.EXAMPLE
.\DeviceAssignment_PerUser_Report.ps1 -CSVUserFilePath "C:\Device_Owners_Check.csv" -ReportFilePath "C:\Device_Assignment_PerUser_Report.csv"

.NOTES
Author: Ashish Arya
Date: 20 June 2025
Requires: Microsoft.Graph PowerShell SDK
#>

[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$CSVUserFilePath,

    [Parameter(Mandatory = $true)]
    [string]$ReportFilePath
)

# Check if Microsoft.Graph module is installed
if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
    Write-Host "Microsoft.Graph module is not installed. Installing now..."
    Install-Module Microsoft.Graph -Scope CurrentUser -Force
}

# Import the module
Import-Module Microsoft.Graph

# Connect to Microsoft Graph
Connect-MgGraph -NoWelcome

# Load user list from CSV
$userlist = Import-Csv -Path $CSVUserFilePath
$totalUsers = $userlist.Count
$deviceInfo = [System.Collections.Generic.List[Object]]@()

# Loop through each user and fetch device info
for ($i = 0; $i -lt $totalUsers; $i++) {
    $user = $userlist[$i]

    # Calculate and show progress
    $percentComplete = [math]::Round((($i + 1) / $totalUsers) * 100, 2)
    Write-Progress -Activity "Processing user $($user.UPN)" `
                   -Status "$percentComplete% complete" `
                   -PercentComplete $percentComplete

    # Get device names assigned to the user
    $devices = (Get-MgDeviceManagementManagedDevice -Filter "userPrincipalName eq '$($user.UPN)'").deviceName

    # Create output object
    $psobject = [PSCustomObject]@{
        UPN        = $user.UPN
        DeviceName = if ($null -eq $devices) {
            "No Device Assigned in Intune"
        } else {
            $devices -join ", "
        }
    }

    $deviceInfo.Add($psobject)
}

# Export results to CSV
$deviceInfo | Export-Csv -Path $ReportFilePath -NoTypeInformation
