
<#

.SYNOPSIS
    Script to get the Uninstall Registry Keys for Installed applications.
.DESCRIPTION
    This is a PowerShell script which will help you to find the uninstall registry keys for installed applications which are required while 
    testing applications uninstallation.
.NOTES
    Author: Ashish Arya
    Date : 20-March-2023
#>


$productNames = @("*")
$UninstallKeys = @('HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall',
    'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall'
)
$results = foreach ($key in (Get-ChildItem $UninstallKeys)) {
    foreach ($product in $productNames) {
        if ($key.GetValue("DisplayName") -like "$product") {
            [pscustomobject]@{
                KeyName         = $key.Name.split('\')[-1]
                DisplayName     = $key.GetValue("DisplayName")
                UninstallString = $key.GetValue("UninstallString")
                Publisher       = $key.GetValue("Publisher")
            }
        }
    }
}

$results | Format-List *
