
<#
    .SYNOPSIS
        Script to enable features that require Windows diagnostic data in processor configuration.
    .DESCRIPTION
        This script will enable the features that require Windows diagnostic data in processor configuration.
        This will toggle on the setting under Tenant Administration ==> Connectors and tokens ==> Windows data ==> Windows data 
    .NOTES
        Author: Ashish Arya
        Date: 25 July 2023
#>


Function Get-AuthToken {

    <#
    .SYNOPSIS
     This function uses the Azure AD app details which in turn will help to get the access token to interact with Microsoft Graph API.

    .DESCRIPTION
     This function uses the Azure AD app details which in turn will help to get the access token to interact with Microsoft Graph API.
     As a prerequisite for executing this script, you will require the MSAL.PS powershell module for authenticating to the API.
     Here you need to add the below environment variables (as per your Azure AD app credentials) on your local machine.
    
        a) $Env:Azure_CLIENT_ID
        b) $Env:Azure_TENANT_ID
        c) $Env:Azure_CLIENT_SECRET

    .EXAMPLE
     Get-AuthToken

    .NOTES
     Author: Ashish Arya
     Date: 19 Jan 2023
  #>
    
    # Checking if the MSAL.PS Powershell module is installed or not. If not then it will be installed.
    Write-Host "Checking for MSAL.PS module..."
    $MSALPSModule = Get-Module -Name MSAL.PS -ListAvailable

    if ($null -eq $MSALPSModule) {
        Write-Host "MSAL.PS PowerShell module is not installed." -f Red 
        $Confirm = Read-Host "Press Y for installing the module or N for cancelling the installion"

        if ($Confirm -eq "Y") {
            Install-Module -name 'MSAL.PS' -Scope CurrentUser -Force
        }  
        else {
            Write-Host "You have cancelled the installation and the script cannot continue.." -f Red
            write-host
            exit
        }
    }

    # Azure AD app details
    $authparams = @{
        ClientId     = $Env:Azure_CLIENT_ID
        TenantId     = $Env:Azure_TENANT_ID
        ClientSecret = ($Env:Azure_CLIENT_SECRET | ConvertTo-SecureString -AsPlainText -Force)
    }
    
    $auth = Get-MsalToken @authParams
    
    $authorizationHeader = @{
        Authorization = $auth.CreateAuthorizationHeader()
    }

    return $authorizationHeader
}

$AuthToken = Get-AuthToken

$uri = "https://graph.microsoft.com/beta/deviceManagement/dataProcessorServiceForWindowsFeaturesOnboarding"

$Json = @"
{
    "@odata.type": "#microsoft.graph.dataProcessorServiceForWindowsFeaturesOnboarding",
    "areDataProcessorServiceForWindowsFeaturesEnabled": "true"
}
"@

Invoke-RestMethod -Uri $uri -Headers $authToken -Method 'Patch' -Body $Json -ContentType "application/json"

