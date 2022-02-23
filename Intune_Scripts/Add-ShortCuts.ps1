<#
    This is a script to add multiple shortcuts with their URL and icon images to the Intune devices.
    Author : Ashish Arya
    Github : @ashisharya65
#>

#region variable decalaration
$Path1 = "$env:USERPROFILE\OneDrive\Desktop"
$Path2 = "$env:USERPROFILE\Desktop"
$WScriptShell = New-Object -ComObject WScript.Shell
#endregion

#region function declaration
function Add-ShortCut {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ShortCutName,   
        [Parameter(Mandatory)] 
        [string]$ShortCutUrl,       
        [Parameter(Mandatory)]
        [string]$ShortCutIconLocation
    )

    if (test-path $path1) {
        $ShortCut = $WScriptShell.CreateShortcut($path1 + "\$ShortCutName.lnk") 
        $ShortCut.TargetPath = $ShortCutUrl
        if ($ShortCutIconLocation) {
            $ShortCut.IconLocation = $ShortCutIconLocation
        } 
        $Shortcut.Save()
    }
    elseif (test-path $path2) {
        $ShortCut = $WScriptShell.CreateShortcut($path2 + "\$ShortCutName.lnk") 
        $ShortCut.TargetPath = $ShortCutUrl
        if ($ShortCutIconLocation) {
            $ShortCut.IconLocation = $ShortCutIconLocation
        }
        $Shortcut.Save()
    }
}
#endregion

#region CustomObject creation
$AllShortCuts = 
@([PSCustomObject]@{
        Name         = "First Shortcut Name"
        Url          = "First ShortCut URL"
        IconLocation = "First ShortCut Icon Image Location"
    },
    [PSCustomObject]@{
        Name         = "Second Shortcut Name"
        Url          = "Second ShortCut URL"
        IconLocation = "Second ShortCut Icon Image Location"
    }
)
#region function call

Foreach ($ShortCut in $AllShortCuts) {
    Add-ShortCut -ShortCutName $ShortCut.Name -ShortCutUrl $ShortCut.Url -ShortCutIconLocation $ShortCut.IconLocation
}
#endregion
