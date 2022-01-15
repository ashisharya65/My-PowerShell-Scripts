<#
    This script uses two text files called SerialNumber and MgmtNames.
    We are adding the management names from the MgmtNames.txt file to the devices in SerialNumber.txt file.
#>


#Loading all the Intune managed Windows 10 devices
$Devices = Get-IntuneManagedDevice | Get-MSGraphAllPages | Where-Object {($_.operatingSystem -eq "Windows")}

#Loading all the SerialNumber of the devices from SN.txt file
$DevicesSNList = Get-Content "C:\Users\Arya\Desktop\SerialNumber.txt"    

<#
    #Selecting and loading only the filtered devices that are in the SerialNumber.txt file from Devices variable.
    This is done to get the selected devices with all the properties.
#>
$FilteredDevices = $Devices | where-object -FilterScript { $DevicesSNList -contains $_.serialNumber} | Sort-Object -Property serialNumber

#Loading ManagementNames from the MgmtNames.txt file
$NewManagementNames = Get-Content "C:\Users\Arya\Desktop\MgmtNames.txt"

#Looping through all the devices and changing the Management names
for($i=0;$i-lt $NewManagementNames.Length;$i++){

    
    $CurrentManagementName = $FilteredDevices[$i].managedDeviceName

    $DeviceID = $FilteredDevices[$i].id
    $Resource = "deviceManagement/managedDevices('$DeviceID')"
    $GraphApiVersion = "Beta"
    $URI = "https://graph.microsoft.com/$graphApiVersion/$($resource)"
    
    $JSONPayload = @"
    { managedDeviceName: "$($NewManagementNames[$i])"  
    } 
"@

    Invoke-MSGraphRequest -HttpMethod PATCH -Url $URI -content $JSONPayload -verbose
 
    $Myobject = [PSCustomObject]@{
        SerialNumber = $($FilteredDevices[$i]).SerialNumber
        OldManagementName = $CurrentManagementName
        NewManagementName = $NewManagementNames[$i]
    }

    [Array] $FinalDevices +=$MyObject
}

$FinalDevices