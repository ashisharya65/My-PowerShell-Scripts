
<#
    .SYNOPSIS
        PowerShell script to delete the AVD's device identity from Intune, AzureAD, Azure VM & AVD portal.

    .DESCRIPTION
        This script will delete the AVD (which is Azure AD joined and Intune managed) from Intune,AzureAD, Azure VM & AVD portals.
        Here before running this script we have to make sure that the concerned device names are already added to the Text file.

    .NOTES
        Author : Ashish Arya
        Date   : 06-Sept-2023
#>

# You will be prompted to provide the below values.
Param(
    [Parameter(Mandatory)] $TenantID,
    [Parameter(Mandatory)] $Subscription,
    [Parameter(Mandatory)] $Subscriptionid,
    [Parameter(Mandatory)] $HPResourceGroup,
    [Parameter(Mandatory)] $AVDResourceGroup,
    [Parameter(Mandatory)] $HostPoolName,
    [Parameter(Mandatory)] $AzureADRegisteredAppId,     # The app id of your Azure Ad registered app
    [Parameter(Mandatory)] $AADRegisteredAppSecret,     # The secret of your Azure Ad registered app
    [Parameter(Mandatory)] $TextFilePath
)

# Importing the text file of devices having devicename header
$Devices = Get-Content -path $TextFilePath 

# Checking and Verifying if the latest version of Az, Microsoft.Graph & Az.DestopVirtualization powerShell modules are installed or not
$Modules = @(
    "Az",
    "Microsoft.Graph",
    "Az.DesktopVirtualization"
)
Foreach ($Module in $Modules) {
    $latest = Find-Module -Name $Module -AllVersions -AllowPrerelease | select-Object -First 1
    $current = Get-InstalledModule | Where-Object { $_.Name -eq $Module }
    If ($latest.version -gt $current.version) {
        Try {
            Update-Module -Name $Module -RequiredVersion $latest.version -AllowPrerelease -Force -ErrorAction 'Stop'
            Write-Host "$($Module) PowerShell module has been successfully updated to $($latest.Version) version."-ForegroundColor 'Green'
        }
        Catch {
            Write-Host "Unable to update the $($Module) PowerShell module to $($latest.version) version." -ForegroundColor 'Red'
        }
    }
    Elseif ($null -eq $current.version) {
        Try {
            Write-Host "The $($Module) PowerShell module is not installed. Hence, installing it..." -ForegroundColor "Yellow"
            Install-Module $Module -scope CurrentUser -force -ErrorAction 'Stop'
            Write-Host "The $($Module) PowerShell module with $($latest.version) version has been installed successfully on your machine."
        }
        Catch {
            Write-Host "Unable to install the $($Module) PowerShell module with $($latest.version) version." -ForegroundColor 'Red'
        }
    }
    Else {
        Write-Host "Your machine already has the latest version of $($Module) PowerShell module." -ForegroundColor 'Yellow'
    }
}

# Connecting to Azure
Connect-AzAccount -Tenant $TenantID -Subscription $Subscription  | Out-Null

# Connecting to Microsoft Graph
$AADRegisteredAppSecret = $AADRegisteredAppSecret | ConvertTo-SecureString -AsPlainText -Force
$ClientSecretCredential = New-Object -TypeName 'System.Management.Automation.PSCredential' -ArgumentList $AzureADRegisteredAppId, $AADRegisteredAppSecret
Connect-MgGraph -TenantId $TenantID -ClientSecretCredential $ClientSecretCredential | Out-Null

# Function to remove the AVD from the Azure VM portal
Function Remove-AVDFromAzureVMPortal {
    [cmdletbinding()]
    Param(
        $DeviceIdentity
    )
    
    $DeviceIdentity.StorageProfile.OsDisk.DeleteOption = 'Delete'
    $DeviceIdentity.StorageProfile.DataDisks | ForEach-Object { $_.DeleteOption = 'Delete' }
    $DeviceIdentity.NetworkProfile.NetworkInterfaces | ForEach-Object { $_.DeleteOption = 'Delete' }
    $DeviceIdentity | Update-AzVM | Out-Null

    Try {
        Remove-AzVm -ResourceGroupName $AVDResourceGroup -Name $DeviceIdentity.Name -ForceDeletion $true -Force -NoWait | Out-Null
        Write-Host "The device identity of $($DeviceIdentity.Name) AVD has been successfully deleted from Azure VM portal." -ForegroundColor 'Green'
    }
    Catch {
        $errormessage = "Unable to remove the $($DeviceIdentity.Name) AVD from Azure Virtual machines portal."
        Write-Error $errormessage
    }
}

