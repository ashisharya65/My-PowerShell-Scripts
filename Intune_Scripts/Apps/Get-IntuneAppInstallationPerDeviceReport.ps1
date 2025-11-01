<#
.SYNOPSIS
    Retrieves Intune device app installation status report for a given application.

.DESCRIPTION
    This script connects to the Microsoft Graph API using the Client Credentials flow (service principal authentication) and retrieves Intune device installation data for a specific application. 

    It calls the Graph beta endpoint:
        https://graph.microsoft.com/beta/deviceManagement/reports/retrieveDeviceAppInstallationStatusReport

    The report displays the device name, user principal name (UPN), installation status (Installed, Failed, Pending, etc.), and last modified time.

.PARAMETER tenantid
    The Microsoft Entra Tenant ID (GUID) of your organization.

.PARAMETER clientid
    The Client ID (Application ID) of the Azure AD app registration 
    that has the necessary Graph API permissions (DeviceManagementApps.Read.All or equivalent).

.PARAMETER clientsecret
    The client secret (app password) associated with the registered Azure AD application.

.EXAMPLE
    PS> .\Get-IntuneAppInstallationPerDeviceReport.ps1 -tenantid "tenant id" `
                                           -clientid "client id of your entra registered app" `
                                           -clientsecret "client-secret of your entra registered app"

    Enter the application id: <your app id>

    This example retrieves and displays the installation status of the specified Intune app
    across all managed devices in the tenant.

.NOTES
    Author: Ashish Arya
    Date:   01-Nov-2025
    Version: 1.0

    Required Graph API Permissions:
        - DeviceManagementApps.Read.All
        - DeviceManagementManagedDevices.Read.All

    You can run this script using a service principal with appropriate permissions in Microsoft Entra ID.

#>

[CmdletBinding()]
param(
    [parameter(Mandatory)][string]$tenantid,
    [parameter(Mandatory)][string]$clientid,
    [parameter(Mandatory)][string]$clientsecret
)

# Function to display banner messages for readability
function Write-Banner {
    param($msg, $color = "Green")
    
    # Display a formatted banner in specified color
    Write-Host ("=" * 165) -ForegroundColor $color
    Write-Host (" " * 70 + $msg) -ForegroundColor $color
    Write-Host ("=" * 165) -ForegroundColor $color
}

# Function to fetch Microsoft Graph API authentication token using client credentials
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
        Write-Error "Error while fetching token: $($_.Exception.Message)"
    }
}

# Function to get Intune App Installation Status per device for a given Application ID
Function Get-AppInstallationReportPerDevice {
    param(
        $appid,
        $authToken
    )

    try {
        $uri = "https://graph.microsoft.com/beta/deviceManagement/reports/retrieveDeviceAppInstallationStatusReport"
        $body = @"
        {
            "select": [
                "DeviceName",
                "UserPrincipalName",
                "Platform",
                "AppVersion",
                "InstallState",
                "InstallStateDetail",
                "AssignmentFilterIdsExist",
                "LastModifiedDateTime",
                "DeviceId",
                "ErrorCode",
                "UserName",
                "UserId",
                "ApplicationId",
                "AssignmentFilterIdsList",
                "AppInstallState",
                "AppInstallStateDetails",
                "HexErrorCode"
            ],
            "skip": 0,
            "top": 9999,
            "filter": "(ApplicationId eq '$appid')",
            "orderBy": []
        }
"@
        return $(Invoke-RestMethod -Uri $uri -Method Post -Headers $authToken -Body $body -ErrorAction Stop)
    }
    Catch {
        Write-Error "Error while fetching token: $($_.Exception.Message)"
    }
}

# ---------------------------------------------------------------------
# MAIN SCRIPT EXECUTION START
# ---------------------------------------------------------------------

Write-Host
Write-Banner "INTUNE APP INSTALLATION STATUS START"
Write-Host

# Get Graph API access token
$applicationid = Read-Host -prompt "Enter the application id"
$authToken = Get-AuthToken -tenantid $tenantid -clientid $clientid -clientsecret $clientsecret
$response = Get-AppInstallationReportPerDevice -authToken $authToken -appid $applicationid

if ($response -and $response.values -and $response.values.Count -gt 0) {

    $report = foreach ($row in $response.values) {
        [PSCustomObject]@{
            DeviceName            = $row[9]
            UserPrincipalName     = $row[18]
            AppInstallationStatus = $row[1]
            LastModifiedTime      = $row[14]
        }
    }

    $report | Format-Table -AutoSize
}
else {
    Write-Warning "No data found in report output."
}

Write-Host
Write-Banner "INTUNE APP INSTALLATION STATUS END"
Write-Host

# ---------------------------------------------------------------------
# MAIN SCRIPT EXECUTION END
# ---------------------------------------------------------------------
