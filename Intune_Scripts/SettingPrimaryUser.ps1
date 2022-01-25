
<#
    This is a powershell script which will programmatically interact with Intune to set the Primary usernames of the Intune devices.

    Microsoft has built two authentication libraries over the years to interact with Microsoft Graph API:
        * Active Directory Authentication Library (ADAL)
        * Microsoft Authentication Library (MSAL).
        
    Microsoft has announced end of support timelines for ADAL,and no further feature development will take place on the library.
     
    Here is the link for reference:
    (https://techcommunity.microsoft.com/t5/azure-active-directory-identity/update-your-applications-to-use-microsoft-authentication-library/ba-p/1257363)
                
    This script is a modified version of one of the script from Dave Falkus famous Intune Samples Github repo. This uses the MSAL library
    instead of the ADAL library. The original script was using the ADAL library to get the access token.
        
    Here is the link of the original script:

    https://github.com/microsoftgraph/powershell-intune-samples/blob/master/ManagedDevices/Win10_PrimaryUser_Set.ps1
        
    The pre-requisites that we need before running this script are:
        * Azure AD Registration mentioning the App details in Get-AuthToken function
        * Microsoft.Graph.Intune Powershell module installed on your device
        * MSAL.PS PowerShell module installed on your device (Written by Jason Thompson (https://github.com/jasoth)

    Author : Ashish Arya (https://github.com/ashisharya65)

#>

#####################################################################################################################################

param(
    [parameter(Mandatory = $false)]
    $DeviceName,
    [parameter(Mandatory = $false)]
    $UserPrincipalName
)

#####################################################################################################################################

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
        ClientId     = 'Azure AD AppID'
        TenantId     = 'TenantID'
        ClientSecret = ('ClientSecret of Azure AD App' | ConvertTo-SecureString -AsPlainText -Force)
    }
    $auth = Get-MsalToken @authParams

    $authorizationHeader = @{
        Authorization = $auth.CreateAuthorizationHeader()
    }

    return $authorizationHeader

}
#####################################################################################################################################

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
    
        if ($deviceName) {
    
            $Resource = "deviceManagement/managedDevices?`$filter=deviceName eq '$deviceName'"
            $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)" 
    
                (Invoke-RestMethod -Uri $uri -Headers $authToken -Method Get).value
    
        }
    
        else {
    
            $Resource = "deviceManagement/managedDevices?`$filter=(((deviceType%20eq%20%27desktop%27)%20or%20(deviceType%20eq%20%27windowsRT%27)%20or%20(deviceType%20eq%20%27winEmbedded%27)%20or%20(deviceType%20eq%20%27surfaceHub%27)))"
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

#####################################################################################################################################

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

#####################################################################################################################################

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
    
    #try{
            
    $uri = "https://graph.microsoft.com/$graphApiVersion/$($Resource)"
    
    $userUri = "https://graph.microsoft.com/$graphApiVersion/users/" + $userId
    
    $id = "@odata.id"
    $JSON = @{ $id = "$userUri" } | ConvertTo-Json -Compress
    
    Invoke-RestMethod -Uri $uri -Headers $authToken -Method Post -Body $JSON -ContentType "application/json"
    
    #}
    <#    
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
    #>
}

#####################################################################################################################################
$authToken = Get-AuthToken

$Devices = Get-Win10IntuneManagedDevice

Foreach ($Device in $Devices) { 

    Write-Host "Device name:" $Device."deviceName" -ForegroundColor Cyan
    $IntuneDevicePrimaryUser = Get-IntuneDevicePrimaryUser -deviceId $Device.id 

    #Check if there is a Primary user set on the device already
    if ($null -eq $IntuneDevicePrimaryUser) {

        Write-Host "No Intune Primary User Id set for Intune Managed Device" $Device."deviceName" -f Red 

    }
    else {
        $PrimaryAADUser = Get-AADUser -userPrincipalName $IntuneDevicePrimaryUser 
            
        Write-Host "Intune Device Primary User:" $PrimaryAADUser.displayName       
    }

    #Get the objectID of the last logged in user for the device, which is the last object in the list of usersLoggedOn
    $LastLoggedInUser = ($Device.usersLoggedOn[-1]).userId
                       
    #Using the objectID, get the user from the Microsoft Graph for logging purposes
    $User = Get-AADUser -userPrincipalName $LastLoggedInUser
            
    #Check if the current primary user of the device is the same as the last logged in user
    if ($IntuneDevicePrimaryUser -ne $User.id) {

        #If the user does not match, then set the last logged in user as the new Primary User
        $SetIntuneDevicePrimaryUser = Set-IntuneDevicePrimaryUser -IntuneDeviceId $Device.id -userId $User.id
       
        #$SetIntuneDevicePrimaryUser
        if ($SetIntuneDevicePrimaryUser -eq "") {

            Write-Host "User"$User.displayName"set as Primary User for device '$($Device.deviceName)'..." -ForegroundColor Green

        }

    }
    else {
        
        #If the user is the same, then write to host that the primary user is already correct.
        Write-Host "The user '$($User.displayName)' is already the Primary User on the device..." -ForegroundColor Yellow

    }

    Write-Host

}

