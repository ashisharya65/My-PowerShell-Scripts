<#
   .Synopsis 
   PowerShell Script to set your environment variables with your Azure AD app credentials.
   
   .Description
   This script will help you to set your Azure AD app components like client id, client secret and tenant id on your local machine where you
   will be running this script.
   
   .Notes
   Author : Ashish Arya
   Date   : 25 Jan 2023

#>

Function Set-EnvtVariables{
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [string] $CliendId,
        [Parameter(Mandatory)]
        [string] $ClientSecret,
        [Parameter(Mandatory)]
        [string] $TenantId    )     $Regpath = "HKCU:\Environment"     $RegProperties = @(
    [PSCustomObject]@{
        Name = "AZURE_CLIENT_ID"
        Value = $CliendId
    },
    [PSCustomObject]@{
        Name = "AZURE_CLIENT_SECRET"
        Value = $ClientSecret
    },
    [PSCustomObject]@{
        Name = "AZURE_TENANT_ID"
        Value = $TenantId
    }
    )     Foreach($Reg in $RegProperties){
        try {
            New-ItemProperty -Path $Regpath -Name $Reg.Name -Value $Reg.Value | Out-Null
            Write-Host "The $($Reg.Name) Environment Variable has been created and set with $($Reg.Value) value."
        }
        catch {
            Write-Host "Unable to create the $($Reg.Name) Environment Variable."
        }
    }
}
