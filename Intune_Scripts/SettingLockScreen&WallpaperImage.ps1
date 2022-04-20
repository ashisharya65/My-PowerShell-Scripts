<#

.SYNOPSIS
This script can be used to set the Wallpaper and LockScreen image on a Windows 10 device.

.DESCRIPTION
This is a script which will be used to set up the Wallpaper and LockScreen image on a Windows 10 device.
Here we are targetting the PersonalizationCSP to create the Wallpaper and LockScreen registry keys.

Author : Ashish Arya
Date   : 20-April-2022

#>

#region variables
$RegKeyPath          = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\PersonalizationCSP"
$DesktopPath         = "DesktopImagePath"
$DesktopStatus       = "DesktopImageStatus"
$DesktopUrl          = "DesktopImageUrl"
$LockScreenPath      = "LockScreenImagePath"
$LockScreenStatus    = "LockScreenImageStatus"
$LockScreenUrl       = "LockScreenImageUrl"
$LockScreenImageURL  = "Web location for LockScreen Image"
$WallpaperImageURL   = "Web location for Wallpaper Image"
$LocalScreenImageloc = "C:\Windows\Personalization\LockScreenImage\Lockscreen.jpg"
$WallpaperImageloc   = "C:\Windows\Personalization\DesktopImage\Wallpaper.jpg"
$StatusValue         = "1"
$WallpaperDirectory  = "C:\Windows\Personalization\DesktopImage"
$LockScreenDirectory = "C:\Windows\Personalization\LockScreenImage"

#region check for lock screen image and wallpaper image directories and creating them if they are not there.
If ((!(Test-Path -Path $WallpaperDirectory)) -or (!(Test-Path -Path $LockScreenDirectory))) {
    New-Item -Path $Directory -ItemType Directory
}

#region downloading the lock screen image and wallpaper image to their respective locations.
$wc = New-Object System.Net.WebClient
$wc.DownloadFile($LockScreenImageURL, $LocalScreenImageloc)
$wc.DownloadFile($WallpaperImageURL, $WallpaperImageloc)

#region for checking the PersonalizationCSP registry key and creating it if it is not there.
if (!(Test-Path $RegKeyPath)) {
    Write-Host "Creating registry path $($RegKeyPath)."
    New-Item -Path $RegKeyPath -Force | Out-Null
}

#region for creating the Wallpaper registry keys and values.
New-ItemProperty -Path $RegKeyPath -Name $DesktopStatus -Value $Statusvalue -PropertyType DWORD -Force | Out-Null
New-ItemProperty -Path $RegKeyPath -Name $DesktopPath -Value $WallpaperImageloc -PropertyType STRING -Force | Out-Null
New-ItemProperty -Path $RegKeyPath -Name $DesktopUrl -Value $WallpaperImageURL -PropertyType STRING -Force | Out-Null

#region for creating the LockScreen registry keys and values.
New-ItemProperty -Path $RegKeyPath -Name $LockScreenStatus -Value $Statusvalue -PropertyType DWORD -Force | Out-Null
New-ItemProperty -Path $RegKeyPath -Name $LockScreenPath -Value $LocalScreenImageloc -PropertyType STRING -Force | Out-Null
New-ItemProperty -Path $RegKeyPath -Name $LockScreenUrl -Value $LockScreenImageURL -PropertyType STRING -Force | Out-Null


