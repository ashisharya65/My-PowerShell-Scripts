<#
.SYNOPSIS
    Script to export all the Intune deployed PowerShell scripts to the local machine.
.DESCRIPTION
    With this PowerShell script, we can export all the Intune deployed PowerShell scripts to the local machine.
.NOTES
    Author: Ashish Arya
    Date: 24-Jan-2023
#>

#Function for Setting Environment Variables
Function Set-EnvtVariables {
    <#
    .SYNOPSIS
    Function set the environment variables in user context.
    .DESCRIPTION
    This script will help you to create the user environment variables on the device where you are executing this script.
    This script will ask you to provide the Clientid, ClientSecret and Tenantid from your Azure AD app created for PowerShell-Graph API integration.
    .EXAMPLE
    Set-EnvtVariables
    .NOTES
    Name: Set-EnvtVariables
    #>
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [string] $ClientId,
        [Parameter(Mandatory)]
        [string] $ClientSecret,
        [Parameter(Mandatory)]
        [string] $TenantId
    )

    $EnvtVariables = @(
        [PSCustomObject]@{
            Name  = "AZURE_CLIENT_ID"
            Value = $CliendId
        },
        [PSCustomObject]@{
            Name  = "AZURE_CLIENT_SECRET"
            Value = $ClientSecret
        },
        [PSCustomObject]@{
            Name  = "AZURE_TENANT_ID"
            Value = $TenantId
        }
    )

    Foreach ($EnvtVar in $EnvtVariables) {
        
        Try {
            [System.Environment]::SetEnvironmentVariable($EnvtVar.Name, $EnvtVar.Value, [System.EnvironmentVariableTarget]::User)
        }
        Catch {
            Write-Host "Unable to set the $($EnvtVar.Name) environment value. So please set the Environment variables for your Azure AD registered app in order to execute this script successfully." -foreground 'Red'
        }
        
    }
}

#Checking if the environment variables for the Azure AD app are created or not
if ($null -eq (Get-ChildItem env: | Where-Object { $_.Name -like "Azure_*" })) {
    
    Write-Host "`nThe environment variables for Azure AD app are not created. Hence creating..." -ForegroundColor "Yellow"

    Set-EnvtVariables
}

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
        Install-Module -name 'MSAL.PS' -Scope CurrentUser -Force  
    }
    
    # Azure AD app details
    $authparams = @{
        ClientId     = [System.Environment]::GetEnvironmentVariable("Azure_CLIENT_ID")
        TenantId     = [System.Environment]::GetEnvironmentVariable("AZURE_TENANT_ID")
        ClientSecret = ([System.Environment]::GetEnvironmentVariable("AZURE_CLIENT_SECRET") | ConvertTo-SecureString -AsPlainText -Force)
    }
    $auth = Get-MsalToken @authParams

    $authorizationHeader = @{
        Authorization = $auth.CreateAuthorizationHeader()
    }

    return $authorizationHeader

}

Function Get-IntunePowerShellScripts {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory = $true)][String] $Path
    )

    $ApiVersion = "Beta"
    $Resource = "deviceManagement/deviceManagementScripts" 
    

    $Result = Invoke-RestMethod -Uri "https://graph.microsoft.com/$ApiVersion/$Resource" -Method GET -Headers $authtoken

    $AllPSScripts = $result.value | Where-Object { $_.displayname -like "*VNEXT*" } | Select-Object id, displayname, fileName

    Foreach ($PSScript in $AllPSScripts) {

        $Script = Invoke-RestMethod -Uri "$resource/deviceManagement/deviceManagementScripts/$($PSScript.id)" -Method GET -Headers $authtoken | `
            Where-Object { $_.displayname -like "*VNEXT*" }

        [System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String($($Script.scriptContent))) | `
            Out-File -FilePath $(Join-Path $Path $($PSScript.fileName)) -Encoding ASCII
    }

}

$FolderPath = Read-Host -Prompt "Enter the full path of the folder where you want to place the Intune PowerShell scripts"
$authToken = Get-AuthToken
Get-IntunePowerShellScripts -FolderPath $FolderPath
