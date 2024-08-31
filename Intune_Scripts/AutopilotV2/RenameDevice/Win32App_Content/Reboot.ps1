<#
.SYNOPSIS
This script automates the handling of a scheduled task for rebooting a device and its associated notification task, including logging, task disabling, and conditional rebooting based on user interaction.

.DESCRIPTION
The script performs the following actions:
1. Initializes paths for logs, scheduled tasks, and a detection tag file.
2. Defines a logging function to record the script's execution details.
3. Ensures the log file is created if it does not already exist.
4. Defines a function to disable a scheduled task with error handling.
5. Starts and monitors the execution of a scheduled notification task.
6. Checks for the presence of a detection tag file to determine if the device should be rebooted.
7. Disables scheduled tasks and reboots the device if the user confirms the action; otherwise, it logs that no reboot will occur.

.PARAMETER Level
Specifies the log level ("Info" or "Error") for the `Write-Log` function.

.PARAMETER Message
The message to be logged, associated with the specified log level.

.NOTES
Author: [Ashish Arya]
Date: [31-Aug-2024]
Version: 1.0

.EXAMPLE
PS C:\> .\Reboot.ps1
This command executes the script, logging its progress, handling the reboot and notification tasks, and conditionally rebooting the device based on user input.

#>

# Set up folder paths and filenames for logs, scheduled tasks, and the detection tag file
$RootFolderPath = "C:\Temp"
$LogFolderPath = $RootFolderPath + "\Rename-Device"
$LogFilePath = $LogFolderPath + "\Reboot.log"
$RebootSchdTaskName = "Post-ESPReboot"
$RebootNotificationSchdTaskName = "Post-ESPReboot-Notification"
$DetectionTagFilePath = $LogFolderPath + "\Reboot.ps1.tag"

# Define a function for logging messages to the log file with a timestamp
Function Write-Log {
    param(
        [Parameter(Mandatory)]
        [ValidateSet("Info", "Error")]
        [string] $Level,
        [Parameter(Mandatory)]
        [string] $Message
    )
    $timestamp = Get-Date -Format "dd-MM-yyyy HH:mm:ss"
    $logMessage = "$timestamp [$Level] - $Message"
    Add-Content -Path $LogFilePath -Value $logMessage -force
}
 
# Check if the log file exists. If not, create it and log the initialization of the script
if (-not(Test-Path $LogFilePath)) {
    Try {
        # Create the log file and log the script start.
        New-Item -path $LogFilePath -Itemtype "File" -force -erroraction "stop" | Out-Null
        Write-Log -Level "Info" -Message "Script execution started."
        Write-Log -Level "Info" -Message "Log file created at '$($LogFilePath)'."
    }
    Catch {
        # Log an error if the log file cannot be created.
        $err = $_.exception.message
        Write-Log -Level "Error" -Message "Error: Unable to create the log file. '$err'."
    }
   
}

# Define a function to disable a scheduled task, logging success or failure
Function Disable-SchdTask {
    param(
        [string] $TaskName
    )

    # Check if the scheduled task exists.
    $Task = (Get-ScheduledTask -TaskName $TaskName -ErrorAction "Stop")
        
    try {
        # Attempt to disable the scheduled task
        Disable-ScheduledTask -TaskName $Task.TaskName -ErrorAction "Stop"
        Write-Log -Level "Info" -Message "Scheduled task '$TaskName' has been successfully disabled."
    }
    catch {
        # Log an error if disabling the task fails
        Write-Log -Level "Error" -Message "Error: Unable to disable the '$TaskName' scheduled task. $_"
    }
}

# Start the scheduled task responsible for the reboot notification
Start-ScheduledTask -TaskName $RebootNotificationSchdTaskName
Write-Log -Level "Info" -Message "The scheduled task : $($RebootNotificationSchdTaskName) was successfully started."

# Monitor the scheduled task until it completes, logging its status periodically
do {
    $taskStatus = (Get-ScheduledTask -TaskName $RebootNotificationSchdTaskName).State
    Write-Log -Level "Info" -Message "Waiting for the scheduled task to complete. Current status: $taskStatus."
    Start-Sleep -Seconds 5
} while ($taskStatus -eq "Running")

Write-Log -Level "Info" -Message "The scheduled task : $($RebootNotificationSchdTaskName) has completed."

# Check if the detection tag file exists, which indicates user confirmation for the reboot
if (Test-Path -Path $DetectionTagFilePath) {
    # Disable both the reboot and notification scheduled tasks.
    Disable-SchdTask -TaskName $RebootSchdTaskName
    Disable-SchdTask -TaskName $RebootNotificationSchdTaskName

    # Log user confirmation and reboot the device.
    Write-Log -Level "Info" -Message "The user clicked on 'Yes' button."
    Write-Log -Level "Info" -Message "Hence rebooting the device."
    Write-Log -Level "Info" -Message "Script execution ended."
    Restart-Computer -Force
}
else {
    # Log that the user declined the reboot, and end the script without rebooting.
    Write-Log -Level "Info" -Message "The user clicked on 'No' button so no reboot will happen."
    Write-Log -Level "Info" -Message "Script execution ended."
}
