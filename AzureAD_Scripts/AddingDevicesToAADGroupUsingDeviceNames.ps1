<#
    Adding AzureAD managed devices to the Azure AD group using a text file storing devices names.
#>

$Devices = Get-content "C:\Users\Ashish.Arya\Desktop\devicelist.txt"
$count = $null
$GroupObjectID = "Group Object ID"
ForEach ($Device in $Devices) {
    $count = $count + 1
     $ObjId  = (Get-AzureADDevice -SearchString $Device).ObjectId
     Add-AzureADGroupMember -objectid $GroupObjectID -RefObjectId $ObjId
     write-host "$($count). Added the device $($Device) to the device group."
}

