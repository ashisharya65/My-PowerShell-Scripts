
<#
    .SYNOPSIS    
     This script is to authenticate to Graph API using Microsoft.Graph PowerShell module.

    .DESCRIPTION
     This script is to authenticate to Graph API using Microsoft.Graph PowerShell module.
     Here you need to add below environment variables to your PowerShell session or you can add your PowerShell profile.
    
        a) $Env:Azure_CLIENT_ID
        b) $Env:Azure_TENANT_ID
        c) $Env:Azure_CLIENT_SECRET
     
     With Microsoft Graph V2 version, we can use ClientSecretCredential parameter with Connect-MgGraph cmdlet which helps you
     to connect to Microsoft Graph API using your Client secret. Below is the link for your reference.
     
     https://devblogs.microsoft.com/microsoft365dev/microsoft-graph-powershell-v2-is-now-in-public-preview-half-the-size-and-will-speed-up-your-automations/#speed-up-your-automations
     
    .NOTES
      Author: Ashish Arya
      Date: 19 Jan 2023
#>

# Checking and Verifying if the latest Microsoft.Graph Module is installed or not
$latest = Find-Module -Name Microsoft.Graph -AllVersions -AllowPrerelease | select-Object -First 1
$current = Get-InstalledModule | Where-Object {$_.Name -eq "Microsoft.Graph"}
If ($latest.version -gt $current.version) {
        Try {
                  Update-Module -Name Microsoft.Graph -RequiredVersion $latest.version -AllowPrerelease
                  Write-Host "Microsoft Graph PowerShell module updated successfully to" $latest.Version -ForegroundColor Green
        }
        Catch {
                  Write-Host "Unable to update Microsoft Graph PowerShell module" -ForegroundColor Red
        }
} Else {
     Write-Host "Latest version of Microsoft Graph is not newer than the current" -ForegroundColor yellow
}

# Azure AD App details
$ApplicationId = $Env:Azure_CLIENT_ID
$TenantID = $Env:Azure_TENANT_ID
$ClientSecret = $Env:Azure_CLIENT_SECRET | ConvertTo-SecureString -AsPlainText -Force
$ClientSecretCredential = New-Object -TypeName 'System.Management.Automation.PSCredential' -ArgumentList $ApplicationId, $ClientSecret

# Connecting to Microsoft Graph
Connect-MgGraph -TenantId $TenantID -ClientSecretCredential $ClientSecretCredential | Out-Null
