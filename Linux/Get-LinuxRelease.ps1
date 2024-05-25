<#
.SYNOPSIS
Retrieves the Ubuntu OS release information from the specified file.

.DESCRIPTION
The Get-LinuxRelease function reads the Ubuntu OS release information from a specified file,
defaulting to "/etc/os-release". It parses the file and returns a list of custom objects
representing key-value pairs found in the file.

.PARAMETER filepath
The path to the OS release file. Defaults to "/etc/os-release".

.EXAMPLE
PS C:\> Get-LinuxRelease

This command retrieves the Ubuntu OS release information using the default file path.

.EXAMPLE
PS C:\> Get-LinuxRelease -filepath "/custom/path/os-release"

This command retrieves the Ubuntu OS release information from a custom file path.

.OUTPUTS
System.Collections.Generic.List[PSObject]
A list of custom objects, each containing a 'key' and a 'value' property representing
a key-value pair from the OS release file.

.NOTES
The function checks if the specified file path exists. If not, it falls back to "/usr/lib/os-release".
If neither file is found, an error is thrown.

#>

function Get-LinuxRelease {
    [cmdletbinding()]
    param(
        [string]$filepath = "/etc/os-release"
    )

    if (-not (Test-Path -Path $filepath)) {
        if (Test-Path '/usr/lib/os-release') {
            $filepath = '/usr/lib/os-release'
        }
        else {
            throw 'Unable to find os-release file in /etc/ or /usr/lib directories'
        }
    }

    # Initialize an empty list
    $osInfoList = [System.Collections.Generic.List[PSObject]]::new()
    
    foreach ($line in (Get-Content -Path $filepath)) {
        if ($line -match "^(.+)=(.+)$") {
            # Create a custom object for each key-value pair
            $obj = [pscustomobject]@{
                key = $matches[1]
                value = $matches[2].Trim('"')     
            }
            # Add the object to the list
            $osInfoList.Add($obj)
        }
    }
    return $osInfoList
}

Get-LinuxRelease

<#
    OUTPUT

    key                value
    ---                -----
    PRETTY_NAME        Ubuntu 24.04 LTS
    NAME               Ubuntu
    VERSION_ID         24.04
    VERSION            24.04 LTS (Noble Numbat)
    VERSION_CODENAME   noble
    ID                 ubuntu
    ID_LIKE            debian
    HOME_URL           https://www.ubuntu.com/
    SUPPORT_URL        https://help.ubuntu.com/
    BUG_REPORT_URL     https://bugs.launchpad.net/ubuntu/
    PRIVACY_POLICY_URL https://www.ubuntu.com/legal/terms-and-policies/privacy-policy
    UBUNTU_CODENAME    noble
    LOGO               ubuntu-logo

#>