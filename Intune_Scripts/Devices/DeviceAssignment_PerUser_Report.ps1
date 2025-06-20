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

# Ensure Microsoft.Graph module is available
try {
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
        Write-Host "Microsoft.Graph module not found. Installing..."
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -ErrorAction Stop
    }
    Import-Module Microsoft.Graph -ErrorAction Stop
}
catch {
    Write-Error "❌ Failed to install or import Microsoft.Graph module: $_"
    exit 1
}

# Connect to Microsoft Graph
try {
    Connect-MgGraph -NoWelcome -ErrorAction Stop
}
catch {
    Write-Error "❌ Failed to connect to Microsoft Graph: $_"
    exit 1
}

# Load user list from CSV
try {
    if (-not (Test-Path $CSVUserFilePath)) {
        throw "CSV file not found at path: $CSVUserFilePath"
    }

    $userlist = Import-Csv -Path $CSVUserFilePath -ErrorAction Stop
    if ($userlist.Count -eq 0) {
        throw "CSV file is empty or improperly formatted."
    }
}
catch {
    Write-Error "❌ Error loading user list: $_"
    exit 1
}

$totalUsers = $userlist.Count
$deviceInfo = [System.Collections.Generic.List[Object]]@()

# Loop through each user and fetch device info
for ($i = 0; $i -lt $totalUsers; $i++) {
    $user = $userlist[$i]

    $percentComplete = [math]::Round((($i + 1) / $totalUsers) * 100, 2)
    Write-Progress -Activity "Processing user $($user.UPN)" `
                   -Status "$percentComplete% complete" `
                   -PercentComplete $percentComplete

    try {
        $devices = (Get-MgDeviceManagementManagedDevice -Filter "userPrincipalName eq '$($user.UPN)'").deviceName
    }
    catch {
        Write-Warning "⚠️ Failed to retrieve devices for user $($user.UPN): $_"
        $devices = @()
    }

    $psobject = [PSCustomObject]@{
        UPN        = $user.UPN
        DeviceName = if ($null -eq $devices -or $devices.Count -eq 0) {
            "No Device Assigned in Intune"
        } else {
            $devices -join ", "
        }
    }

    $deviceInfo.Add($psobject)
}

# Export results to CSV
try {
    $deviceInfo | Export-Csv -Path $ReportFilePath -NoTypeInformation -ErrorAction Stop
    Write-Host "`n✅ Report successfully exported to: $ReportFilePath"
}
catch {
    Write-Error "❌ Failed to export report: $_"
    exit 1
}
