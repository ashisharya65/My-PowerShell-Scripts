
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
    [Parameter(Mandatory)] $TextFilePath                # Path of the text file which stores the device names
)

# Importing the text file of devices having devicename header
$Textfilepath = Read-Host -prompt 'Enter the path of text file storing the device names'
$Devices = Get-Content -path $TextFilePath

# Checking and Verifying if the latest version of Az, Microsoft.Graph & Az.DestopVirtualization powerShell modules are installed or not
Write-Host "Checking the required PowerShell modules are already installed or not..." -ForegroundColor 'Yellow'
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
            Write-Host "Latest version $($latest.version) of $($Module) PowerShell module is not installed. Hence installing it..." -ForegroundColor 'Yellow'
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
            Write-Host "The $($Module) PowerShell module with $($latest.version) version has been installed successfully on your machine." -ForegroundColor 'Green'
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
Write-Host "`nConnecting to Azure...." -ForegroundColor 'Yellow'
Connect-AzAccount -Tenant $TenantID -Subscription $Subscription  | Out-Null
Write-Host "Connected to Azure." -ForegroundColor 'Green'

# Connecting to Microsoft Graph
Write-Host "`nConnecting to Microsoft Graph API...." -ForegroundColor 'Yellow'
$AADRegisteredAppSecret = $AADRegisteredAppSecret | ConvertTo-SecureString -AsPlainText -Force
$ClientSecretCredential = New-Object -TypeName 'System.Management.Automation.PSCredential' -ArgumentList $AzureADRegisteredAppId, $AADRegisteredAppSecret
Connect-MgGraph -TenantId $TenantID -ClientSecretCredential $ClientSecretCredential | Out-Null
Write-Host "Connected To Microsoft Graph API." -ForegroundColor 'Green'

# Function to remove the AVD from the Azure VM portal
Function Remove-AVDFromAzureVMPortal {
    [cmdletbinding()]
    Param(
        $DeviceIdentity
    )
    
    $DeviceIdentity.StorageProfile.OsDisk.DeleteOption = 'Delete'
    $DeviceIdentity.StorageProfile.DataDisks | ForEach-Object { $_.DeleteOption = 'Delete' }
    $DeviceIdentity.NetworkProfile.NetworkInterfaces | ForEach-Object { $_.DeleteOption = 'Delete' }
    $DeviceIdentity | Update-AzVM -NoWait | Out-Null

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
    Write-Host "`n$($Count). For $($Device) AVD" -ForegroundColor 'Cyan'
    Write-Host "****************************************************************************************************" -ForegroundColor 'Cyan'

    # Shutting down the AVD if it is in running state
    $AVDPowerState = (Get-AzVm -ResourceGroupName $AVDResourceGroup -Name $Device -Status).statuses[1].DisplayStatus
    If ($AVDPowerState -eq "VM running") {
        Write-Host "The $($Device) AVD is still running. Hence shutting it down now." -ForegroundColor "Yellow"
        Try {
            Stop-AzVM -ResourceGroupName $AVDResourceGroup -Name $Device -ErrorAction 'Stop' -Force -NoWait
            Write-Host "$($Device) AVD has been sucessfully stopped." -ForegroundColor 'Green'
        }
        Catch {
            $errormessage = "Unable to shutdown the $($Device) AVD."
            Write-Error $errormessage
        }
    }
    Elseif ($null -eq $AVDPowerState) {
        Write-Host "$($Device) AVD is not found on Azure VM portal." -ForegroundColor 'Yellow'
    }

    # Removing the device identiy from AVD hostpool portal
    $AVDPortalIdentity = Get-AzWvdSessionHost -ResourceGroupName $HPResourceGroup -HostPoolName $HostPoolName -Name $Device
    If ($null -eq $AVDPortalIdentity) {
        Write-Host "$($Device) AVD does not exist in the AVD portal." -ForegroundColor 'Yellow'
    }
    Else {
        Write-Host "$($Device) AVD is existing in AVD hostpool portal. Hence deleting it..." -ForegroundColor 'Yellow'
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
        Write-Host "$($Device) AVD is existing in Azure VM portal. Hence deleting it..." -ForegroundColor 'Yellow'
        Remove-AVDFromAzureVMPortal -DeviceIdentity $AzureVMPortalIdentity
    }

    # Removing the device entry from Intune portal
    $IntuneDeviceIdentity = Get-MgDeviceManagementManagedDevice -Filter "deviceName eq '$($Device)'"
    If ($null -eq $IntuneDeviceIdentity) {
        Write-Host "$($Device) AVD does not exist in the Intune portal." -ForegroundColor 'Yellow'
    }
    Else {
        Write-Host "$($Device) AVD is existing in Intune portal. Hence deleting it..." -ForegroundColor 'Yellow'
        Try {
            Remove-MgDeviceManagementManagedDevice -ManagedDeviceId $IntuneDeviceIdentity.Id
            Write-Host "The device identity of $($Device) AVD device has been successfully deleted from the Intune portal." -ForegroundColor 'Green'
        }
        Catch {
            $errormessage = "Unable to delete the $($Device) AVD from Intune portal."
            Write-Error $errormessage
        }
    }

    # Removing the device identity from Azure AD portal
    $AzureADDeviceIdentity = Get-MgDevice -Filter "DisplayName eq '$($Device)'"
    If ($null -eq $AzureADDeviceIdentity) {
        Write-Host "$($Device) AVD does not exist in the Intune portal." -ForegroundColor 'Yellow'
    }
    Else {
        Write-Host "$($Device) AVD is existing in Azure AD portal. Hence deleting it..." -ForegroundColor 'Yellow'
        Try {
            Remove-MgDevice -DeviceId $AzureADDeviceIdentity.id  
            Write-Host "The device identity of $($Device) AVD has been successfully deleted from the Azure AD portal." -ForegroundColor 'Green'
        }
        Catch {
            $errormessage = "Unable to delete the $($Device) AVD from Azure AD portal."
            Write-Error $errormessage
        }
    }
}
