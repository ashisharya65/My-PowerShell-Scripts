
<#
    .SYNOPSIS
        Duplicating Configuration profile in Intune
    .DESCRIPTION
        This script creates a duplicate configuration profile using an existing Intune config profile name.
        Pre-requisites for this script are MSAL.PS powershell module and Azure AD app details.
    .NOTES
        Author : Ashish Arya (@ashisharya65)
        Date   : 22-September-2022
    .EXAMPLE
       .\DuplicateConfigProfile.ps1 -ConfigProfileName <Existing Config ProfileName> -DuplicateConfigProfileName <Name for Duplicate Config Profile>"
#>

param(
    [Parameter(Mandatory,
        HelpMessage = "Enter the Intune Configuration Profile id.")]
    $ConfigProfileName,
    [Parameter(Mandatory,
        HelpMessage = "Enter the name of Duplicate Intune Configuration Profile.")]
    $DuplicateConfigProfileName
)

Function Get-AuthToken {
    <#
    .SYNOPSIS
    This function uses the Azure AD app details which in turn will help to get the access token to interact with Microsoft Graph API.
    .DESCRIPTION
    This function uses the Azure AD app details which in turn will help to get the access token to interact with Microsoft Graph API.
    As a prerequisite for executing this script, you will require the MSAL.PS powershell module for authenticating to the API.

    .EXAMPLE
    Get-AuthToken
    .NOTES
    NAME: Get-AuthToken
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
        ClientId     = 'ClientID'
        TenantId     = 'TenantID'
        ClientSecret = ('ClientSecret' | ConvertTo-SecureString -AsPlainText -Force)
    }
    $auth = Get-MsalToken @authParams

    $authorizationHeader = @{
        Authorization = $auth.CreateAuthorizationHeader()
    }

    return $authorizationHeader

}

Function Get-ConfigProfile {

    param(
        $ProfileName
    )

    $graphApiVersion = "Beta"
    $resource = "deviceManagement/deviceConfigurations"
    $Uri = "https://graph.microsoft.com/$graphApiVersion/$resource"

    try {
    (Invoke-RestMethod -Uri $Uri -Method Get -Headers $authToken).value | Where-Object { $_.displayName -eq $ProfileName }
    }
    catch {    
        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        write-host
        break
    }
}

Function Add-ConfigProfile() {

    <#
    .SYNOPSIS
    This function is used to add an device configuration policy using the Graph API REST interface
    .DESCRIPTION
    The function connects to the Graph API Interface and adds a device configuration policy
    .EXAMPLE
    Add-DeviceConfigurationPolicy -JSON $JSON
    Adds a device configuration policy in Intune
    .NOTES
    NAME: Add-DeviceConfigurationPolicy
    #>
    
    [cmdletbinding()]
    
    param
    (
        $JSON
    )
    
    $graphApiVersion = "Beta"
    $DCP_resource = "deviceManagement/deviceConfigurations"
    Write-Verbose "Resource: $DCP_resource"
    
    try {
    
        if (($JSON -eq "") -or ($null -eq $JSON)) {
    
            write-host "No JSON specified, please specify valid JSON for the Policy..." -f Red
    
        }
    
        else {
    
            #Test-JSON -JSON $JSON
    
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($DCP_resource)"
            Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"
            Write-Host "The duplicate profile $DuplicateConfigProfileName has been added to Intune." -ForegroundColor Green
    
        }
    
    }
    
    catch {
    
        $ex = $_.Exception
        $errorResponse = $ex.Response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($errorResponse)
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $responseBody = $reader.ReadToEnd();
        Write-Host "Response content:`n$responseBody" -f Red
        Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
        write-host
        break
    
    }
    
}


# Getting the Bearer access token for authenticating to MS Graph API
$authToken = Get-AuthToken

# Getting the Config profile data
$ConfigProfile = Get-ConfigProfile -ProfileName $ConfigProfileName 

# Elements required to be deleted from the above extracted config profile data 
$elements = @("id", "lastModifiedDateTime", "supportsScopeTags", "createdDateTime", "version”)

#Looping over the extracted Config profile data and removing the concerned elements from it
foreach ($key in ($ConfigProfile.Psobject.Properties.Name)) {
    foreach ($element in $elements) {
        if ($element -eq $key) {
            $ConfigProfile.Psobject.Properties.Remove($element)
        }
    }
}

# Changing the name to the config profile data for Duplicate Config Profile
$ConfigProfile.displayName = $DuplicateConfigProfileName

# Preparing the JSONPayload by converting the config profile deta to JSON object
$JSONPayload = $ConfigProfile | ConvertTo-Json 

# Printing the original profile and duplicated profile names
Write-Host "`nThe profile which is getting duplicated: $ConfigProfileName" -ForegroundColor DarkMagenta
Write-Host "The duplicate Intune Config Profile name: $DuplicateConfigProfileName" -ForegroundColor Cyan

# Passing the JSONPayload to Add-ConfigProfile function for creating the Duplicate Config Profile with a different name
Add-ConfigProfile -JSON $JSONPayload | Out-Null
