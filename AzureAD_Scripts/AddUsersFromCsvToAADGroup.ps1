$Users = Import-Csv "C:\Users\Intune.Test\Downloads\Users.csv"
$count = $null
$GroupObjectID = "Group Object ID"

ForEach ($User in $Users) {
    $count = $count + 1
    $UserObjectid  = (Get-AzureADUser -Filter "UserPrincipalName eq '$($User.UPN)'").objectid
    Add-AzureADGroupMember -objectid $GroupObjectID -RefObjectId $UserObjectid
    write-host "$($count). Added the user $(($User.UPN -split "@")[0]) to the Group name."
}
