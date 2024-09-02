
$DetectionTagFilePath = "C:\Temp\Rename-Device\Detection.ps1.tag"

if (Test-Path -path $DetectionTagFilePath) {
    Write-Output "The device is already rebooted."
    Exit 0
}
else {
    Write-Output "The device is not rebooted."
    Exit 1
}
