<#
.SYNOPSIS
This script removes specific log files, scripts, and scheduled task folders, and then disables and unregisters scheduled tasks related to post-ESP (Enrollment Status Page) reboot operations.

.DESCRIPTION
The script performs the following actions:
1. Initializes paths for logs, scripts, and scheduled task folders.
2. Removes the log file, scripts folder, and scheduled tasks folder if they exist.
3. Disables and unregisters the scheduled tasks "Post-ESPReboot" and "Post-ESPReboot-Notification".
4. Logs and outputs each step of the script execution for troubleshooting and auditing purposes.

.PARAMETER RebootSchdTaskName
The name of the scheduled task responsible for rebooting the system after ESP.

.PARAMETER RebootNotificationSchdTaskName
The name of the scheduled task responsible for notifying the user before the reboot after ESP.

.NOTES
Author: Ashish Arya
Date: 31-Aug-2024
Version: 1.0

.EXAMPLE
PS C:\> .\Uninstall.ps1
This command executes the script, cleaning up the log, scripts, and scheduled tasks related to post-ESP reboots.

#>

# Variable declarations: Define paths for the log folder and scheduled tasks.
$LogFolderPath = "C:\Temp\Rename-Device"
$RebootSchdTaskName = "Post-ESPReboot"
$RebootNotificationSchdTaskName = "Post-ESPReboot-Notification"

# Output the start of the script execution.
Write-Output "Script execution starts here."

# Remove the log file, scripts folder, and scheduled tasks folder if they exist, excluding the main log file.
Get-ChildItem -Path $LogFolderPath -Exclude "Rename-Device.log" | Remove-Item -Recurse -Force
Write-Output "Successfully removed the Log file, Scripts and Scheduled tasks folders."

# Disable the scheduled tasks "Post-ESPReboot" and "Post-ESPReboot-Notification" silently.
Disable-ScheduledTask -TaskName $RebootSchdTaskName -Erroraction 'silentlycontinue' | Out-Null
Disable-Scheduledtask -TaskName $RebootNotificationSchdTaskName -ErrorAction 'Continue' | Out-Null

# Unregister the scheduled tasks "Post-ESPReboot" and "Post-ESPReboot-Notification" without confirmation prompts.
Unregister-ScheduledTask -TaskName $RebootSchdTaskName -confirm:$false
Unregister-ScheduledTask -TaskName $RebootNotificationSchdTaskName -confirm:$false
Write-Host "Successfully disabled and unregistered both $RebootSchdTaskName and $RebootNotificationSchdTaskName scheduled tasks."

# Output the end of the script execution.
Write-Output "Script execution ends here."
