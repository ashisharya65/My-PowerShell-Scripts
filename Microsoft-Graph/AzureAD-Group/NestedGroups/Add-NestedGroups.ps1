<#
.SYNOPSIS
    This script adds a member group to a parent group in Microsoft Azure Active Directory by reading data from a CSV file.

.DESCRIPTION
    The script connects to Microsoft Graph using Entra ID credentials stored in environment variables. It checks for the existence of required environment variables and ensures they match expected values. The script logs all activities, including any errors encountered during execution, to a specified log file. It then reads group membership details from a CSV file and adds the specified member group to the parent group in Azure AD.

.PARAMETER Csvfilepath
    The path to the CSV file that contains the group membership information. The CSV file should have columns for MemberGroupName and ParentGroupName.

.PARAMETER LogFilePath
    The path to the log file where the script's execution details will be recorded. If not provided, a default path under ProgramData will be used.

.FUNCTION Write-Log
    Logs messages to a specified log file with a timestamp and log level (Info or Error). 

.FUNCTION Check-EnvironmentVariables
    Verifies that the required Azure environment variables (Azure_CLIENT_ID, Azure_TENANT_ID, Azure_CLIENT_SECRET) are present and match the expected values.

.EXAMPLE
    .\Add-NestedGroups.ps1 -Csvfilepath "C:\Path\To\Groups.csv"
    Runs the script with a specified CSV file to add member groups to parent groups in Azure AD.

.EXAMPLE
    .\Add-NestedGroups.ps1 -Csvfilepath "C:\Path\To\Groups.csv" -LogFilePath "C:\Logs\MyScript.log"
    Runs the script with a specified CSV file and logs execution details to a custom log file.

.NOTES
    - The script requires the Microsoft.Graph module to be installed and imported.
    - Ensure that the Azure environment variables (Azure_CLIENT_ID, Azure_TENANT_ID, Azure_CLIENT_SECRET) are set before running the script.
    - The script creates a log file if it does not exist and appends all execution details, including any errors.

#>

[cmdletbinding()]
param(
    [parameter(mandatory)] $Csvfilepath,
    [string] $LogFilePath = "$($env:ProgramData)\Microsoft\IntuneScripts\Logs\NestedGroup.log"
)

# Function for logging
Function Write-Log {
    param(
        [parameter(mandatory)]
        [ValidateSet('Info','Error')]
        [String] $Level,
        
        [Parameter(mandatory)]
        [string] $Message
    )
    $CurrentDate = Get-Date -format "dd-MM-yyyy hh:mm:ss"
    $logmessage = "$($CurrentDate) [$Level] - $Message"
    Add-Content -path $LogFilePath -Value $logmessage -force
}

# Azure AD App details
Function Check-EnvironmentVariables {
    [cmdletbinding()]
    param(
        [parameter(mandatory)] $ExpectedApplicationId,
        [parameter(mandatory)] $ExpectedTenantId,
        [parameter(mandatory)] $ExpectedClientSecret
    )

    # Retrieve the environment variables
    $ApplicationId = [Environment]::GetEnvironmentVariable("Azure_CLIENT_ID")
    $TenantID = [Environment]::GetEnvironmentVariable("Azure_TENANT_ID")
    $ClientSecret = [Environment]::GetEnvironmentVariable("Azure_CLIENT_SECRET")
    
    # Check if all environment variables exist and match the expected values
    if (($ApplicationId -eq $ExpectedApplicationId) -and ($TenantID -eq $ExpectedTenantId) -and ($ClientSecret -eq $ExpectedClientSecret)) {
        return $true
    } else {
        return $false
    }
}

if(-not(Test-Path $LogFilePath)){

    try {
        New-Item -path $LogFilePath -Itemtype 'File' -force -erroraction 'Stop'| Out-Null
        Write-Log -Level 'Info' -Message "Script executed started."
        Write-Log -Level 'Info' -Message "Successfully created the log file at $($LogFilePath) location."   
    }
    catch {
        $err = $_.Exception.Message
        Write-Log -Level 'Error' -Message "Unable to create both logfolder and log file : $err."
    }
}

# Checking if Environment variables and their with the expected values or not
Try {    
    if (Check-EnvironmentVariables){
        Write-Log -Level "Info" -Message "All environment variables exist and have the expected values."
        $ClientSecretCredential = New-Object -TypeName 'System.Management.Automation.PSCredential' -ArgumentList $ApplicationId, $ClientSecret -erroraction 'Stop'
    }
    else {
        Write-Log -Level "Error" -Message "One or more environment variables are missing or do not have the expected values. Please correct the values."
        Write-Log -Level "Info" -Message "Hence, exiting the script."
        Exit
    }

}
Catch {
    $err = $_.Exception.Message
    Write-Log -Level "Error" -Message "Unable to check if environment variables has the expected values or not: $err."
    Write-Log -Level "Info" -Message "Exiting the script."
    Exit
}

# Connecting to Microsoft Graph
Try {
    Connect-MgGraph -TenantId $TenantID -ClientSecretCredential $ClientSecretCredential -erroraction 'Stop'| Out-Null
    Write-Log -Level 'Info' -Message "Successfully connected to Microsoft Graph."
}
Catch{
    $err = $_.Exception.Message
    Write-Log -Level 'Error' -Message "Unable to connect to Microsoft Graph: $err."
}


# Getting all the data from the Csv file
$AllData = Import-Csv $Csvfilepath
Foreach($data in $AllData){
    
    $MemberGroup = $data.MemberGroupName
    $ParentGroup = $data.ParentGroupName

    $MemberGroupId = (Get-MgGroup -filter "displayName eq '$MemberGroup'").id
    $ParentGroupId = (Get-MgGroup -filter "displayName eq '$ParentGroup'").id        
    Try{
        $params = @{
            "@odata.id" = "https://graph.microsoft.com/v1.0/directoryObjects/$($MemberGroupId)"
        }
        New-MgGroupMemberByRef -GroupId $ParentGroupId -BodyParameter $params -erroraction 'Stop'
        Write-Host "The $($MemberGroup) group was successfully added as member to $($ParentGroup) group." -ForegroundColor 'Green'
    }
    Catch{
        $err = $_.Exception.Message
        Write-Log -Level 'Error' -Message "Unable to add $($MemberGroup) group as member to the $($ParentGroup) group : $err."
    }
}

Write-Log -Level 'Info' -Message "Script executed ended."
