
<#
    .SYNOPSIS
        PowerShell Script to extract a report of Intune Apps and their assigned Azure AD groups.

    .DESCRIPTION
        WIth this Powershell script, we will get a report of all the Intune apps created in your Tenant and their assigned Azure AD groups.
        This script uses the Microsoft.Graph PowerShell module which will be automatically installed if it is not there on the local machine. 
    
    .NOTES
        Author : Ashish Arya
        Date   : 17 May 2023
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
If ($null -eq (Get-ChildItem env: | Where-Object { $_.Name -like "Azure_*" })) {
    Write-Host "`nThe environment variables for your Azure AD app are not created. Hence creating..." -ForegroundColor "Yellow"
    Set-EnvtVariables
}

# Checking and Verifying if the latest Microsoft.Graph PowerShell Module is installed 
$latest = Find-Module -Name 'Microsoft.Graph' -AllVersions -AllowPrerelease | Select-Object -First 1
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
    Write-Host "`nLatest version of Microsoft Graph is not newer than the current" -ForegroundColor 'Yellow'
}

# Azure AD App details
$ApplicationId = $Env:Azure_CLIENT_ID
$TenantID = $Env:Azure_TENANT_ID
$ClientSecret = $Env:Azure_CLIENT_SECRET | ConvertTo-SecureString -AsPlainText -Force
$ClientSecretCredential = New-Object -TypeName 'System.Management.Automation.PSCredential' -ArgumentList $ApplicationId, $ClientSecret

# Connecting to Microsoft Graph
Connect-MgGraph -TenantId $TenantID -ClientSecretCredential $ClientSecretCredential | Out-Null

# Getting all the Intune applications details
$AllApps = Get-MgDeviceAppManagementMobileApp -all | Select-Object Id,DisplayName


Write-Host "`nCollating all the information..`n" -ForegroundColor 'Yellow'

# Looping through all Intune Apps
Foreach($App in $AllVNextApps){

    # Inializing the variables 
    $GroupIdsEndingWithTwoZeroes = $GroupNames = $null
    
    # Getting the Group Ids ending with Two zeroes (ex 1234_12123_43432313_4313131_0_0)
    $GroupIdsEndingWithTwoZeroes = (Get-MgDeviceAppManagementMobileAppAssignment -MobileAppId $App.Id).Id

    # Looping through the Group Ids to get the corresponding group names
    Foreach($Group in $GroupIdsEndingWithTwoZeroes){
       
        # Splitting the GroupId (ending with two zeroes) to get the actual group id.
        $GroupId = $Group.Split("_")[0]
       
        # Getting the Group DisplayName
        $GroupName = (Get-MgGroup -GroupId $GroupId).DisplayName
       
        # Collecting all the group names
        [Array] $GroupNames += $GroupName
    }

    # Joining group names using comma(,)
    [string]$GroupList = $GroupNames -join ", "

    # Creating the custom object to store Intune app name and Group names
    $ReportLine = [PSCustomObject][Ordered]@{  
        "ApplicationNames"     = $App.DisplayName
        "GroupNames"           = $GroupList
    }

    # Adding the custom object to the report array
    [Array] $Report += $ReportLine
}

Write-Host "`n Exporting all the information..`n" -ForegroundColor 'Yellow'

# Exporting the app and groups details to CSV report
$Report | Export-CSV -NoTypeInformation $CSVFilePath
