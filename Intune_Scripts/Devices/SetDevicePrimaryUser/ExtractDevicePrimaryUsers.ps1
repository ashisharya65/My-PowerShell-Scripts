
<#
    .SYNOPSIS
        PowerShell script to get all the Intune devices details like devicenames & Primary usernames.
    
    .DESCRIPTION
        This script will extract a CSV report storing the Intune devices' names and their primary usernames.

        This script checks for the environment variable for your Azure AD registered app are already set up on your local machine or not. If they are not there 
        then it will prompt you to provide them so that it will create them on your machine as thesee variables are mandatory for successful execution
        of this script.

        This script also checks and if not found,installs the MSAL.PS powershell module which is used to get the access token to interact with MS Graph API.
    
    .NOTES
        Author : Ashish Arya
        Date   : 22 May 2023
#>

#####################################################################################################################################
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
#####################################################################################################################################
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
    $MSALPSModule = Get-InstalledModule -Name 'MSAL.PS' 

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
        ClientId     = [System.Environment]::GetEnvironmentVariable("AZURE_CLIENT_ID")
        TenantId     = [System.Environment]::GetEnvironmentVariable("AZURE_TENANT_ID")
        ClientSecret = ([System.Environment]::GetEnvironmentVariable("AZURE_CLIENT_SECRET") | ConvertTo-SecureString -AsPlainText -Force)
    }
    $auth = Get-MsalToken @authParams

    $authorizationHeader = @{
        Authorization = $auth.CreateAuthorizationHeader()
    }

    return $authorizationHeader

}
#####################################################################################################################################
Function Get-W10IntuneManagedDevice {

    <#
        .SYNOPSIS
        This gets information on Intune managed devices
        .DESCRIPTION
        This gets information on Intune managed devices
        .EXAMPLE
        Get-W10IntuneManagedDevice
        .NOTES
        NAME: Get-W10IntuneManagedDevice
    #>
    
    [cmdletbinding()]
    
    param
    (
        [parameter(Mandatory = $false)]
        [ValidateNotNullOrEmpty()]
        [string]$deviceName
    )
        
    $graphApiVersion = "beta"    
    try {
        
        # $Resource = "deviceManagement/managedDevices"
        $Resource = "deviceManagement/managedDevices"
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)" 
                
        #Adding the Paging to the Microsoft Graph API request
        $DevicesResponse = (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get)
        $Devices = $DevicesResponse.value
        $DevicesNextLink = $DevicesResponse."@odata.nextLink"

        while ($null -ne $DevicesNextLink) {
            $DevicesResponse = (Invoke-RestMethod -Uri $DevicesNextLink -Headers $authToken -Method Get)
            $DevicesNextLink = $DevicesResponse."@odata.nextLink"
            $Devices += $DevicesResponse.value
        }
        return $Devices
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
        throw "Get-IntuneManagedDevices error"
    }
}
#####################################################################################################################################
Function Get-IntuneDevicePrimaryUser {

    <#
        .SYNOPSIS
        This lists the Intune device primary user
        .DESCRIPTION
        This lists the Intune device primary user
        .EXAMPLE
        Get-IntuneDevicePrimaryUser
        .NOTES
        NAME: Get-IntuneDevicePrimaryUser
    #>
    
    [cmdletbinding()]
    
    param
    (
        [Parameter(Mandatory = $true)]
        [string] $deviceId
    )
    $graphApiVersion = "beta"
    $Resource = "deviceManagement/managedDevices"
    $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)" + "/" + $deviceId + "/users"
    
    try {
            
        $primaryUser = Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get
    
        return $primaryUser.value."id"
            
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
        throw "Get-IntuneDevicePrimaryUser error"
    }
}
#####################################################################################################################################
Function Get-AADUser {

    <#
        .SYNOPSIS
        This function is used to get AAD Users from the Graph API REST interface
        .DESCRIPTION
        The function connects to the Graph API Interface and gets any users registered with AAD
        .EXAMPLE
        Get-AADUser
        Returns all users registered with Azure AD
        .EXAMPLE
        Get-AADUser -userPrincipleName user@domain.com
        Returns specific user by UserPrincipalName registered with Azure AD
        .NOTES
        NAME: Get-AADUser
    #>
    
    [cmdletbinding()]
    
    param
    (
        $userPrincipalName,
        $id,
        $Property
    )
    
    # Defining Variables
    $graphApiVersion = "v1.0"
    $User_resource = "users"
        
    if ($id) {
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($User_resource)/$($id)"
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).userPrincipalName
    }            
    elseif ($userPrincipalName -eq "" -or $null -eq $userPrincipalName) {
            
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($User_resource)"
            (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
            
    }
    else {
                
        if ($Property -eq "" -or $null -eq $Property) {
    
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($User_resource)/$userPrincipalName"
            Write-Verbose $uri
            Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get
    
        }
    
        else {
    
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($User_resource)/$userPrincipalName/$Property"
            Write-Verbose $uri
                (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).Value
    
        }
    
    }
        
}
#####################################################################################################################################

#Checking if the environment variables for the Azure AD app are created or not
If ($null -eq (Get-ChildItem env: | Where-Object { $_.Name -like "Azure_*" })) {
    Write-Host "`nThe environment variables for your Azure AD app are not created. Hence creating..." -ForegroundColor "Yellow"
    Set-EnvtVariables
}

#CSV FilePath
$CSVFilePath = "$($PSScriptRoot)\" + "$($myInvocation.myCommand.name.split('.')[0])" + ".csv"

# Checking if authToken exists before running authentication
If ($global:authToken) {

    # Setting DateTime to Universal time to work in all timezones
    $DateTime = (Get-Date).ToUniversalTime()

    # If the authToken exists checking when it expires
    $TokenExpires = ($authToken.ExpiresOn.datetime - $DateTime).Minutes

    If ($TokenExpires -le 0) {

        Write-Host "Authentication Token expired" $TokenExpires "minutes ago. Getting the authentication token again..." -ForegroundColor 'Yellow'
        Start-Sleep 1

        $global:authToken = Get-AuthToken 

    }
}
# Authentication doesn't exist, calling Get-AuthToken function
Else {

    # Getting the authorization access token
    Write-Host "Getting the authentication token..." -ForegroundColor 'Yellow'
    Start-Sleep 1
    $global:authToken = Get-AuthToken 

}

Write-Host "`nCollating all Intune devices local IP addresses & their Primary users.." -ForegroundColor 'Cyan'
$Report = Get-W10IntuneManagedDevice | Foreach-Object { 
    [PSCustomObject][Ordered]@{
        Name        = $_.deviceName
        PrimaryUser = Get-AADUser -id (Get-IntuneDevicePrimaryUser -deviceId $_.id)
    }
} | Format-Table -Autosize

Write-Host ("`nExporting the Intune Device IP address & Primary username details to a CSV report...") -ForegroundColor 'Green'
$Report | Export-CSV -NoTypeInformation $CSVFilePath

############################################################################# END ##############################################################################
