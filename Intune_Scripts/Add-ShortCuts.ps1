<#
    This is a script to add multiple shortcuts with their URL and icon images to the Intune devices.
#>

#region variable decalaration
$path1 = "$env:USERPROFILE\OneDrive\Desktop"
$path2 = "$env:USERPROFILE\Desktop"
$WScriptShell = New-Object -ComObject WScript.Shell
#endregion

#region function declaration
function Add-ShortCut {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ShortCutName,   
        [Parameter(Mandatory)] 
        [string]$ShortcutUrl,       
        [Parameter(Mandatory)]
        [string]$ShortcutIconLocation
    )

    if (test-path $path1) {
        $Shortcut = $WScriptShell.CreateShortcut($path1 + "\$ShortcutName.lnk") 
        $Shortcut.TargetPath = $ShortcutUrl
        if ($ShortcutIconLocation) {
            $Shortcut.IconLocation = $ShortcutIconLocation
        } 
        $Shortcut.Save()
    }
    elseif (test-path $path2) {
        $Shortcut = $WScriptShell.CreateShortcut($path2 + "\$ShortcutName.lnk") 
        $Shortcut.TargetPath = $ShortcutUrl
        if ($ShortcutIconLocation) {
            $Shortcut.IconLocation = $ShortcutIconLocation
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
    Add-ShortCut -ShortCutName $ShortCut.Name -ShortcutUrl $ShortCut.Url -ShortcutIconLocation $ShortCut.IconLocation
}
#endregion
