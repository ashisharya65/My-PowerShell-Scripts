<#
    .SYNOPSIS
        PowerShell Script to prefix a folder files with numbers as per their creation time.

    .DESCRIPTION
        This is a script using which you can use to add a prefix to your files in a folder with numbers from 1 to the count of files.
        Here we are sorting the files as per their creation time. Like the file which was created first will be prefix with number 1.

    .NOTES
        Author : Ashish Arya
        Date   : 05-June-2023
#>

Param(
    $FolderPath = "D:\AshishArya_Docs\Github\ashisharya65\Learn-CSharp\NoteBooks"
)

# Getting all the files from a folder and sorting them as per their creation time
$AllFiles = Get-ChildItem $FolderPath | Sort-Object -Property CreationTime

# Looping through all files to add the number as prefix to the filename and then renaming the file with the new name
$AllFiles | Foreach-Object {
    $Count += 1 
    $NewName = "$($Count).$($_.Name)"
    Rename-Item -Path $_.FullName -NewName $NewName -Force
}