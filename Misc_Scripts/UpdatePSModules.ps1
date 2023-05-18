
<#
    .SYNOPSIS
        Script to update all your installed PowerShell modules to their latest versions.

    .DESCRIPTION
        You can use this script to execute on a regular basis to update all your PowerShell modules installed on your local machine to their latest versions.
        
    .NOTES
        Author : Ashish Arya
        Date   : 18 May 2023
#>

Write-Host "Retrieving all installed modules ..." -ForegroundColor 'Yellow'
$CurrentModules = Get-InstalledModule | Select-Object Name,Version | Sort-Object -Property Name
If (-not $CurrentModules) {
    Write-Host ("No modules found.") -ForegroundColor 'Gray'
    Return
}
Else {
    $ModulesCount = $CurrentModules.Count
    $DigitsLength = $ModulesCount.ToString().Length
    Write-Host ("{0} modules found." -f $ModulesCount) -ForegroundColor 'Gray'
}

# Loop through the installed modules and update them if a newer version is available
$i = 0
Foreach ($Module in $CurrentModules) {
    
    $i++
    $Counter = ("[{0,$DigitsLength}/{1,$DigitsLength}]" -f $i, $ModulesCount)
    $CounterLength = $Counter.Length
    Write-Host ('{0} Checking for updated version of module {1} ...' -f $Counter, $Module.Name) -ForegroundColor 'Green'
    
    Try {
            Update-Module -Name $Module.Name -AllowPrerelease:$AllowPrerelease -AcceptLicense -Scope:CurrentUser -ErrorAction 'Stop'
    }
    Catch {
            Write-Host ("{0,$CounterLength} Error updating module {1}!" -f ' ', $Module.Name) -ForegroundColor 'Red'
    }

    # Retrieve newest version number and remove old(er) version(s) if any
    $AllVersions = Get-InstalledModule -Name $Module.Name -AllVersions | Sort-Object PublishedDate -Descending
    $MostRecentVersion = $AllVersions[0].Version
    If ($AllVersions.Count -gt 1 ) {
        Foreach ($Version in $AllVersions) {
            If ($Version.Version -ne $MostRecentVersion) {
                Try {
                        Write-Host ("{0,$CounterLength} Uninstalling previous version {1} of module {2} ..." -f ' ', $Version.Version, $Module.Name) -ForegroundColor 'DarkYellow'
                        Uninstall-Module -Name $Module.Name -RequiredVersion $Version.Version -Force:$True -ErrorAction 'Stop'
                }
                Catch {
                        Write-Warning ("{0,$CounterLength} Error uninstalling previous version {1} of module {2}!" -f ' ', $Version.Version, $Module.Name)
                }
            }
        }
    }
}

# Get the new module versions for comparing them to to previous one if updated
$NewModules = Get-InstalledModule | Select-Object Name, Version | Sort-Object -Property Name
if ($NewModules) {
    ''
    Write-Host ("List of updated modules:") -ForegroundColor 'Green'
    $NoUpdatesFound = $true
    Foreach ($Module in $NewModules) {
        $CurrentVersion = $CurrentModules | Where-Object Name -EQ $Module.Name
        If ($CurrentVersion.Version -notlike $Module.Version) {
            $NoUpdatesFound = $false
            Write-Host ("- Updated module {0} from version {1} to {2}" -f $Module.Name, $CurrentVersion.Version, $Module.Version) -ForegroundColor 'Green'
        }
    }
    If ($NoUpdatesFound) {
            Write-Host ("No modules were updated.") -ForegroundColor 'Gray'
    }
}
