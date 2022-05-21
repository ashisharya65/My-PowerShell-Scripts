
<#
  This is a script to update the server name in the network drive path from Server1 to Server2.
  Author: Ashish Arya
  Date: 21-May-2022
#>

#region Variables
$OldPDrivePath = "\\Server1\Projects"
$OldSDrivePath = "\\Server1\Groups"
$NewPDrivePath = "\\Server2\Projects"
$NewSDrivePath = "\\Server2\Groups"


#region Update-DriveMapping function declaration
function Update-DriveMapping {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [string]$OldDrivePath,
        [Parameter(Mandatory)] 
        [string]$NewDrivePath,
        [Parameter(Mandatory)]
        [string]$DriveLetter
    ) 
    $Drive = Get-PSDrive -Name $DriveLetter -ErrorAction SilentlyContinue
    if (($Drive -and $Drive.DisplayRoot) -eq $OldDrivePath) {
        $Drive | Remove-PSDrive 
        New-PSDrive -Name $DriveLetter -PSProvider FileSystem -Root $NewDrivePath -Persist -Scope Global
    }
}

#region Update-DriveMapping Function call and passing arguments to update drive mappings
Update-DriveMapping -OldDrivePath $OldPDrivePath -NewDrivePath $NewPDrivePath -DriveLetter "P"        # Update P drive mappings
Update-DriveMapping -OldDrivePath $OldSDrivePath -NewDrivePath $NewSDrivePath -DriveLetter "S"        # Update S drive mappings

