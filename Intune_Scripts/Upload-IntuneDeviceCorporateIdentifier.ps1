
<#
.SYNOPSIS
    Uploads a device's manufacturer, model, and serial number information to Microsoft Intune using Microsoft Graph API.

.DESCRIPTION
    This script authenticates to Microsoft Graph using Azure AD app registration credentials (Client ID, Client Secret, Tenant ID),
    retrieves the device's hardware details via WMI (manufacturer, model, serial number),
    checks if the device is already imported in Intune, and if not, uploads it using the Graph API.

.PARAMETER TenantId
   Microsoft Entra tenant ID of your organization.

.PARAMETER ClientId
    Application (client) ID of your registered Azure AD app.

.PARAMETER ClientSecret
    Secret associated with your Azure AD app.

.EXAMPLE
    .\Upload-IntuneDeviceCorporateIdentifier.ps1 -TenantId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" -ClientId "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" -ClientSecret "your-secret"

.NOTES
    Author: Ashish Arya
    Version: 1.0
    Requires: PowerShell 5.1+ or PowerShell 7+, Microsoft Graph API permissions (DeviceManagementServiceConfig.ReadWrite.All)
#>

#region Entra registered app details
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$TenantId,
    [Parameter(Mandatory)][string]$ClientId,
    [Parameter(Mandatory)][string]$ClientSecret
)
#endregion

#region function to retrieve Microsoft Graph access token
function Get-AuthToken {
    param($tenantid, $clientid, $clientsecret)

    # URL used to request OAuth 2.0 access token
    $tokenUrl = "https://login.microsoftonline.com/$tenantid/oauth2/v2.0/token"

    # Authentication request body parameters
    $body = @{
        client_id     = $clientid
        client_secret = $clientsecret
        scope         = "https://graph.microsoft.com/.default"
        grant_type    = 'client_credentials'
    }

    try {
        # Invoke REST request for authentication token
        $response = Invoke-RestMethod -Method Post -Uri $tokenUrl -Body $body -ContentType "application/x-www-form-urlencoded" -ErrorAction Stop
        Write-Host "Access token was successfully retrieved." -f Green
        
        # Return bearer token in authorization header format
        return @{ 
            "Authorization" = "Bearer $($response.access_token)" 
            "Content-Type"  = "application/json"
        }

    }
    catch {
        # Log token fetch failure
        Write-Host "Error while fetching token: $($_.Exception.Message)" -f Red
        return $null
    }
}
#endregion

#region function to retrieve the imported device identity information from Microsoft Intune by serial number.
Function Get-DeviceCorpIdFromIntune {
    param(
        [parameter(Mandatory)][Hashtable]$token,
        [parameter(Mandatory)][string] $serialnumber
    )
    try {
        $apiversion = "beta"
        $resource = "deviceManagement/importedDeviceIdentities?`$filter=contains(importedDeviceIdentifier,'$serialNumber')"
        $uri = "https://graph.microsoft.com/$apiversion/$resource"
        $response = (Invoke-RestMethod -Uri $uri -Method GET -Headers $token ).Value.importedDeviceIdentifier
        return $response
    }
    catch {
        Write-Host "Failed to retrieve device identifier: $($_.Exception.Message)" -f Red
        return $null
    }
}
#endregion

#region function to upload the device details (manufacturer, model, serial) to Microsoft Intune if not already imported.
Function Upload-CorpIdentifier {
    param(
        [Hashtable]$token
    )

    try {
        $computerSystem = Get-CimInstance -ClassName Win32_ComputerSystem -ErrorAction Stop
        $bios = Get-CimInstance -ClassName Win32_BIOS -ErrorAction Stop
        $deviceidentifier = "$($computerSystem.Manufacturer),$($computerSystem.Model),$($bios.SerialNumber)"
    }
    catch {
        Write-Host "Failed to retrieve system information: $($_.Exception.Message)" -f Red
        return $null
    }

    $response = Get-DeviceCorpIdFromIntune -token $token -serialnumber $($bios.SerialNumber)
    if ($response) {
        Write-Host "'$($env:COMPUTERNAME)' device identifier is already imported in Intune." -f Green
    }
    else {
        $apiversion = "beta"
        $resource = "deviceManagement/importedDeviceIdentities/importDeviceIdentityList"
        $uri = "https://graph.microsoft.com/$apiversion/$resource"

        $params = @{
            overwriteImportedDeviceIdentities = $false
            importedDeviceIdentities          = @(
                @{
                    importedDeviceIdentityType = "manufacturerModelSerial"
                    importedDeviceIdentifier   = $deviceidentifier
                }
            )
        } | ConvertTo-Json

        try {
            Invoke-RestMethod -Uri $uri -Method POST -Headers $token -Body $params -ErrorAction Stop | Out-Null
            Write-Host "Device details are successfully uploaded to Intune." -f Green
        }
        catch {
            Write-Host "Failed to upload device details to Intune: $($_.Exception.Message)" -f Red
            return $null
        }   
    }
}
#endregion

#region ---- Main Execution ----
Write-Host "`n==== Starting Intune Device Upload ====`n" -ForegroundColor Yellow
$authtoken = Get-AuthToken -TenantId $TenantId -ClientId $ClientId -ClientSecret $ClientSecret
if ($null -ne $authtoken) {
    Upload-CorpIdentifier -token $authtoken
}
Write-Host "`n==== Completed Successfully ====`n" -ForegroundColor Yellow
#endregion
