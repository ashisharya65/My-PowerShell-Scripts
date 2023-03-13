
<#
    .SYNOPSIS
    Getting the Azure AD groups associated with users.
    
    .DESCRIPTION
    PowerShell script to add a user account as an owner to single AAD group.
    This script will prompt you to provide a regex pattern for group display names.
    Here we will be requiring a csv file as well.
    
    .NOTES
    Author : Ashish Arya
    Date   : 13-March-2023
#>

# RegEx pattern for filtering the Azure AD group with their names
$RegExPattern = Read-Host -prompt "Enter your RegEx pattern for Azure AD Group name"

# Declare Azure AD app details
$ApplicationId = $Env:Azure_CLIENT_ID
$TenantID = $Env:Azure_TENANT_ID
$ClientSecret = $Env:Azure_CLIENT_SECRET | ConvertTo-SecureString -AsPlainText -Force
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


$GroupInfo | Select UserName, Groups

