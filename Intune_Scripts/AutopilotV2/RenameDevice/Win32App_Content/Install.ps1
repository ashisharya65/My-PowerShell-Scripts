<# 
.SYNOPSIS
This script automates the setup and registration of scheduled tasks for Post-ESPReboot and Post-ESPReboot-Notification, ensuring all necessary scripts and folders are in place.

.DESCRIPTION
The script initializes necessary variables and checks for the existence of required files and directories. If the specified Post-ESPReboot and Post-ESPReboot-Notification scripts do not exist, it creates them and logs all actions to a designated log file. Additionally, it registers scheduled tasks using predefined XML configurations. Error handling and logging are implemented to track the script's progress and capture any issues.

.PARAMETER PostESPRebootFolderPath
The folder path where the Post-ESPReboot scripts and logs are stored. Defaults to 'C:\Temp\Post-ESPReboot'.

.PARAMETER LogFilePath
The file path for the log file where script execution details are recorded. Defaults to a log file within the PostESPRebootFolderPath.

.PARAMETER PostESPRebootNotificationScriptPath
The file path for the Post-ESPReboot-Notification script.

.PARAMETER PostESPRebootScriptPath
The file path for the Post-ESPReboot script.

.PARAMETER PostESPRebootSchdTask
The name of the scheduled task for the Post-ESPReboot script.

.PARAMETER PostESPRebootNotificationSchdTask
The name of the scheduled task for the Post-ESPReboot-Notification script.

.PARAMETER DetectionTag
The path to the detection tag file used to mark the installation status.

.EXAMPLE
.\Install.ps1
This command runs the script with default parameters.

.NOTES
Version: 1.0
Script Name: Install.ps1
Purpose: Creating scheduled tasks to automatically reboot reboot the device post Enrollment Status Page phase completion.
#>


[cmdletbinding()]
# Variable declarations
param(
    [string] $PostESPRebootFolderPath = "C:\Temp\Post-ESPReboot",
    [string] $LogFilePath = $PostESPRebootFolderPath + "\Logs\Post-ESPReboot-InstallScriptLog.log",
    [string] $PostESPRebootSchdTask = "Post-ESPReboot",
    [string] $PostESPRebootNotificationSchdTask = "Post-ESPReboot-Notification",
    [string] $DetectionTag = $PostESPRebootFolderPath + "\DetectionTag.ps1.tag"
)

# Function for logging
Function Write-Log {
    param(
        [parameter(mandatory)]
        [ValidateSet('Info', 'Error')]
        [String] $Level,
        
        [Parameter(mandatory)]
        [string] $Message
    )
    $CurrentDate = Get-Date -format "dd-MM-yyyy hh:mm:ss"
    $logmessage = "$($CurrentDate) [$Level] - $Message"
    Add-Content -path $LogFilePath -Value $logmessage -force
}

# If the script the Post-ESPReboot, Post-ESPReboot-Notification scripts and the concerned folder are not there, create it.
if (-not((Test-Path $PostESPRebootFolderPath))) {
    
    Try {
        New-Item -Path $PostESPRebootFolderPath -Itemtype 'Directory' -force -erroraction 'stop' | Out-Null
        New-Item -path $LogFilePath -Itemtype 'File' -force |  Out-Null
        Set-Content -Path $DetectionTag -Value "Installed" -erroraction 'Stop'

        Write-Log -Level 'Info' -Message "Script execution started."
        Write-Log -Level 'Info' -Message "Successfully created the Post-ESPReboot folder and detection tag file."
    }
    Catch {
        $err = $_.Exception.Message
        Write-Log -Level 'Error' -Message "Unable to create the log file as well as the device rename tag file: $err."
    }

    Try {
        Copy-Item -Path ".\Post-ESPReboot.ps1" -Destination $PostESPRebootFolderPath -Force -erroraction 'stop'
        Write-Log -Level 'Info' -Message "Copied the Post-ESPReboot script to the Post-ESPReboot folder."

        Copy-Item -Path ".\Post-ESPReboot-Notification.ps1" -Destination $PostESPRebootFolderPath -Force -erroraction 'stop'
        Write-Log -Level 'Info' -Message "Copied the Post-ESPReboot-Notification script to the Post-ESPReboot folder." 
    }
    catch {
        $err = $_.Exception.Message
        Write-Log -Level 'Error' -Message "Unable to create the Post-ESPReboot and Post-ESPReboot-Notification scripts as well the concerned folder. : $err."
    }
}


# Registering the scheduled task for both Post-ESPReboot and Post-ESPReboot-Notification
Try {
    Register-ScheduledTask -xml (Get-Content '.\Post-ESPReboot.xml' | Out-String) -TaskName "Post-ESPReboot" -Force -erroraction 'Stop' | Out-Null
    Write-Log -Level 'Info' -Message "Post-ESPReboot scheduled task was created successfully."
}
Catch {
    $err = $_.Exception.Message
    Write-Log -Level 'Error' -Message "Unable to create the Post-ESPReboot scheduled task: $err."
}

Try {
    Register-ScheduledTask -xml (Get-Content '.\Post-ESPReboot-Notification.xml' | Out-String) -TaskName "Post-ESPReboot-Notification" -Force -erroraction 'Stop' | Out-Null
    Write-Log -Level 'Info' -Message "Post-ESPReboot-Notification scheduled task was created successfully."
}
Catch {
    $err = $_.Exception.Message
    Write-Log -Level 'Error' -Message "Unable to create the Post-ESPReboot-Notification scheduled task : $err."
}

Write-Log -Level 'Info' -Message "Script execution ended."
