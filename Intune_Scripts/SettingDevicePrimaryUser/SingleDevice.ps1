
<#
.SYNOPSIS
    PowerShell Script to Set the Primary User name of an Intune Device
.DESCRIPTION
    With this script we will be setting the Primary username of an Intune device as per the User Principal name of our choice,
.NOTES
    Author: Ashish Arya
    Date: 24 Jan 2023
#>


function Get-AuthToken {
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
        ClientId     = $Env:Azure_CLIENT_ID
        TenantId     = $Env:Azure_TENANT_ID
        ClientSecret = ($Env:Azure_CLIENT_SECRET | ConvertTo-SecureString -AsPlainText -Force)
    }
    $auth = Get-MsalToken @authParams

    $authorizationHeader = @{
        Authorization = $auth.CreateAuthorizationHeader()
    }

    return $authorizationHeader

}

###################################################################
function Get-Win10IntuneManagedDevice {

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
   
        $Resource = "deviceManagement/managedDevices?`$filter=deviceName eq '$deviceName'"
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
function Get-IntuneDevicePrimaryUser {

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
function Set-IntuneDevicePrimaryUser {

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
    
    try {
            
        $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
    
        $userUri = "https://graph.microsoft.com/$graphApiVersion/users/" + $userId
    
        $id = "@odata.id"
        $JSON = @{ $id = "$userUri" } | ConvertTo-Json -Compress
    
        Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"
    
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
        throw "Set-IntuneDevicePrimaryUser error"
    }
}
###################################################################

$authToken = Get-AuthToken

###################################################################

$DeviceName = Read-Host -prompt "Enter the Device name"
$Device = Get-Win10IntuneManagedDevice -deviceName $DeviceName

###################################################################

$UserUPN = Read-Host -prompt "Enter the user UPN whom you want to set as Primary user on the $Devicename"
$User = Get-AADUser -userPrincipalName $UserUPN

###################################################################

Try {
    #Checking if last logger in user is same as the current primary user
    $LastLoggedInUser = ($Device.usersLoggedOn[-1]).userId
    $CurrentPrimaryUser = Get-IntuneDevicePrimaryUser -deviceId $Device.id 
    If ($CurrentPrimaryUser -eq $LastLoggedInUser) {
        Write-Host "The user $($User.displayName) is already set as Primary username on $DeviceName" -ForegroundColor "Green"
    }
    Else {
        Set-IntuneDevicePrimaryUser -IntuneDeviceId $Device.id -userId $User.id
        Write-Host "The user $($User.displayName) is already set as Primary username on $DeviceName"
    }
}
Catch {
    Write-Host "Unable to update the primary username." -ForegroundColor 'Red'
}
###################################################################
