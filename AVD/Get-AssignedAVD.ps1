<#
  .SYNOPSIS
  Powershell script to get the assigned AVD name.
  
  .DESCRIPTION
  This script prompts for the UPN and displays all the AVDs (which are assigned to the user) from the all the hostpools.
  
  .PARAMETER userUPN
  The resource group name where both VNets will reside.

  .PARAMETER subscription
  The name of your Azure subscription.
  
  .PARAMETER tenantid
  The id for your Azure tenant.
  
  .INPUTS
  Prompts for user's user principal name, subscription name & tenantid.

  .OUTPUTS
  System.Collections.Generic.List. You will be getting all the AVD names from all the hostpools which are assigned to the user.
  
  .EXAMPLE
  PS> .\Get-AssignedAVD.ps1

  .NOTES
    Author : Ashish Arya
    Date   : 08-Feb-2024
#>

# Function to handle error
function Handle-Error {
    param([string]$Errormessage)
    Write-Host $Errormessage -ForegroundColor "Red"

}

# Function to get the AVD assigned to the user
function Get-AssignedAVD {
    [cmdletbinding()]
    Param(
        [string][Parameter(Mandatory, HelpMessage = "Enter the user's userpricipalname")]$userUPN,
        [string][Parameter(Mandatory, HelpMessage = "Enter the Azure subscription name")]subscription,
        [string][Parameter(Mandatory, HelpMessage = "Enter the Azure tenant id")]$tenantid
    )

    # Verifying if AZ and AVD PowerShell modules are installed or not
    @("Az", "Az.DesktopVirtualization") | ForEach-Object {
        If ($null -eq $(Get-InstalledModule -Name $_)) {
            Write-Host "$_ PowerShell module is not installed on your machine. Hence installing it."
            Install-Module $_ -Scope 'CurrentUser' -Force
        }
    }

    # Connecting to Azure Subscription
    if(!([string]::IsNullOrEmpty($Connected))){
        Write-host "`nYou are already connected to your Azure tenant." -f "DarkGreen"
    }
    else{
        Write-host "`nConnecting to Azure..." -ForegroundColor "DarkYellow"
        Try {
            $Connected = connect-Azaccount -Tenant $tenantid -Subscription $subscription -ea 'stop'# | Out-Null
            Write-Host "Successfully connected to your Azure tenant." -f 'DarkGreen'
        }
        Catch {
            Handle-Error -Errormessage $_.Exception.Message
            Break
        }
    }
    
    # Getting the host pools
    $hostpools = Get-AzWvdHostPool | Foreach-Object {
        [PSCustomObject]@{
            hostpool      = $_.name
            resourcegroup = ($_.id -split "/")[4]
        }
    }

    # Looping through all the host pool to fing the right AVD and print the Assigned user name
    $AVDList = [System.Collections.Generic.List[Object]]@()
    foreach ($Hp in $hostpools) {
        try {
            $AVDs = Get-AzWVDSessionHost -HostPoolName $Hp.hostpool -ResourceGroupName $Hp.resourcegroup -ea Stop
            Foreach ($AVD in $AVDs) {
                $AVDName = ($AVD.Name -split "/")[1]
                If ($userUPN -eq $AVD.AssignedUser) {
                    $AVDList.Add($AVDName) | Out-Null
                    Break
                }
            }
        }
        Catch {
            Handle-Error -Errormessage $_.Exception.Message
        }
    }
    return $AVDList
}

# Displaying all the assigned AVDs
$AllAVDs = Get-AssignedAVD
If ([string]::IsNullOrEmpty($AllAVDs)) {
    Write-Host "No AVDs are assinged to the $UserUPN user." -f "DarkYellow"
}
Else {
    Write-Host "`n#############################" -f "Cyan"
    Write-Host "`tAssigned AVDs" -f "DarkYellow"
    Write-Host "#############################`n" -f "Cyan"
    $AllAVDs | Foreach-Object {
        Write-Host " - $_" -f "DarkGreen"
    }
    Write-Host
}
