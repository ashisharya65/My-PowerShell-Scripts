<#
    .SYNOPSIS
        Removing the Azure AD registered application.
    .DESCRIPTION
        With this script you can remove any of your Azure AD registered application.
    .NOTES
       Author : Ashish Arya
       Date   : 11-April-2023
#>

param(
    [Parameter(Mandatory = $False)]
    [Switch] $StayConnected = $False
)

# Checking and Verifying if the latest Microsoft.Graph Module is installed or not
$Latest = Find-Module -Name 'Microsoft.Graph' -AllVersions -AllowPrerelease | select-Object -First 1
$Current = Get-InstalledModule | Where-Object { $_.Name -eq "Microsoft.Graph" }
If ($Latest.version -gt $Current.version) {
    Try {
        Update-Module -Name 'Microsoft.Graph' -RequiredVersion $Latest.version -AllowPrerelease
        Write-Host "Microsoft Graph PowerShell module updated successfully to" $Latest.Version -ForegroundColor 'Green'
    }
    Catch {
        Write-Host "Unable to update Microsoft Graph PowerShell module" -ForegroundColor 'Red'
    }
}
Elseif ($null -eq $Current.version) {
    Try {
        Write-Host "The Microsoft Graph PowerShell module is not installed. Hence, installing it..." -ForegroundColor "Yellow"
        Install-Module 'Microsoft.Graph' -scope 'CurrentUser' -force
    }
    Catch {
        Write-Host "Unable to install the Microsoft Graph PowerShell module" -ForegroundColor 'Red'
    }

}
Else {
    Write-Host "Latest version of Microsoft Graph is not newer than the current" -ForegroundColor 'Yellow'
}

#Prompt for your Azure AD app name
$DisplayName = Read-Host -prompt "Enter your Azure AD App name"

#Connecting to Microsoft Graph with right permissions
Connect-MgGraph -Scopes "Application.ReadWrite.All User.Read" -UseDeviceAuthentication -ErrorAction 'Stop'

#Getting the app details
$AzureADApp = Get-MgApplication -Filter "DisplayName eq '$DisplayName'"

#Removing the Azure AD registered app and move it to the deleted items
Try {
    Remove-MgApplication -ApplicationId $AzureADApp.id -ErrorAction 'Stop'
}
Catch {
    Write-Host $_.Exception.Message -ForegroundColor 'Red'
}

#Permanently removing the Azure Ad registered app from the deleted items
Try {
    Remove-MgDirectoryDeletedItem -DirectoryObjectId $AzureADApp.id -ErrorAction 'Stop'
    Write-Host "`n$DisplayName application has been permanently removed from your Azure Ad tenant." -ForegroundColor 'Cyan'
}
Catch {
    Write-Host $_.Exception.Message -ForegroundColor 'Red'
}

#Disconnecting the session
If ($StayConnected -eq $False) {
    Disconnect-MgGraph | Out-Null
    Write-Host "`nDisconnected from Microsoft Graph`n" -ForegroundColor 'Green'
}
Else {
    Write-Host
    Write-Host "The connection to Microsoft Graph is still active. To disconnect, use Disconnect-MgGraph" -ForegroundColor 'Yellow'
}

################################################################## END #########################################################################
