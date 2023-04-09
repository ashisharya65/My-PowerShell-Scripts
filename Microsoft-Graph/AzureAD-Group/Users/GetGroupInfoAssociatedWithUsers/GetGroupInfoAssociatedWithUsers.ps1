
<#
    .SYNOPSIS
    Getting the Azure AD groups associated with users.
    
    .DESCRIPTION
    PowerShell script to get all the Azure AD groups associated with the users mentioned in the csv file (attached to the GitHub repo).
    This script will prompt you to provide a regex pattern for group display names.

    .NOTES
    Author : Ashish Arya
    Date   : 13-March-2023
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

# Checking and Verifying if the latest Microsoft.Graph Module is installed or not
$latest = Find-Module -Name Microsoft.Graph -AllVersions -AllowPrerelease | select-Object -First 1
$current = Get-InstalledModule | Where-Object { $_.Name -eq "Microsoft.Graph" }
If ($latest.version -gt $current.version) {
    Try {
        Update-Module -Name Microsoft.Graph -RequiredVersion $latest.version -AllowPrerelease
        Write-Host "Microsoft Graph PowerShell module updated successfully to" $latest.Version -ForegroundColor Green
    }
    Catch {
        Write-Host "Unable to update Microsoft Graph PowerShell module" -ForegroundColor Red
    }
}
Elseif ($null -eq $current.version) {
    Try {
        Write-Host "The Microsoft Graph PowerShell module is not installed. Hence, installing it..." -ForegroundColor "Yellow"
        Install-Module Microsoft.Graph -scope CurrentUser -force
    }
    Catch {
        Write-Host "Unable to install the Microsoft Graph PowerShell module"
    }

}
Else {
    Write-Host "Latest version of Microsoft Graph is not newer than the current" -ForegroundColor 'Yellow'
}

# RegEx pattern for filtering the Azure AD group with their names
$RegExPattern = Read-Host -prompt "Enter your RegEx pattern for Azure AD Group name"

#Checking if the environment variables for the Azure AD app are created or not
if ($null -eq (Get-ChildItem env: | Where-Object { $_.Name -like "Azure_*" })) {
    
    Write-Host "`nThe environment variables for Azure AD app are not created. Hence creating..." -ForegroundColor "Yellow"

    Set-EnvtVariables
}

# Declare Azure AD app details
$ApplicationId = [System.Environment]::GetEnvironmentVariable("Azure_CLIENT_ID")
$TenantID = [System.Environment]::GetEnvironmentVariable("Azure_TENANT_ID")
$ClientSecret = [System.Environment]::GetEnvironmentVariable("Azure_CLIENT_SECRET") | ConvertTo-SecureString -AsPlainText -Force
$ClientSecretCredential = New-Object -TypeName 'System.Management.Automation.PSCredential' -ArgumentList $ApplicationId, $ClientSecret

# Connecting to Microsoft Graph
Connect-MgGraph -TenantId $TenantID -ClientSecretCredential $ClientSecretCredential | Out-Null

# Importing the users details from the CSV file
$UsersInfo = Import-Csv -path ".\users.csv"

# Storing the Group Info
$GroupInfo = @()

Write-Host -ForegroundColor Yellow "`n-----------------------------------------"
Write-Host -ForegroundColor Yellow "| Azure AD Groups associated with users |"
Write-Host -ForegroundColor Yellow "-----------------------------------------"

# Looping through all users
Foreach($User in $UsersInfo){

    Try{
        $Userid = (Get-MgUser -Filter "userPrincipalName eq '$($User.userupn)'").id
        if($Null -eq $Userid){
            throw "User variable is empty"
        }
        else{       

            $CustomObj = [PSCustomObject]@{
                UserName = $($User.username)
                Groups = ((Get-MgUserMemberOf -UserId $Userid -All).AdditionalProperties | `
                            Select @{n="DisplayName";e={$_.displayName}} | where {$_.displayName -match $RegExPattern}).displayName
            }

            $GroupInfo += $CustomObj
            
        }
    }
    Catch{
            Write-Error -Message "$($User.username)'s account is not available in Azure AD."
    }
}

#Writing the groups information associated with the users on the console
$GroupInfo | Select UserName, Groups
