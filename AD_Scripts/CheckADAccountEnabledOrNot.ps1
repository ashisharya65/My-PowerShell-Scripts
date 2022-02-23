
<#
    Check whether AD users are enabled or not.
    
    Here we have used the userlist text file which stores the user's user principal name (UPN).
    
    Author: Ashish Arya
    Github: @ashisharya65
#>

$users = get-content "C:\Users\Ashish.Arya\Desktop\userlist.txt"

$users | foreach-object {

    [PSCustomObject]@{

        UPN = $_
        Enabled = (Get-ADUser -identity $_.split("@")[0]).Enabled

    }

} | Sort UPN, Enabled

