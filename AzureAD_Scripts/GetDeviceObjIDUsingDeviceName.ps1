<#
    Getting AzureAD Devices ObjectID using their device names stored in a text file.
    Author : Ashish Arya
    Github : @ashisharya65
#>

Connect-AzureAD | out-null

$Devices = Get-content "C:\Users\Ashish.Arya\Desktop\devicelist.txt"

ForEach ($Device in $Devices) {
    $object = [PSCustomObject]@{
        devicename = $Device
        ObjId      = (Get-AzureADDevice -SearchString $Device).ObjectId
    }
    [Array] $AllDevices += $object
}

$AllDevices

