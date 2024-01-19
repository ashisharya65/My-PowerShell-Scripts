<#
    .SYNOPSIS
        PowerShell Script to extract a report of Intune Apps and their assigned Azure AD groups.

    .DESCRIPTION
        With this Powershell script, we will get a report of all the Intune apps created in your Tenant and their assigned Azure AD groups.
        This script uses the Microsoft.Graph, ImportExcel PowerShell modules which will be automatically installed if they are not there on the local machine. 
    
    .NOTES
        Author : Ashish Arya
        Date   : 17 May 2023
#>

# Excel file path
$ExcelFilePath = "$($PSScriptRoot)\" + "$($myInvocation.myCommand.name.split('.')[0])" + ".xlsx"

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
            Value = $ClientId
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

# Checking and Verifying if the latest ImportExcel,Microsoft.Graph PowerShell Modules are installed 
$CurrentModules = Get-InstalledModule | Where-Object {($_.Name -eq 'ImportExcel')-or($_.Name -eq "Microsoft.Graph")}`
                  | Select-Object Name,Version | Sort-Object -Property Name

Foreach($Current in $CurrentModules){

    $Latest = Find-Module -Name $Current.Name | Select-Object Name, Version
    
    If ($Latest.Version -gt $Current.Version){
        Try {
            Write-Host "The $($Current.Name) PowerShell module is not updated. Hence, updating it..." -ForegroundColor 'Yellow'
            Uninstall-Module -Name $Current.Name -RequiredVersion $Current.Version -Force:$True
            Install-Module -Name $Current.Name -RequiredVersion $Latest.version -AllowPrerelease -ErrorAction 'Stop'
            Write-Host "$($Current.Name) PowerShell module was updated successfully to $($Latest.Version) version." -ForegroundColor 'Green'

        }
        Catch {
            Write-Host "Unable to update $($Current.Name) PowerShell module.`n" -ForegroundColor Red
        }
    }
    Elseif ($null -eq $Current.version) {
        Try {
            Write-Host "$($Current.Name) PowerShell module is not installed. Hence, installing it..." -ForegroundColor "Yellow"
            Install-Module "$($Current.Name)" -Scope 'CurrentUser' -force
        }
        Catch {
            Write-Host "`nUnable to install the $($Current.Name) PowerShell module,`n" -ForegroundColor 'Red'
        }
    }
    Else {
        Write-Host "Latest version of $($Current.Name) PowerShell Module is not newer than the current version." -ForegroundColor 'Cyan'
    }
}

# Azure AD App details
$ApplicationId = $Env:Azure_CLIENT_ID
$TenantID = $Env:Azure_TENANT_ID
$ClientSecret = $Env:Azure_CLIENT_SECRET | ConvertTo-SecureString -AsPlainText -Force
$ClientSecretCredential = New-Object -TypeName 'System.Management.Automation.PSCredential' -ArgumentList $ApplicationId, $ClientSecret

# Connecting to Microsoft Graph
Connect-MgGraph -TenantId $TenantID -ClientSecretCredential $ClientSecretCredential | Out-Null

# Getting all the Intune applications details
$AllApps = Get-MgDeviceAppManagementMobileApp -all | Select-Object DisplayName,Id

Write-Host "`nCollating all the information..`n" -ForegroundColor 'Yellow'

# Looping through all Intune Apps
Foreach($App in $AllApps){

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

# Exporting the app and groups details to Excel report
$Report | Export-Excel $ExcelFilePath -TableStyle 'Medium16'
