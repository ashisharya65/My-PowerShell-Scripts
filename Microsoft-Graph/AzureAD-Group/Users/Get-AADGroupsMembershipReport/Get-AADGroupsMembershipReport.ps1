
<#
    .SYNOPSIS
        Script to export the Group Members of all of your Azure AD groups to a CSV file.

    .DESCRIPTION
        This script will create a CSV report which has all the Azure AD groups and their member details.
        This script requires the Microsoft.Graph powershell module and we have included all the command to install it forcefully if it is not installed.
        
    .NOTES
        Author : Ashish Arya
        Date   : 26 April 2023
#>

# CSV file path
$CSVFilePath = "$($PSScriptRoot)\" + "$($myInvocation.myCommand.name.split('.')[0])" + ".csv"

# Function for Setting Environment Variables
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
            Write-Host "Unable to set the $($EnvtVar.Name) environment value." -foreground 'Red'
        }
        
    }
}

#Checking if the environment variables for the Azure AD app are created or not
if ($null -eq (Get-ChildItem env: | Where-Object { ($_.Name -like "Azure_*") })) {
    
    Write-Host "`nThe environment variables for Azure AD app are not created. Hence creating..." -ForegroundColor "Yellow"

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

# Getting all the groups with displayname starting with the provided pattern
$Groups = Get-MgGroup -Top 5000

#Create report object
$Report = [System.Collections.Generic.List[Object]]::new()

# Looping through all the filtered groups
ForEach ($Group in $Groups){

    #Store all members of current group
    $users = Get-MgGroupMember -GroupID $Group.id

    #Store members information
    [string]$MemberNames
    [array]$UserData = $users.AdditionalProperties 
    [string]$MemberUPNs = $UserData.userPrincipalName -join ", "
    
    #Add group and member information to report
    $ReportLine = [PSCustomObject][Ordered]@{  
        "Group Name"             = $Group.displayName
        "Group Members"          = $MemberUPNs 
    }
    $Report.Add($ReportLine)
}

# Export report to CSV
$Report | Export-CSV -NoTypeInformation $CSVFilePath

Clear-Host
