<#
    .Synopsis
    Script to disable the hotspot using PowerShell

    .Description
    PowerShell Code Snippet to disable the hotspot on a Windows 10 Machine.

    .Notes
    Author : Ashish Arya
    Date   : 16 June 2022
    
#>

$RegKey = @{
    "Path" = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Network Connections"
    "Name" = "NC_ShowSharedAccessUI"
    "PropertyType" = "DWORD"
    "Value" = "0"
}

New-ItemProperty @RegKey
