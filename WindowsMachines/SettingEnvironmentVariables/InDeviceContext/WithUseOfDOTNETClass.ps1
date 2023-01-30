
<#
   .SYNOPSIS 
   PowerShell Script to set your environment variables with your Azure AD app credentials in machine context.
   
   .DESCRIPTION
   This script will help you to set your Azure AD app components like client id, client secret and tenant id on your local machine (where you
   will be running this script) as environment variables. Here the script uses the System.Environment Dotnet class to set the environment
   variables in machine context.
   
   This script will prompt you for Client id, client secret and tenant id and after successful execution you will see the below fields set as the
   user environment variables with their corresponding values provided.
   
      a) AZURE_CLIENT_ID
      b) AZURE_CLIENT_SECRET
      c) AZURE_TENANT_ID
           
   .NOTES
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
        [string] $TenantId
   )    
   
   $EnvtVariables = @(
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
    )     
    
    Foreach($EnvtVar in $EnvtVariables){
        Try{
            [System.Environment]::SetEnvironmentVariable($EnvtVar.Name,$EnvtVar.Value,[System.EnvironmentVariableTarget]::Machine)
        }
        Catch{
            Write-Host "Unable to set the $($EnvtVar.Name) environment value." -foreground 'Red'
        }
    }
} 

Set-EnvtVariables
