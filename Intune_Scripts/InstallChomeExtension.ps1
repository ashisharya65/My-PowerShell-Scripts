<#
    This script will be installing the High Contrast Chrome Extension
    
    Author : Ashish Arya
    Github : @ashisharya65
#>

$KeyPath = "HKLM:\Software\Policies\Google\Chrome\ExtensionInstallForcelist"
$KeyName = "1"
$KeyType = "String"

# Here djcfdncoelnlbldjfhinnjlhdjlikmph is Id for this extension.
$KeyValue = "djcfdncoelnlbldjfhinnjlhdjlikmph;https://clients2.google.com/service/update2/crx"

#Verify if the registry path already exists
if(!(Test-Path $KeyPath)) {
    try {
        #Create registry path
        New-Item -Path $KeyPath -ItemType RegistryKey -Force -ErrorAction Stop
    }
    catch {
        Write-Output "FAILED to create the registry path"
    }
}
#Verify if the registry key already exists
if(!((Get-ItemProperty $KeyPath).$KeyName)) {
    try {
        #Create registry key 
        New-ItemProperty -Path $KeyPath -Name $KeyName -PropertyType $KeyType -Value $KeyValue
    }
    catch {
        Write-Output "FAILED to create the registry key"
    }
}
