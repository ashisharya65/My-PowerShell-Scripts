
<#
.SYNOPSIS
    Changes the icon and name of a specified folder.

.DESCRIPTION
    The Change-FolderProperty function updates the icon and name of a folder. It creates or modifies the desktop.ini file within the folder to 
    set a custom icon and renames the folder to a new specified name.
    This function requires administrative privileges to run if the folder is in a protected directory.

.PARAMETER oldfolderpath
    The path of the folder to be modified.

.PARAMETER imgpath
    The file path of the icon image (with .ico extension) to be used for the folder.

.PARAMETER iconindex
    The index number of the icon image file. As we are using .ico image file, indexnumber will be 0.

.PARAMETER newfolderpath
    The new path (including the new folder name) for the folder.

.EXAMPLE
    Change-FolderProperty -oldfolderpath "C:\OldFolder" -imgpath "C:\Icons\MyIcon.ico" -imgindexnum 0 -newfolderpath "C:\NewFolder"

.NOTES
    Author : Ashish Arya
    Date   : 04-July-2024
#>


Function Change-FolderProperty {
    [cmdletbinding()]
    param(
        # The original folder path.
        [parameter(mandatory)]
        [string] $oldfolderpath,

        # The path to the icon file.
        [parameter(mandatory)]
        [string] $imgpath,

        # The index number of the icon in the icon file.
        [int] $iconindex = 0,

        # The new folder path after renaming.
        [parameter(mandatory)]
        [string] $newfolderpath    
    )

    # The content to be added to the desktop.ini file for custom icon.
    $desktopini = @"
        [.ShellClassInfo]
        IconResource=$($imgpath),$($iconindex)
"@

    # Check if the desktop.ini file already exists in the folder.
    If (!(Test-Path "$($oldfolderpath)\desktop.ini")) {
        
        # If not, create the desktop.ini file with the custom icon.
        Add-Content "$($oldfolderpath)\desktop.ini" -Value $desktopini
        
        # Set the necessary attributes for the desktop.ini file.
        (Get-Item "$($oldfolderpath)\desktop.ini" -Force).Attributes = 'Hidden, System, Archive'

        # Set the folder attributes to ReadOnly and Directory.
        (Get-Item $oldfolderpath -Force).Attributes = 'ReadOnly, Directory'
    }

    # Rename the folder to the new name provided.
    Rename-Item -Path $oldfolderpath -NewName $newfolderpath -Force
}

# Call the function to change folder properties.
Change-FolderProperty
