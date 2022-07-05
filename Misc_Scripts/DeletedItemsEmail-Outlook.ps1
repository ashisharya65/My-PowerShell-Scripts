Add-Type -Assembly "$($env:ProgramFiles)\Microsoft Office\root\Office16\ADDINS\Microsoft Power Query for Excel Integrated\bin\Microsoft.Office.Interop.Outlook.dll"

$outlookApp = New-Object -comobject Outlook.Application
$mapiNamespace = $outlookApp.GetNameSpace("MAPI")

$DeletedItems = $mapiNamespace.GetDefaultFolder([Microsoft.Office.Interop.Outlook.OlDefaultFolders]::olFolderDeletedItems)
$DeletedItems.Items | ForEach-Object {$_.Delete()}
