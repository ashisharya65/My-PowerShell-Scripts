<#
.SYNOPSIS
This script automates the creation and execution of scheduled tasks to reboot a device and display a notification after the device exits the Enrollment Status Page (ESP) phase in Windows Autopilot.

.DESCRIPTION
The script performs the following operations:
1. Initializes paths for logs, scripts, and scheduled tasks.
2. Defines a logging function to record information and errors.
3. Creates necessary directories and log files if they do not exist.
4. Copies reboot and notification scripts, along with their associated scheduled task XML files, to the designated directories.
5. Registers the scheduled tasks using the copied XML files.
6. Checks whether the device has exited the ESP phase by detecting a specific event in the Security log.
7. If the device has exited the ESP phase, the script triggers the scheduled reboot task; otherwise, it logs that the device is still in the ESP phase.

.PARAMETER Level
The log level for the `Write-Log` function, either "Info" or "Error".

.PARAMETER Message
The message to log, associated with the specified log level.

.NOTES
Author: Ashish Arya
Date: 31-Aug-2024
Version: 1.0

.EXAMPLE
PS C:\> .\Rename-Device.ps1
This command executes the script, creating the necessary files and folders, copying the required scripts, and registering the scheduled tasks.

.EXAMPLE
PS C:\> Write-Log -Level "Info" -Message "This is a test log entry."
This command logs an informational message to the log file.

#>

# Set up folder paths and filenames for logs, scripts, and scheduled tasks.
$LogFolderPath = "C:\Temp\Rename-Device"
$LogFilePath = $LogFolderPath + "\Main.log"
$ScriptsFolderPath = $LogFolderPath + "\Scripts"
$SchdTaskFolderPath = $LogFolderPath + "\SchdTasks"
$RebootScriptPath = $ScriptsFolderPath + "\Reboot.ps1"
$RebootNotificationScriptPath = $ScriptsFolderPath + "\Toast.ps1"
$RebootSchdTaskPath = $SchdTaskFolderPath + "\RebootSchdTask.xml"
$RebootNotificationSchdTaskPath = $SchdTaskFolderPath + "\ToastSchdTask.xml"
$RebootSchdTaskName = "Post-ESPReboot"

# Define a function for logging messages to the log file with a timestamp.
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

# Check if log file and necessary folders exist. If not, create them.
if (-not((Test-Path $LogFilePath) -and (Test-Path $ScriptsFolderPath) -and (Test-Path $SchdTaskFolderPath))) {
    Try {
        New-Item -path $LogFilePath -Itemtype "File" -force -erroraction "stop" | Out-Null
        New-Item -path $ScriptsFolderPath -Itemtype "Directory" -force -erroraction "stop" | Out-Null
        New-Item -path $SchdTaskFolderPath -Itemtype "Directory" -force -erroraction "stop" | Out-Null
        Write-Log -Level "Info" -Message "Script execution starts here."
        Write-Log -Level "Info" -Message "Log file is created at '$($LogFilePath)' path."
        Write-Log -Level "Info" -Message "Scripts folder is created at '$($ScriptsFolderPath)' path."
        Write-Log -Level "Info" -Message "Scheduled tasks folder is created at '$($SchdTaskFolderPath)' path."
    }
    Catch {
        $err = $_.exception.message
        Write-Log -Level "Error" -Message "Error: Unable to create the log file, Scripts and Schedule task folders.$err."
    }
}

# Check if the reboot script, notification script, and associated XML files exist. If not, copy them from the source.
if (-not((Test-Path $RebootScriptPath) -and (Test-Path $RebootNotificationScriptPath) -and (Test-Path $RebootSchdTaskPath) -and (Test-Path $RebootNotificationSchdTaskPath))) {
    
    # Copy reboot and notification scripts along with their XML files to the target directories.
    Try {
        Copy-Item -Path ".\Reboot.ps1" -Destination $RebootScriptPath -Force -ErrorAction 'Stop'
        Copy-Item -Path ".\Toast.ps1" -Destination $RebootNotificationScriptPath -Force -ErrorAction 'Stop'
        Copy-Item -Path ".\RebootSchdTask.xml" -Destination $RebootSchdTaskPath -Force -ErrorAction 'Stop'
        Copy-Item -Path ".\ToastSchdTask.xml" -Destination $RebootNotificationSchdTaskPath -Force -ErrorAction 'Stop'

        # Log the successful copying of scripts and XML files.
        Write-Log -Level "Info" -Message "All Scripts are copied under $($ScriptsFolderPath) folder path."
        Write-Log -Level "Info" -Message "All Scheduled tasks are copied under $($SchdTaskFolderPath) folder path."
    }
    Catch {
        # Log an error message if the copying fails.
        $err = $_.Exception.Message
        Write-Log -Level "Error" -Message "ERROR: Unable to copy the scripts and schedule tasks to the concerned directories. '$err.'"
    }

    # Register the scheduled tasks using the copied XML files.
    Try {
        Register-ScheduledTask -xml (Get-Content '.\RebootSchdTask.xml' | Out-String) -TaskName "Post-ESPReboot" -Force -ErrorAction 'Stop' | Out-Null
        Register-ScheduledTask -xml (Get-Content '.\ToastSchdTask.xml' | Out-String) -TaskName "Post-ESPReboot-Notification" -Force -ErrorAction 'Stop' | Out-Null

        # Log the successful registration of the scheduled tasks.
        Write-Log -Level "Info" -Message "Reboot and its notification scheduled tasks got successfully created."
        Write-Log -Level "Info" -Message "Script execution ended."
    }
    Catch {
        # Log an error message if registration of scheduled tasks fails.
        $err = $_.Exception.Message
        Write-Log -Level "Error" -Message "ERROR: Unable to register both the Reboot and its notification scheduled tasks. '$err.'"
    }
}

# Check if the device has exited the ESP phase by looking for a specific event in the Security log.
$DisableAcctEvent = Get-WinEvent -FilterHashtable @{LogName = "Security"; Id = "4725" } -ErrorAction "SilentlyContinue" | `
    Where-Object { $_.Message -match "Account Name:\s*defaultuser0" } | Select-Object -First 1

# If the event is found, the device has exited ESP; start the reboot scheduled task.
if ($DisableAcctEvent) {
    Write-Log -Level "Info" -Message "The device has already gone through the ESP phase."
    Start-ScheduledTask -TaskName $RebootSchdTaskName
    Write-Log -Level "Info" -Message "The scheduled task : $($RebootSchdTaskName) was successfully started."
    Write-Log -Level "Info" -Message "Script execution ends here."
}
else {
    # If the event is not found, the device is still in ESP.
    Write-Log -Level "Info" -Message "The device still is in the ESP phase."
    Write-Log -Level "Info" -Message "Script execution ends here."
}
