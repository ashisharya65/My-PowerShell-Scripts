
<#
.SYNOPSIS
Retrieves and displays the permissions of files and directories in a specified path on a linux machine.

.DESCRIPTION
The Get-Permission function retrieves detailed file and directory permissions in a specified path
on an linux system. It utilizes the 'stat' command to gather information such as permissions,
links, owner, group, size, and last modified date, and returns this information in a structured
format.

.PARAMETER Path
The path to the file or directory whose permissions are to be retrieved. This parameter is mandatory.

.EXAMPLE
Get-Permission -Path "/etc"

This example retrieves the permissions of all files and directories in the "/etc" directory and 
displays them in a table format.

.EXAMPLE
Get-Permission -Path "/var/log" | Format-Table -AutoSize

This example retrieves the permissions of all files and directories in the "/var/log" directory and
displays them in a formatted table.

.NOTES
This function is designed to work on linux systems and requires the 'stat' command to be available.

#>

function Get-Permission {
    [cmdletbinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    # Check if the specified path exists
    if (-not (Test-Path -Path $Path)) {
        throw "The specified path '$Path' does not exist."
    }

    # Get the detailed file information
    $items = Get-ChildItem -Path $Path -Force

    # Initialize an empty array for storing permissions
    $permissionsList = [System.Collections.Generic.List[Psobject]]::new()

    foreach ($item in $items) {
        # Get the full item path
        $fullPath = $item.FullName

        # Get the file information using stat
        $fileInfo = & stat --format="%A %h %U %G %s %y" $fullPath

        # Parse the output
        $info = $fileInfo -split "\s+"

        # Create a custom object to display the permissions
        $permissionsObj = [PSCustomObject]@{
            Permissions   = $info[0]
            Links         = $info[1]
            Owner         = $info[2]
            Group         = $info[3]
            Size          = $info[4]
            LastModified  = $info[5] + " " + $info[6]
            Name          = $item.Name
        }

        # Add the custom object to the list
        $permissionsList.Add($permissionsObj)
    }

    return $permissionsList
}

# Example usage:
# Get permissions for a specific folder
Get-Permission -Path "/etc/os-release" | Format-Table -AutoSize

<#

    OUTPUT:
        
    Permissions Links Owner Group Size LastModified                  Name
    ----------- ----- ----- ----- ---- ------------                  ----
    lrwxrwxrwx  1     root  root  21   2024-04-22 18:38:03.000000000 os-release

#>
