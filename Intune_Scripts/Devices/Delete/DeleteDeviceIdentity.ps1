<#
    .SYNOPSIS
        PowerShell script to delete the device identity from Intune and Azure AD.

    .DESCRIPTION
        This script will delete the device identity from both Intune and Azure AD using the csv file which has the serial numbers of all the concerned devices.

    .NOTES
        Author : Ashish Arya
        Date   : 01-Aug-2023
#>

Param(
    $ErrorActionPreference = 'Stop'
)

# Checking and Verifying if the latest Microsoft.Graph Module is installed or not
$latest = Find-Module -Name Microsoft.Graph -AllVersions -AllowPrerelease | select-Object -First 1
$current = Get-InstalledModule | Where-Object { $_.Name -eq "Microsoft.Graph" }
If ($latest.version -gt $current.version) {
    Try {
        Update-Module -Name Microsoft.Graph -RequiredVersion $latest.version -AllowPrerelease
        Write-Host "Microsoft Graph PowerShell module updated successfully to" $latest.Version -ForegroundColor Green
    }
    Catch {
        Write-Host "Unable to update Microsoft Graph PowerShell module" -ForegroundColor Red
    }
}
Elseif ($null -eq $current.version) {
    Try {
        Write-Host "The Microsoft Graph PowerShell module is not installed. Hence, installing it..." -ForegroundColor "Yellow"
        Install-Module Microsoft.Graph -scope CurrentUser -force
    }
    Catch {
        Write-Host "Unable to install the Microsoft Graph PowerShell module"
    }

}
Else {
    Write-Host "Latest version of Microsoft Graph is not newer than the current" -ForegroundColor 'Yellow'
}

# Connecting to Microsoft Graph
Connect-MgGraph -Scope "DeviceManagementServiceConfig.ReadWrite.All,DeviceManagementManagedDevices.ReadWrite.All,Device.ReadWrite.All,Directory.ReadWrite.All"

# Importing the csv file of devices having SerialNumber header
$CSVFilePath = "$($PSScriptRoot)\" + "$($myInvocation.myCommand.name.split('.')[0])" + ".csv"
$Devices = Import-Csv -path $CSVFilePath

Foreach($Device in $Devices){

    # Removing the Intune Windows device entry
    $IntuneDeviceIdentity = Get-MgDeviceManagementManagedDevice -Filter "SerialNumber eq '$($Device.SerialNumber)'"
    $DeviceName = $IntuneDeviceIdentity.DeviceName
    Try{
        Remove-MgDeviceManagementManagedDevice -ManagedDeviceId $IntuneDeviceIdentity.Id 
        Write-Host "The Intune identity of $($DeviceName) device has been successfully deleted." -ForegroundColor 'Green'
    }
    Catch{
        Write-Error $_.Exception.Message
    }

    # Removing the windows autopilot enrollment identity of Intune device
    $WinAutoptEnrmtDeviceIdentity = Get-MgDeviceManagementWindowsAutopilotDeviceIdentity | Where-Object {$_.SerialNumber -eq $Device.SerialNumber}
    Try{
        Remove-MgDeviceManagementWindowsAutopilotDeviceIdentity -WindowsAutopilotDeviceIdentityId $WinAutoptEnrmtDeviceIdentity.Id 
        Write-Host "The Windows autopilot identity of $($DeviceName) device with Serial Number $($Device.SerialNumber) has been successfully deleted." -ForegroundColor 'Green'
    }
    Catch{
        Write-Error $_.Exception.Message
    }

    # Removing the Azure AD Identity
    $AzureADDeviceIdentity = Get-MgDevice -Filter "DisplayName eq '$($DeviceName)"
    Try{
        Remove-MgDevice -DeviceId $AzureADDeviceIdentity.id  
        Write-Host "The Azure AD identity of $($DeviceName) has been successfully deleted." -ForegroundColor 'Green'
    }
    Catch{
        Write-Error $_.Exception.Message
    }

}
