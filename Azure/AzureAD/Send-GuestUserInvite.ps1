
<#
.SYNOPSIS
    Send Guest user access invitation to External AzureAD user and add that guest account to an Azure AD group.

.DESCRIPTION
    This script will be used to send the guest user access invitation to the External AzureAD user's email addresses.
    This will also gonna add the same guest account to the concerned Azure AD group.

    Below are the prerequisites for successfully executing this script - 
    * Install AzureAD powershell module.
    * Install Azure VPN Client from Microsoft Store (https://apps.microsoft.com/store/detail/azure-vpn-client/9NP355QT2SQB).

.EXAMPLE
    .\SendGuestUserInvite.ps1 -ExternalEmailAddress <Your external Azure AD account email Address>

.PARAMETER ExternalEmailAddress
    External user's email address which will be used to set up the Guest user access and also on which the invitation email will be sent. 

.PARAMETER GroupName
    The Azure AD Group where the Guest account of external user will be added.

.PARAMETER GroupObjID
    The object id of the Azure AD group.

.PARAMETER UserObjectID
    The object id of the Guest user.

.PARAMETER AzureVPNClientFolder
    The actual directory path of Azure VPN client app folder.

.INPUTS
    External AzureAD user's Email address is required to be entered once you are running the script.
    The AzureAD group where the concerned external user's guest account will be added.
    
.OUTPUTS
    None

.NOTES
    Version       : 1.0
    Author        : Ashish Arya (https://github.com/ashisharya65)
    Date          : 10 Oct 2022

#>

# Function to send Guest User invitation.
Function Send-GuestUserInvite {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [string] $ExternalEmailAddress,
        [Parameter(Mandatory)]
        [string] $GroupName,
        [string] $GroupObjID,
        [string] $UserObjectID
    )

    # This will capitalize the first letter from user's first name and last name
    $InvitedUserDisplayName = [cultureinfo]::GetCultureInfo("en-US").TextInfo.ToTitleCase($CoforgeEmailAddress.split("@")[0].replace(".", " "))

    #Sending the invite to the guest user
    Try {
        
        New-AzureADMSInvitation -InvitedUserEmailAddress $CoforgeEmailAddress -InvitedUserDisplayName $InvitedUserDisplayName `
            -SendInvitationMessage $True -InviteRedirectUrl "http://myapps.microsoft.com" -ErrorAction SilentlyContinue
        
        Write-Host "$InvitedUserDisplayName external Azure AD user account has been added as a guest user and above are its details."  -f Green
        Write-Host
    }
    Catch {
        $_.Exception.Message
    }

    ########################################################################################################
        
    # Adding the guest user to the concerned Azure AD group #

    ########################################################################################################

    $GroupObjID = (Get-AzureADGroup -SearchString $GroupName).ObjectId
    $UserObjectID = (Get-AzureADUser -SearchString $InvitedUserDisplayName | Where-Object {$_.usertype -eq "Guest" }).Objectid

    try {

        If ($null -ne $UserObjectID) {
            Add-AzureADGroupMember -ObjectID $GroupObjID -RefObjectId $UserObjectID -ErrorAction SilentlyContinue
            Write-Host "$($InvitedUserDisplayName) external user's guest account was also added to the $($GroupName) group." -ForegroundColor 'Green'
        }
    }
    catch {
        $_.Exception.Message
    }

}

# Function to check Azure VPN client installation.
Function Test-VPNClientInstallation {
    [CmdletBinding()]
    param(
        $AzureVPNClientFolder = "$env:LOCALAPPDATA\Packages\Microsoft.AzureVpn_8wekyb3d8bbwe"
    )

    If(Test-Path -Path $AzureVPNClientFolder){
        return $true
    }
    Else{
        return $false
    }  
}

# To check if Azure AD Powershell module & Azure VPN client app are installed or not. 
# If they are installed only then the script will execute otherwise it will exit.

Write-Host "Checking for AzureAD module..."

$AadModule = Get-Module -Name "AzureAD" -ListAvailable

if (($null -eq $AadModule) -and (Test-VPNClientInstallation -eq $false)) {

    Write-Host "AzureAD Powershell module & Azure VPN client are not installed..." -f Red
    Write-Host "Install the module by running 'Install-Module AzureAD -Scope CurrentUser' command" -f Yellow
    Write-Host "Install the Azure VPN client from Microsoft Store (https://apps.microsoft.com/store/detail/azure-vpn-client/9NP355QT2SQB)." -f Yellow
    Write-Host "Script can't continue now..." -f Red
    Write-Host 
    exit
}Else{
    Write-Host "AzureAD Powershell module & Azure VPN client app are already installed..." -f Green
    Write-Host "Connecting to Azure AD.." -f Yellow
    Start-Sleep 2
    Connect-AzureAD | Out-Null
    Start-Sleep 2
    Send-GuestUserInvite
}
