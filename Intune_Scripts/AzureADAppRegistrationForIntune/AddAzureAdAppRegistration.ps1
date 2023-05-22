<#
    .SYNOPSIS
        Registring an Azure AD app for accessing Intune resources programatically.

    .DESCRIPTION
        With this script, one will be able to register an Azure AD app which can help you to access the Intune resources using Microsoft Graph.
        This will also create the app secret for that app with proper API permissions.

    .NOTES
      Author : Ashish Arya
      Date   : 10-April-2023
#>

 
Param(
    [Parameter(Mandatory = $True,HelpMessage = "The friendly name of the app registration")]
    [String] $AppName,

    [Parameter(Mandatory = $False, HelpMessage = "The sign in audience for the app")]
    [ValidateSet("AzureADMyOrg", "AzureADMultipleOrgs","AzureADandPersonalMicrosoftAccount", "PersonalMicrosoftAccount")]
    [String] $SignInAudience = "AzureADMyOrg",

    [Parameter(Mandatory = $False)]
    [Switch] $StayConnected = $False
)

# Tenant to use in authentication.
$AuthTenant = Switch ($SignInAudience) {
    "AzureADMyOrg" { "tenantId" }
    "AzureADMultipleOrgs" { "organizations" }
    "AzureADandPersonalMicrosoftAccount" { "common" }
    "PersonalMicrosoftAccount" { "consumers" }
    default { "invalid" }
}

If ($AuthTenant -eq "invalid") {
    Write-Host "Invalid sign in audience:" $SignInAudience -ForegroundColor 'Red'
    Exit
}

# Checking and Verifying if the latest Microsoft.Graph Module is installed or not
$Latest = Find-Module -Name 'Microsoft.Graph' -AllVersions -AllowPrerelease | select-Object -First 1
$Current = Get-InstalledModule | Where-Object { $_.Name -eq "Microsoft.Graph" }
If ($Latest.version -gt $Current.version) {
    Try {
        Update-Module -Name 'Microsoft.Graph' -RequiredVersion $Latest.version -AllowPrerelease
        Write-Host "Microsoft Graph PowerShell module updated successfully to" $Latest.Version -ForegroundColor 'Green'
    }
    Catch {
        Write-Host "Unable to update Microsoft Graph PowerShell module" -ForegroundColor 'Red'
    }
}
Elseif ($null -eq $Current.version) {
    Try {
        Write-Host "The Microsoft Graph PowerShell module is not installed. Hence, installing it..." -ForegroundColor "Yellow"
        Install-Module 'Microsoft.Graph' -scope 'CurrentUser' -force
    }
    Catch {
        Write-Host "Unable to install the Microsoft Graph PowerShell module" -ForegroundColor 'Red'
    }

}
Else {
    Write-Host "Latest version of Microsoft Graph is not newer than the current" -ForegroundColor 'Yellow'
}

# Requires an admin
Write-Host
Connect-MgGraph -Scopes "Application.ReadWrite.All User.Read" -UseDeviceAuthentication -ErrorAction 'Stop'

# Get context for access to tenant ID
$Context = Get-MgContext -ErrorAction Stop

if ($AuthTenant -eq "tenantId") {
    $AuthTenant = $Context.TenantId
}

# Create app registration
$AppRegistration = New-MgApplication -DisplayName $AppName -SignInAudience $SignInAudience -IsFallbackPublicClient -ErrorAction 'Stop'
Write-Host "`nApp registration was successfully done." -ForegroundColor 'Cyan'

# Create corresponding service principal
if ($SignInAudience -ne "PersonalMicrosoftAccount") {
    New-MgServicePrincipal -AppId $AppRegistration.AppId -ErrorAction 'SilentlyContinue' -ErrorVariable 'SPError' | Out-Null
    if ($SPError) {
        Write-Host "A service principal for the app could not be created." -ForegroundColor 'Red'
        Write-Host $SPError -ForegroundColor 'Red'
        Exit
    }
    Write-Host "Service principal was also successfully created." -ForegroundColor 'Cyan'
}

# Adding a secret
$PasswordCred = @{
    DisplayName = "MySecret"
    EndDateTime = (Get-Date).AddMonths(6)
}
$Secret = Add-MgApplicationPassword -applicationId $AppRegistration.id -PasswordCredential $PasswordCred 

## Microsoft Graph's globally unique id
$MicrosoftGraphAppId = (Get-MgServicePrincipal | Where-Object { $_.DisplayName -eq "Microsoft Graph" }).AppId

## Define the new Microsoft Graph permissions to be added to the target client
$NewMicrosoftGraphPermissions = @{  
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

## Intializing existing resoource access permissions
$ExistingResourceAccess = $AppRegistration.RequiredResourceAccess

## If the app has no existing permissions, or no existing permissions from our new permissions resource
If (([string]::IsNullOrEmpty($ExistingResourceAccess) ) -or ($ExistingResourceAccess | Where-Object { $_.ResourceAppId -eq $MicrosoftGraphAppId } -eq $null)) {
    $ExistingResourceAccess += $NewMicrosoftGraphPermissions
    Update-MgApplication -ApplicationId $AppRegistration.id -RequiredResourceAccess $ExistingResourceAccess
}

Write-Host "`n================================" 
Write-Host "Below are the app credentials: " -ForegroundColor Green
Write-Host "================================" 
Write-Host "Client ID: " -ForegroundColor 'Cyan' -NoNewline
Write-Host $AppRegistration.AppId --ForegroundColor 'Yellow'
Write-Host "Object ID: " -ForegroundColor 'Cyan' -NoNewline
Write-Host $AppRegistration.Id -ForegroundColor 'Yellow'
Write-Host "Tenand ID: " -ForegroundColor 'Cyan' -NoNewline
Write-Host $AuthTenant -ForegroundColor 'Yellow'
Write-Host "App Secret: " -ForegroundColor 'Cyan' -NoNewline 
Write-Host $Secret.SecretText -ForegroundColor Yellow 
Write-Host "Secret Expiry date: " -ForegroundColor 'Cyan' -NoNewline 
Write-Host $Secret.EndDateTime -ForegroundColor 'Yellow'

#Disconnecting the session
if ($StayConnected -eq $False) {
    Disconnect-MgGraph | Out-Null
    Write-Host "`nDisconnected from Microsoft Graph`n" -ForegroundColor 'Yellow'
}
else {
    Write-Host
    Write-Host "The connection to Microsoft Graph is still active. To disconnect, use Disconnect-MgGraph" -ForegroundColor Yellow
}

######################################################################## END ###################################################################
