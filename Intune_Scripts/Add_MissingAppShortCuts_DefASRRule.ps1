<#

.SYNOPSIS
Creating Missing App shortcuts on machines affected by Microsoft Defender ASR rule update release on 13 Jan 2023.

.DESCRIPTION
Microsoft releases an update for Defender on 13 Jan 2023 which has affected all the managed endpoints by removing the installed app shortcuts 
from the start menu.    
This script will be re-creating the shortcuts of regular applications like MS Office suite, MS Edge, Chrome, Adobe reader etc at the start menu.
In case there are other applications whose shortcuts are missing, you just need to add the app shortcut details in the $AllShortCuts array

.NOTES
Author : Ashish Arya
Date   : 17 Jan 2023

#>

$WshShell = New-Object -ComObject WScript.Shell

function Add-MissingAppShortCut {
    [CmdletBinding()]
    param(
        [parameter(Mandatory)]
        $ShortCutPath,
        [parameter(Mandatory)]
        $TargetDir,
        [parameter(Mandatory)]
        $WorkingDir
    )

    $ShortCut = $WshShell.CreateShortcut($ShortCutPath)
    $ShortCut.TargetPath = $TargetDir
    $ShortCut.WorkingDirectory = $WorkingDir
    $ShortCut.Save()
}

$AllShortCuts =
@([PSCustomObject]@{
        Path        = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\outlook.lnk"
        TargetPath  = "C:\Program Files\Microsoft Office\root\Office16\outlook.exe"
        WorkingPath = "C:\Program Files\Microsoft Office\root\Office16\"
    },
    [PSCustomObject]@{
        Path        = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\excel.lnkk"
        TargetPath  = "C:\Program Files\Microsoft Office\root\Office16\excel.exe"
        WorkingPath = "C:\Program Files\Microsoft Office\root\Office16\"
    },
    [PSCustomObject]@{
        Path        = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Access.lnk"
        TargetPath  = "C:\Program Files\Microsoft Office\root\Office16\msaccess.exe"
        WorkingPath = "C:\Program Files\Microsoft Office\root\Office16\"
    },
    [PSCustomObject]@{
        Path        = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Publisher.lnk"
        TargetPath  = "C:\Program Files\Microsoft Office\root\Office16\mspub.exe"
        WorkingPath = "C:\Program Files\Microsoft Office\root\Office16\"
    },
    [PSCustomObject]@{
        Path        = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Onenote.lnk"
        TargetPath  = "C:\Program Files\Microsoft Office\root\Office16\onenote.exe"
        WorkingPath = "C:\Program Files\Microsoft Office\root\Office16\"
    },
    [PSCustomObject]@{
        Path        = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\powerpoint.lnk"
        TargetPath  = "C:\Program Files\Microsoft Office\root\Office16\powerpnt.exe"
        WorkingPath = "C:\Program Files\Microsoft Office\root\Office16\"
    },
    [PSCustomObject]@{
        Path        = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Microsoft Edge.lnk"
        TargetPath  = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
        WorkingPath = "C:\Program Files (x86)\Microsoft\Edge\Application\"
    },
    [PSCustomObject]@{
        Path        = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Word.lnk"
        TargetPath  = "C:\Program Files\Microsoft Office\root\Office16\winword.exe"
        WorkingPath = "C:\Program Files\Microsoft Office\root\Office16\"
    },
    [PSCustomObject]@{
        Path        = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Acrobat Reader.lnk"
        TargetPath  = "C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader\AcroRd32.exe"
        WorkingPath = "C:\Program Files (x86)\Adobe\Acrobat Reader DC\Reader"
    },
    [PSCustomObject]@{
        Path        = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\visio.lnk"
        TargetPath  = "C:\Program Files\Microsoft Office\root\Office16\visio.exe"
        WorkingPath = "C:\Program Files\Microsoft Office\root\Office16\"
    },
    [PSCustomObject]@{
        Path        = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\winproj.lnk"
        TargetPath  = "C:\Program Files\Microsoft Office\root\Office16\winproj.exe"
        WorkingPath = "C:\Program Files\Microsoft Office\root\Office16\"
    },
    [PSCustomObject]@{
        Path        = "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Google Chrome.lnk"
        TargetPath  = "C:\Program Files\Google\Chrome\Application\chrome.exe"
        WorkingPath = "C:\Program Files\Google\Chrome\Application\"
    }
)

foreach ($Shortcut in $AllShortCuts) {
    Add-MissingAppShortCut -ShortCutPath $Shortcut.Path -TargetDir $ShortCut.TargetPath -WorkingDir $Shortcut.WorkingPath
}
