<#
.SYNOPSIS
Retrieves Intune managed Windows devices and their Primary User UPNs using Microsoft Graph API.

.DESCRIPTION
This script connects to Microsoft Graph using Entra ID App Registration details (Client Credentials flow),
fetches all Intune managed devices filtered by Windows OS, retrieves their assigned Primary Users,
and displays the results in a formatted table. Pagination is handled using the @odata.nextLink property
to ensure all devices are retrieved from Intune regardless of tenant size.

.PARAMETER tenantid
Azure Tenant ID (GUID) required for token authentication.

.PARAMETER clientid
Client Application ID from the Entra (Azure AD) App Registration.
Must have appropriate Microsoft Graph permissions such as:
- DeviceManagementManagedDevices.Read.All
- User.Read.All

.PARAMETER clientsecret
Client Secret generated from Entra App Registration used for API authentication.

.OUTPUTS
Displays a formatted table containing:
- DeviceName: Name of the Windows device
- UPN: Primary user assigned to that device in Intune

.NOTES
Author: Ashish Arya
Version: 1.0
Created On: 24 October 2025
Requires: PowerShell 5.1+ or PowerShell 7+, Microsoft Graph API access
Dependencies: App Registration with correct API permissions granted and admin consent completed

.EXAMPLE
PS C:\> .\Get-IntuneDeviceAndPrimaryUser.ps1 -tenantid "<tenant>" -clientid "<client>" -clientsecret "<secret>"
This executes the script and prints devices with their primary user UPNs.
#>

# Script parameters
[CmdletBinding()]
param(
    [parameter(Mandatory, helpmessage = "Enter the tenant id of Entra ID tenant.")][string]$tenantid,
    [parameter(Mandatory, helpmessage = "Enter the client id of Entra registered app.")][string]$clientid,
    [parameter(Mandatory, helpmessage = "Enter the tenant id of you Entra ID tenant.")][string]$clientsecret
)

# Function to display a header/footer style banner in script output
function Write-Banner{
    param($msg, $color = "Green")
    
    # Display a formatted banner in specified color
    Write-Host ("=" * 165) -ForegroundColor $color
    Write-Host (" " * 70 + $msg) -ForegroundColor $color
    Write-Host ("=" * 165) -ForegroundColor $color
}

# Function to fetch Graph API access token using Client Credentials authentication
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
        $response = Invoke-RestMethod -Method Post -Uri $tokenUrl -Body $body -ContentType "application/x-www-form-urlencoded"
        
        # Return bearer token in authorization header format
        return @{ Authorization = "Bearer $($response.access_token)" }

    } catch {
        # Log token fetch failure
        Write-Error "Error while fetching token: $($_.Exception.Message)"
        return $null
    }
}

# Function to fetch all Intune managed Windows devices from Microsoft Graph API
function Get-WinIntuneDevices {
    param($authToken)

    try {
        # API version and endpoint path for managed devices
        $apiversion = "beta"
        $resource = "deviceManagement/managedDevices"
        $uri = "https://graph.microsoft.com/$apiversion/$resource"    
        $devices = @()

        # Intune API pagination handling 
        do {
            # Query the API and retrieve a response page
            $response = Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get -ErrorAction Stop
            
            # Filter out devices that are running Windows OS
            $devices += $response.value | Where-Object { $_.operatingSystem -eq "Windows" }
            
            # Check for pagination link (if more data exists)
            $uri = $response."@odata.nextLink"
        }
        while ($uri)

        # Return collected Windows devices
        return $devices
    }
    Catch {
        Write-Error "Error while fetching Windows Devices: $($_.Exception.Message)"
    }
}

# Function to get assigned Primary User for each Intune device
function Get-PrimaryUserUPN {
    param($deviceId, $authToken)

    # API URL to query users assigned to the device
    $uri = "https://graph.microsoft.com/beta/devicemanagement/managedDevices/$deviceId/users"

    try {
        # Fetch user ID for primary assigned user
        $userid = (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get -ErrorAction Stop).value.id
        
        # If primary user found, fetch userPrincipalName (UPN)
        if($userid){
            return (Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/users/$userid" -Headers $authToken -ErrorAction Stop).userPrincipalName
        }
    }
    catch {
        # On failure, return a readable message instead of throwing
        return "Unable to get PrimaryUser details: $($_.Exception.Message)"
    }
}

###########################################################
# MAIN EXECUTION
###########################################################

# Banner indicating script has started
Write-Banner "INTUNE DEVICE INFO START"

Write-Host "`nFetching device details...`n" -ForegroundColor Yellow

# Get Graph API access token
$token = Get-AuthToken -tenantid $tenantid -clientid $clientid -clientsecret $clientsecret
if(!$token){ exit }   # Exit script if authentication fails

# Fetch Windows devices from Intune
$devices = Get-WinIntuneDevices -authToken $token
if(!$devices){
    Write-Host "No devices found." -ForegroundColor Yellow
    exit
}

# Loop through devices and build a new custom object collection
$deviceInfo = foreach($device in $devices){
    [PSCustomObject]@{
        DeviceName = $device.deviceName
        UPN        = Get-PrimaryUserUPN -deviceId $device.id -authToken $token
    }
}

# Format output table for clean display
$deviceInfo | Format-Table -AutoSize

# Display end banner
Write-Banner "INTUNE DEVICE INFO END"