# Looping through all devices to delete their identities
$Count = $null
Foreach ($Device in $Devices) {

    $Count += 1
    Write-Host "`n$($Count). For $($Device) device" -ForegroundColor 'DarkCyan'
    Write-Host "****************************************************************************************************" -ForegroundColor 'Cyan'

    # Shutting down the AVD if it is in running state
    $AVDPowerState = (Get-AzVm -ResourceGroupName $AVDResourceGroup -Name $Device -Status).statuses[1].DisplayStatus
    If ($AVDPowerState -eq "VM running") {
        Write-Host "The $($Device) AVD is still running. Hence shutting it down now." -ForegroundColor "Yellow"
        Try {
            Stop-AzVM -ResourceGroupName $AVDResourceGroup -Name $Device -ErrorAction 'Stop'
            Write-Host "$($Device) has been sucessfully stopped." -ForegroundColor 'Green'
        }
        Catch {
            $errormessage = "Unable to shutdown the $($Device) AVD."
            Write-Error $errormessage
        }
    }

    # Removing the device identiy from AVD hostpool portal
    $AVDPortalIdentity = Get-AzWvdSessionHost -ResourceGroupName $HPResourceGroup -HostPoolName $HostPoolName -Name $Device
    If ($null -eq $AVDPortalIdentity) {
        Write-Host "$($Device) AVD does not exist in the AVD portal." -ForegroundColor 'Yellow'
    }
    Else {
        Try {
            Remove-AzWVDSessionHost -ResourceGroupName $HPResourceGroup -HostpoolName $HostPoolName -Name $Device -ErrorAction 'Stop'
            Write-Host "The device identity of $($Device) AVD has been successfully deleted from the AVD host pool portal." -ForegroundColor 'Green'
        }
        Catch {
            $errormessage = "Unable to delete the $($Device) AVD's device identity from AVD portal."
            Write-Error $errormessage
        }
    }

    # Removing the AVD from the Azure Virtual Machine portal blade
    $AzureVMPortalIdentity = Get-AzVm -ResourceGroupName $AVDResourceGroup -Name $Device
    If ($null -eq $AzureVMPortalIdentity) {
        Write-Host "$($Device) AVD does not exist in the Azure VM portal." -ForegroundColor 'Yellow'
    }
    Else {
        Remove-AVDFromAzureVMPortal -DeviceIdentity $AzureVMPortalIdentity
    }

    # Removing the device entry from Intune portal
    $IntuneDeviceIdentity = Get-MgDeviceManagementManagedDevice -Filter "deviceName eq '$($Device)'"
    If ($null -eq $IntuneDeviceIdentity) {
        Write-Host "$($Device) AVD does not exist in the Intune portal." -ForegroundColor 'Yellow'
    }
    Else {
        Try {
            Remove-MgDeviceManagementManagedDevice -ManagedDeviceId $IntuneDeviceIdentity.Id
            Write-Host "The device identity of $($Device) AVD device has been successfully deleted from the Intune portal." -ForegroundColor 'Green'
        }
        Catch {
            $errormessage = "Unable to delete the Intune device identity."
            Write-Error $errormessage
        }
    }

    # Removing the device identity from Azure AD portal
    $AzureADDeviceIdentity = Get-MgDevice -Filter "DisplayName eq '$($Device)'"
    If ($null -eq $AzureADDeviceIdentity) {
        Write-Host "$($Device) AVD does not exist in the Intune portal." -ForegroundColor 'Yellow'
    }
    Else {
        Try {
            Remove-MgDevice -DeviceId $AzureADDeviceIdentity.id  
            Write-Host "The device identity of $($Device) AVD has been successfully deleted from the Azure AD portal." -ForegroundColor 'Green'
        }
        Catch {
            $errormessage = "Unable to delete the device identity from Azure AD portal."
            Write-Error $errormessage
        }
    }
}