<#
  .SYNOPSIS
  Create Azure VNets with Vnet Peering.
  
  .DESCRIPTION
  This script will create the Azure VNets in a resource group and also set up the VNet peering between them.

  .PARAMETER rgName
  The resource group name where both VNets will reside.

  .PARAMETER loc
  The location of the resource group.
  
  .INPUTS
  Prompts for the resource group name and its location.

  .OUTPUTS
  System.String. You will get the confirmation once the VNets and their peerings are created.
  
  .EXAMPLE
  PS> .\CreateVnetWithVnetPeering.ps1

  .EXAMPLE
  PS> .\CreateVnetWithVnetPeering.ps1 -rgname "Rg01" -loc "westus"

  .NOTES
  Author: Ashish Arya
  Date: 07-Feb-2024
#>

param(
    [Parameter(Mandatory, HelpMessage = "Enter the resource group name")]$rgName,
    [Parameter(Mandatory, HelpMessage = "Enter the location for resource group")]$loc
)

# Function to handle errors
function Handle-Error {
    param([string] $ErrorMessage)
    Write-Host $ErrorMessage -ForegroundColor Red
}

# Function to create a resource group
function New-RG {
    param([string]$ResourceGroupName, [string]$Location)
    try {
        $rgprop = New-AzResourceGroup -Name $ResourceGroupName -Location $Location -ErrorAction Stop
        Write-Host "$($rgprop.ResourceGroupName) resource group has been successfully created." -ForegroundColor DarkGreen
    }
    catch {
        Handle-Error -ErrorMessage $_.Exception.Message
    }
}

# Function to create a virtual network
function New-VirtualNetwork {
    param(
        [string]$Name, 
        [string]$ResourceGroupName, 
        [string]$Location, 
        [string]$AddressPrefix, 
        [string]$SubnetName, 
        [string]$SubnetAddressPrefix
    )
    try {
        $SubnetConfig = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetAddressPrefix
        $Vnet = New-AzVirtualNetwork -Name $Name -ResourceGroupName $ResourceGroupName -Location $Location -AddressPrefix $AddressPrefix -Subnet $SubnetConfig -ErrorAction Stop
        Write-Host "$Name virtual network has been successfully created." -ForegroundColor DarkGreen
        return $Vnet
    }
    catch {
        Handle-Error -ErrorMessage $_.Exception.Message
    }
}

# Function to create a virtual network peering
function New-VirtualNetworkPeering {
    param(
        [string]$Name, 
        [Microsoft.Azure.Commands.Network.Models.PSVirtualNetwork]$VirtualNetwork1, 
        [Microsoft.Azure.Commands.Network.Models.PSVirtualNetwork]$VirtualNetwork2
    )
    try {
        Add-AzVirtualNetworkPeering -Name $Name -VirtualNetwork $VirtualNetwork1 -RemoteVirtualNetworkId $VirtualNetwork2.Id | Out-Null
        Write-Host "VNet peering has been successfully created from $($VirtualNetwork1.Name) to $($VirtualNetwork2.Name)." -ForegroundColor DarkGreen
    }
    catch {
        Handle-Error -ErrorMessage $_.Exception.Message
    }
}

# Creating ResourceGroup
New-RG -ResourceGroupName $rgName -Location $loc

# Creating VNET1 with subnet config
$Vnet1 = New-VirtualNetwork -Name "Vnet1" -ResourceGroupName $rgName -Location $loc -AddressPrefix "10.0.0.0/16" -SubnetName "Web" -SubnetAddressPrefix "10.0.0.0/24"

# Creating VNET2 with subnet config
$Vnet2 = New-VirtualNetwork -Name "Vnet2" -ResourceGroupName $rgName -Location $loc -AddressPrefix "20.0.0.0/16" -SubnetName "DB" -SubnetAddressPrefix "20.0.0.0/24"

# Peering VNET1 to VNET2
New-VirtualNetworkPeering -Name 'vnet1Tovnet2Peering' -VirtualNetwork1 $Vnet1 -VirtualNetwork2 $Vnet2

# Peering VNET2 to VNET1
New-VirtualNetworkPeering -Name 'vnet2Tovnet1Peering' -VirtualNetwork1 $Vnet2 -VirtualNetwork2 $Vnet1
