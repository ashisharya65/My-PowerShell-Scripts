<#
    .SYNOPSIS
    Delete the emails from the Deleted Items folder of your email account in Outlook app.
   
   .DESCRIPTION
   This script will help you to delete the emails from the Deleted Items folder of your email account configured in Outlook app.
   .NOTES
   Author : Ashish Arya (ashisharya65@outlook.com)
   Date   :  5-July-2022
#>

Add-Type -Assembly "$($env:ProgramFiles)\Microsoft Office\root\Office16\ADDINS\Microsoft Power Query for Excel Integrated\bin\Microsoft.Office.Interop.Outlook.dll"

$outlookApp = New-Object -comobject Outlook.Application
$mapiNamespace = $outlookApp.GetNameSpace("MAPI")

$DeletedItems = $mapiNamespace.GetDefaultFolder([Microsoft.Office.Interop.Outlook.OlDefaultFolders]::olFolderDeletedItems)
$DeletedItems.Items | ForEach-Object {$_.Delete()}
