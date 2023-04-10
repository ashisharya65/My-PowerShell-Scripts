<#
    .SYNOPSIS
        Registring an Azure AD app for accessing Intune resources programatically

    .DESCRIPTION
        With this script, one will be able to register an Azure AD app which can help you to access the Intune resources using Microsoft Graph.
        This will also create the app secret for that app with proper API permissions.

    .NOTES
      Author : Ashish Arya
      Date   : 10-April-2023
#>

 
param(
    [Parameter(Mandatory = $true,
        HelpMessage = "The friendly name of the app registration")]
    [String]
    $AppName,

    [Parameter(Mandatory = $false,
        HelpMessage = "The sign in audience for the app")]
    [ValidateSet("AzureADMyOrg", "AzureADMultipleOrgs", `
            "AzureADandPersonalMicrosoftAccount", "PersonalMicrosoftAccount")]
    [String]
    $SignInAudience = "AzureADMyOrg",

    [Parameter(Mandatory = $false)]
    [Switch]
    $StayConnected = $false
)

# Tenant to use in authentication.
$authTenant = switch ($SignInAudience) {
    "AzureADMyOrg" { "tenantId" }
    "AzureADMultipleOrgs" { "organizations" }
    "AzureADandPersonalMicrosoftAccount" { "common" }
    "PersonalMicrosoftAccount" { "consumers" }
    default { "invalid" }
}

if ($authTenant -eq "invalid") {
    Write-Host -ForegroundColor Red "Invalid sign in audience:" $SignInAudience
    Exit
}

# Requires an admin
Write-Host
Connect-MgGraph -Scopes "Application.ReadWrite.All User.Read" -UseDeviceAuthentication -ErrorAction Stop 

# Get context for access to tenant ID
$context = Get-MgContext -ErrorAction Stop

if ($authTenant -eq "tenantId") {
    $authTenant = $context.TenantId
}

# Create app registration
$appRegistration = New-MgApplication -DisplayName $AppName -SignInAudience $SignInAudience `
    -IsFallbackPublicClient -ErrorAction Stop
Write-Host -ForegroundColor Cyan "`nApp registration was successfully done."

# Create corresponding service principal
if ($SignInAudience -ne "PersonalMicrosoftAccount") {
    New-MgServicePrincipal -AppId $appRegistration.AppId -ErrorAction SilentlyContinue `
        -ErrorVariable SPError | Out-Null
    if ($SPError) {
        Write-Host -ForegroundColor Red "A service principal for the app could not be created."
        Write-Host -ForegroundColor Red $SPError
        Exit
    }

    Write-Host -ForegroundColor Cyan "Service principal was also successfully created."
}

# Adding a secret
$passwordCred = @{
    displayName = 'MySecret'
    endDateTime = (Get-Date).AddMonths(6)
}
$Secret = Add-MgApplicationPassword -applicationId $appRegistration.id -PasswordCredential $passwordCred 

## Microsoft Graph's globally unique id
$MicrosoftGraphAppId = "00000003-0000-0000-c000-000000000000"

## Define the new Microsoft Graph permissions to be added to the target client
$newMicrosoftGraphPermissions = @{  
    ResourceAppID  = $MicrosoftGraphAppId
    ResourceAccess = @(

        ## Replace the following with values of ID and type for all Microsoft Graph permissions you want to configure for the app
        @{
            # User.Read scope (delegated permission) to sign-in and read user profile 
            id   = "e1fe6dd8-ba31-4d61-89e7-88639da4683d";
            type = "Scope"
        },
        @{
            # DeviceManagementApps.ReadWrite.All app role (application permission) to view application data
            id   = "78145de6-330d-4800-a6ce-494ff2d33d07";
            type = "Role";
        },
        @{
            # DeviceManagementConfiguration.ReadWrite.All app role (application permission) to view application data
            id   = "9241abd9-d0e6-425a-bd4f-47ba86e767a4";
            type = "Role";
        },
        @{
            # DeviceManagementManagedDevices.PrivilegedOperations.All app role (application permission) to view application data
            id   = "5b07b0dd-2377-4e44-a38d-703f09a0dc3c";
            type = "Role";
        },
        @{
            # DeviceManagementManagedDevices.ReadWrite.All app role (application permission) to view application data
            id   = "243333ab-4d21-40cb-a475-36241daa0842";
            type = "Role";
        },
        @{
            # DeviceManagementRBAC.ReadWrite.All app role (application permission) to view application data
            id   = "e330c4f0-4170-414e-a55a-2f022ec2b57b";
            type = "Role";
        },
        @{
            # DeviceManagementServiceConfig.ReadWrite.All (application permission) to view application data
            id   = "5ac13192-7ace-4fcf-b828-1a26f28068ee";
            type = "Role";
        },
        @{
            # Directory.Read.All app role (application permission) to view application data
            id   = "7ab1d382-f21e-4acd-a863-ba3e13f7da61";
            type = "Role";
        },
        @{
            # Group.Read.All app role (application permission) to view application data
            id   = "5b567255-7703-4780-807c-7be8301ae99b";
            type = "Role";
        },
        @{
            # Group.ReadWrite.All app role (application permission) to view application data
            id   = "62a82d76-70ea-41e2-9197-370581804d09";
            type = "Role";
        }
    )
}
$clientApp = Get-MgApplication -ApplicationId $appRegistration.id

## Intializing existing resoource access permissions
$existingResourceAccess = $clientApp.RequiredResourceAccess

## If the app has no existing permissions, or no existing permissions from our new permissions resource
if (([string]::IsNullOrEmpty($existingResourceAccess) ) -or ($existingResourceAccess | Where-Object { $_.ResourceAppId -eq $MicrosoftGraphAppId } -eq $null)) {
    $existingResourceAccess += $newMicrosoftGraphPermissions
    Update-MgApplication -ApplicationId $appRegistration.id -RequiredResourceAccess $existingResourceAccess
}
else {
    ## If the app already has existing permissions from our new permissions resource
    $existingResourceAccess = $existingResourceAccess + $newAzureADGraphPermissions + $newMicrosoftGraphPermissions
    Update-MgApplication -ApplicationId $appRegistration.id -RequiredResourceAccess $existingResourceAccess
}

Write-Host "================================" 
Write-Host "`nBelow are the app credentials: " -ForegroundColor Green
Write-Host "================================" 
Write-Host -ForegroundColor Cyan -NoNewline "Client ID: "
Write-Host -ForegroundColor Yellow $appRegistration.AppId
Write-Host -ForegroundColor Cyan -NoNewline "Object ID: "
Write-Host -ForegroundColor Yellow $appRegistration.Id
Write-Host -ForegroundColor Cyan -NoNewline "Tenand ID: "
Write-Host -ForegroundColor Yellow $authTenant
Write-Host -ForegroundColor Cyan -NoNewline "App Secret: " 
Write-Host -ForegroundColor Yellow $Secret.SecretText
Write-Host -ForegroundColor Cyan -NoNewline "Secret Expiry date: "
Write-Host -ForegroundColor Yellow $Secret.EndDateTime


#Disconnecting the session
if ($StayConnected -eq $false) {
    Disconnect-MgGraph | Out-Null
    Write-Host "`nDisconnected from Microsoft Graph`n"
}
else {
    Write-Host
    Write-Host -ForegroundColor Yellow `
        "The connection to Microsoft Graph is still active. To disconnect, use Disconnect-MgGraph"
}
