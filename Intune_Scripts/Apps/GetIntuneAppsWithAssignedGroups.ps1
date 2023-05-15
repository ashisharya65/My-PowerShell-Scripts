
<#
    .SYNOPSIS
        PowerShell Script to get all Intune Apps and their associated assigned Azure AD Groups.
    
    .DESCRIPTION
        With this Powershell script, one can easily get all the Intune apps deployed with all assigned Azure AD groups.

    .NOTES
        Author : Ashish Arya
        Date   : 15 May 2023
#>

# CSV file path
$CSVFilePath = "$($PSScriptRoot)\" + "$($myInvocation.myCommand.name.split('.')[0])" + ".csv"

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
    Write-Host "`nThe environment variables for your Azure AD app are not created. Hence creating..." -ForegroundColor "Yellow"
    Set-EnvtVariables
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

# Azure AD App details
$ApplicationId = $Env:Azure_CLIENT_ID
$TenantID = $Env:Azure_TENANT_ID
$ClientSecret = $Env:Azure_CLIENT_SECRET | ConvertTo-SecureString -AsPlainText -Force
$ClientSecretCredential = New-Object -TypeName 'System.Management.Automation.PSCredential' -ArgumentList $ApplicationId, $ClientSecret

# Connecting to Microsoft Graph
Connect-MgGraph -TenantId $TenantID -ClientSecretCredential $ClientSecretCredential | Out-Null

# Getting all the Intune applications details
$AllVNextApps = Get-MgDeviceAppManagementMobileApp -All 

Write-Host "`nCollating all the information.." -ForegroundColor 'Yellow'

#Create report object
$Report = [System.Collections.Generic.List[Object]]::new()

# Looping through all Intune Apps
Foreach ($App in $AllVNextApps) {
      
    # Get the assigned AAD group IDs for the Intune App
    $GroupIdsWithTwoTrailingZeroes = (Get-MgDeviceAppManagementMobileAppAssignment -MobileAppId $App.Id).Id

    # Getting the display name for the AAD groups
    Foreach ($Group in $GroupIdsWithTwoTrailingZeroes) {
        $GroupId = $Group.Split("_")[0]
        $GroupName = (Get-MgGroup -GroupID $GroupId).DisplayName
        [Array]$GroupNames += $GroupName
    }

    # Delimiting the Group names by comma (,)
    [string]$GroupList = $GroupNames -join ", "

    # Creating the app details object
    $ReportLine = [PSCustomObject][Ordered]@{  
        "ApplicationNames" = $App.DisplayName
        "GroupNames"       = $GroupList
    }

    # Adding the app details to the list
    $Report.Add($ReportLine)
}

Write-Host "`n Exporting all the information.." -ForegroundColor 'Yellow'

# Export CSV report 
$Report | Export-CSV -NoTypeInformation $CSVFilePath
