################################################################################################################
<#
  * Renaming Intune Android Device names with naming convention "Android-SerialNumber".
  * Here we are filtering all the android devices using a devicelist having devicenames.
  
  Author : Ashish Arya
  Github : @ashisharya65
#>
################################################################################################################

#Getting All Android phones
$Devices = Get-IntuneManagedDevice | Get-MSGraphAllPages | Where-Object {($_.operatingSystem -eq "Android")}

#Getting the device list
$DeviceList = get-content "C:\Users\Intune.Test\OneDrive - Alzheimer's Society\Desktop\Devicename.txt"

#Filtering the devices with all the properties
$FilteredDevices = $Devices | where-object -FilterScript { $DeviceList -contains $_.devicename } | Sort-Object -Property devicename

#Traversing all devices and then changing their names as per the defined naming convention
foreach ($Device in $FilteredDevices) {
    $OldDeviceName = $Device.deviceName
    $DeviceID = $Device.Id
    $NewDeviceName = "Android-" + $Device.serialNumber
    $Resource = "deviceManagement/managedDevices('$DeviceID')/setDeviceName"
    $GraphApiVersion = "Beta"
    $URI = "https://graph.microsoft.com/$graphApiVersion/$($resource)"

    $JSONPayload = @"
{
deviceName:"$NewDeviceName"
}
"@

    Invoke-MSGraphRequest -HttpMethod POST -Url $URI -Content $JSONPayload -Verbose
    
    $Myobject = [PSCustomObject]@{
        OldDeviceName = $($OldDeviceName)
        NewDeviceName = $($NewDeviceName)
        SerialNumber  = $($Device).SerialNumber       
    }

    [Array] $FinalDevices += $MyObject
}

#Displaying the object with its defined properties
$FinalDevices
