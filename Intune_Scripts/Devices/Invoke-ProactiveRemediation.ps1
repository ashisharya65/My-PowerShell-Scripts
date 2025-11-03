<#
.SYNOPSIS
    Invokes an Intune Proactive Remediation script on a specified device using Microsoft Graph API.

.DESCRIPTION
    This script authenticates to Microsoft Graph using an Azure AD app (Client Credentials flow), retrieves the device ID from Intune by device name, and triggers an on-demand Proactive 
    Remediation script on that device.

    It uses Microsoft Graph API beta endpoints:
        - /deviceManagement/managedDevices
        - /deviceManagement/managedDevices/{deviceId}/initiateOnDemandProactiveRemediation

.PARAMETER tenantid
    The Azure AD Tenant ID of your organization.

.PARAMETER clientid
    The Client ID (App Registration ID) from Azure AD.

.PARAMETER clientsecret
    The client secret (App password) associated with the Azure AD app registration.

.PARAMETER deviceName
    The device name as it appears in Microsoft Intune.

.PARAMETER scriptid
    The ID (GUID) of the Proactive Remediation script policy to invoke.

.EXAMPLE
    PS> .\Invoke-ProactiveRemediation.ps1 -tenantid "xxxx" -clientid "yyyy" -clientsecret "zzzz"
    Enter the device Name: DESKTOP-xxxxxx
    Enter the Proactive remediation script id: xxxx-xxxx-xxxx-xxxx-xxxxx

    This example triggers the specified remediation script on the given Intune-managed device.

.NOTES
    Author  : Ashish Arya
    Version : 1.0
    Date    : 03-November-2025

    Requirements:
        - Microsoft Graph API permissions:
            * DeviceManagementManagedDevices.ReadWrite.All
            * DeviceManagementConfiguration.ReadWrite.All
        - Azure AD app with client credentials flow enabled.

.LINK
    https://learn.microsoft.com/en-us/graph/api/intune-devices-manageddevice-initiateondemandproactiveremediation
#>

#region Entra registered app credentials
[CmdletBinding()]
param(
    [parameter(Mandatory = $false)][string]$tenantid,
    [parameter(Mandatory = $false)][string]$clientid,
    [parameter(Mandatory = $false)][string]$clientsecret
)
#endregion

#region Function to fetch Microsoft Graph API authentication token using client credentials
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
        
        # Return bearer token in authorization header format
        return @{ 
            "Authorization" = "Bearer $($response.access_token)" 
            "Content-Type"  = "application/json"
        }
    }
    catch {
        # Log token fetch failure
        Write-Error "Error while fetching token for '$deviceName': $($_.Exception.Message)"
    }
}
#endregion

#region Function: Get Device ID by Name
Function Get-DeviceId {
    param(
        [parameter(Mandatory)][Hashtable]$Token,
        [parameter(Mandatory)][string]$deviceName
    )

    try {
        $apiversion = "beta"
        $resource = "deviceManagement/managedDevices?`$filter=deviceName eq '$deviceName'"
        $uri = "https://graph.microsoft.com/$apiversion/$resource"

        $response = Invoke-RestMethod -Uri $uri -Method GET -Headers $authToken -ContentType 'application/json' -ErrorAction Stop
        if ($response.value.Count -eq 0) {
            throw "No device found with the name '$deviceName'."
        }

        return $response.value.id
    }
    catch {
        Write-Output "Unable to get the device name: $($_.Exception.Message)."
    }
}
#endregion

#region Function: Invoke Proactive Remediation
Function Invoke-ProactiveRemediation {
    param(
        [Parameter(Mandatory)][hashtable]$token,
        [parameter(Mandatory)][string]$deviceName ,
        [Parameter(Mandatory)][string]$scriptid 
    )

    try {
        $deviceid = Get-DeviceId -Token $Token -deviceName $deviceName
        $apiversion = "beta"
        $resource = "deviceManagement/managedDevices/$deviceId/initiateOnDemandProactiveRemediation"
        $uri = "https://graph.microsoft.com/$apiversion/$resource"

        $body = @{ scriptPolicyId = $scriptid } | ConvertTo-Json

        Invoke-RestMethod -Uri $uri -Method POST -Headers $token -Body $body -ContentType 'application/json' -ErrorAction Stop
        Write-Output "Proactive Remediation script invoked successfully on device '$deviceName'."
    }
    Catch {
        Write-Host "Unable to invoke the remediation script: $($_.Exception.Message)"
    }
}
#endregion

# ---------------- MAIN EXECUTION START ----------------
try {
    $deviceName = Read-Host -Prompt "Enter the device name"
    $scriptid = Read-Host -Prompt "Enter the Proactive Remediation script ID"
   
    $authToken = Get-AuthToken -tenantid $tenantid -clientid $clientid -clientsecret $clientsecret
    Invoke-ProactiveRemediation -token $authToken -deviceName $deviceName -scriptid $scriptid
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
}

# ---------------- MAIN EXECUTION END ----------------
