<#
  Script to find the users (mentioned in a text file) are active or not.
#>

$userlist = get-content "C:\Users\ashish.arya\Desktop\UPNList.txt"

$userlist | foreach-object {
    get-aduser $_ |
    Select-object Name, UserprincipalName, @{n = "Account Status"; E = { if (($_.Enabled -eq 'TRUE')) { 'Enabled' } Else { 'Disabled' } 
        } 
    }
} | Export-csv C:\Users\ashish.arya\Desktop\AccountStatus.csv
