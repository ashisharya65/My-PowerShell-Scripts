
<#
    .SYNOPSIS
        PowerShell Script to Set the Primary User name of an Intune Device
        
    .DESCRIPTION
        With this script we will be setting the Primary username of an Intune device as per the User Principal name of our choice.
        This script uses the Microsoft Graph (REST) API.
        
        This script checks for the environment variable for your Azure AD registered app are already set up on your local machine or not. If they are not there 
        then it will prompt you to provide them so that it will create them on your machine as thesee variables are mandatory for successful execution
        of this script.

        This script also checks and if not found,installs the MSAL.PS powershell module which is used to get the access token to interact with MS Graph API.
        
    .NOTES
        Author: Ashish Arya
        Date: 24 Jan 2023
#>

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
            Write-Host "Unable to set the $($EnvtVar.Name) environment value." -foreground 'Red'
        }
        
    }
}

Function Get-AuthToken {
    <#
    .SYNOPSIS
    This function uses the Azure AD app details which in turn will help to get the access token to interact with Microsoft Graph API.
    .DESCRIPTION
    This function uses the Azure AD app details which in turn will help to get the access token to interact with Microsoft Graph API.
    .EXAMPLE
    Get-AuthToken
    .NOTES
    NAME: Get-AuthToken
    #>

    #Below are the details of Azure AD app:
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

###################################################################
Function Get-Win10IntuneManagedDevice {

    <#
    .SYNOPSIS
    This gets information on Intune managed devices
    .DESCRIPTION
    This gets information on Intune managed devices
    .EXAMPLE
    Get-Win10IntuneManagedDevice
    .NOTES
    NAME: Get-Win10IntuneManagedDevice
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
   
        $Resource = "deviceManagement/managedDevices?`$filter=deviceName eq '$($deviceName)'"
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)" 
    
        (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).value        
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

###################################################################
Function Get-AADUser() {

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
        $Property
    )
    
    # Defining Variables
    $graphApiVersion = "v1.0"
    $User_resource = "users"
        
    # try {
            
    if ($userPrincipalName -eq "" -or $null -eq $userPrincipalName) {
            
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

###################################################################
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

###################################################################
Function Set-IntuneDevicePrimaryUser {

    <#
    .SYNOPSIS
    This updates the Intune device primary user
    .DESCRIPTION
    This updates the Intune device primary user
    .EXAMPLE
    Set-IntuneDevicePrimaryUser
    .NOTES
    NAME: Set-IntuneDevicePrimaryUser
    #>
    
    [cmdletbinding()]
    
    param
    (
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $IntuneDeviceId,
        [parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        $userId
    )
    $graphApiVersion = "beta"
    $Resource = "deviceManagement/managedDevices('$IntuneDeviceId')/users/`$ref"
    
    Try {
            
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
    
        $userUri = "https://graph.microsoft.com/$graphApiVersion/users/" + $userId
    
        $id = "@odata.id"
        $JSON = @{ $id = "$userUri" } | ConvertTo-Json -Compress
    
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"
    
    }
    Catch {
            $ex = $_.Exception
            $errorResponse = $ex.Response.GetResponseStream()
            $reader = New-Object System.IO.StreamReader($errorResponse)
            $reader.BaseStream.Position = 0
            $reader.DiscardBufferedData()
            $responseBody = $reader.ReadToEnd();
            Write-Host "Response content:`n$responseBody" -f Red
            Write-Error "Request to $Uri failed with HTTP Status $($ex.Response.StatusCode) $($ex.Response.StatusDescription)"
            throw "Set-IntuneDevicePrimaryUser error"
    }
        
    
}
###################################################################

# Checking if the environment variables for the Azure AD app are created or not
If ($null -eq (Get-ChildItem env: | Where-Object { $_.Name -like "Azure*" })) {
    Write-Host "The environment variables are not created." -ForegroundColor "Yellow"
    Write-Host "Hence creating..." -ForegroundColor "Yellow"

    try {
        Set-EnvtVariables
    }
    catch {
        Write-Host "Unable to create the environment variables." -ForegroundColor "Red"
        break;
    }
}
Else {
    Write-Host
    Write-Host "The Environment variables are already created." -ForegroundColor "Green"
}

###################################################################

# Getting the Access token to connect to Graph API.
$authToken = Get-AuthToken

###################################################################

# Prompt for Devicename
Write-Host
$DeviceName = Read-Host -prompt "Enter the Intune Device name"
$Device = Get-Win10IntuneManagedDevice -deviceName $DeviceName

###################################################################

# Prompt for User principal name
Write-Host
$UserUPN           = Read-Host -prompt "Enter the user UPN whom you want to set as Primary user on the Intune device $Devicename"
$FinalPrimaryUser  = Get-AADUser -userPrincipalName $UserUPN
###################################################################

#Checking and if not found, setting the provided user as the current primary user
$FinalPrimaryUserId = $FinalPrimaryUser.Id
$CurrentPrimaryUserId = Get-IntuneDevicePrimaryUser -deviceId $Device.id
If ($CurrentPrimaryUserId -eq $FinalPrimaryUserId) {
    Write-Host "`nThe user $($FinalPrimaryUser.displayName) is already set as Primary username on $DeviceName device.`n" -ForegroundColor "Cyan" 
}
Else {
    Set-IntuneDevicePrimaryUser -IntuneDeviceId $Device.id -userId $FinalPrimaryUserId -ErrorAction 'Stop'
    Write-Host "`nThe user $($FinalPrimaryUser.displayName) has been set as Primary username on $DeviceName device.`n" -ForegroundColor 'Green'
}

############################################################################# END ##############################################################################
