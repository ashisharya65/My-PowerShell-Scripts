<#
    .SYNOPSIS
    This is a script which will launch Notepad and start entering keys.

    .DESCRIPTION
    This script will launch notepad app and start entering key which you will pass to the function.
    
    .EXAMPLES
    Send-KeysToNotepad -Key "$"
    
    .NOTES
    Author: Ashish Arya
    Date  : 26 May 2022
#>

add-type -AssemblyName microsoft.VisualBasic
add-type -AssemblyName System.Windows.Forms
function Send-KeysToNotepad{ 
    param(
        [string] $Key
    )
    start-process Notepad -ErrorAction SilentlyContinue
    $Notepad = get-process Notepad -ErrorAction SilentlyContinue
    $wshell = New-Object -ComObject wscript.shell
    do{
         
        $wshell.SendKeys($Key)  
        start-sleep 2
    }while(!($Notepad.HasExited))
    
}

Send-KeysToNotepad "."
