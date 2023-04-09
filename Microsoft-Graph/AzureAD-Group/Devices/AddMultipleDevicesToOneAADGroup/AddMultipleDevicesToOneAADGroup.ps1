
<#

    .SYNOPSIS
    This script we will be adding multiple devices to an Azure AD security group.
        
    .DESCRIPTION
    WIth this script, we are going to leverage Microsoft Graph PowerShell module to add mulitple devices to Azure AD group.

    .NOTES
        Author: Ashish Arya
        Date: 19 Jan 2023

#>

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

# Azure AD App details
$ApplicationId = $Env:Azure_CLIENT_ID
$TenantID = $Env:Azure_TENANT_ID
$ClientSecret = $Env:Azure_CLIENT_SECRET | ConvertTo-SecureString -AsPlainText -Force
$ClientSecretCredential = New-Object -TypeName 'System.Management.Automation.PSCredential' -ArgumentList $ApplicationId, $ClientSecret

# Connecting to Microsoft Graph
Connect-MgGraph -TenantId $TenantID -ClientSecretCredential $ClientSecretCredential | Out-Null

# Getting the Group Object id
$AADGroup = Read-Host -prompt "Enter the Device group where you want your device to be added "
$AADGroupID = (Get-MgGroup -Filter "displayName eq '$($AADGroup)'").id

# Getting All the device names from the device.txt text file
$Devices = Read-Host -prompt "Enter the path of text file containing the device names: "

# Looping through all devices to add them to the AAD group.
Foreach ($Device in $Devices) {
    
    # Getting Device id 
    $DeviceId = (Get-MgDevice -Filter "displayname eq '$($Device)'").id

    # Preparing the Json payload
    $params = @{
        "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/{$($DeviceId)}"
    }

    # Adding the device to the group
    New-MgGroupMemberByRef -GroupId $AADGroupID -BodyParameter $params

    Write-Host "The Device $($Device) is added to the $($AADGroup) group." -f 'Green'
    
}

