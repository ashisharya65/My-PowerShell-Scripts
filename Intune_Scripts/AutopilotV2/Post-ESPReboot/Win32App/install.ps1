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
.\YourScriptName.ps1
This command runs the script with default parameters.

.EXAMPLE
.\YourScriptName.ps1 -PostESPRebootFolderPath "D:\CustomPath\Post-ESPReboot"
This command runs the script, specifying a custom folder path for the Post-ESPReboot files.

.NOTES
Author: [Ashish Arya]
Date: [10-Aug-2024]
Version: 1.0
#>

[cmdletbinding()]
# Variable declarations
param(
    [string] $PostESPRebootFolderPath = "C:\Temp\Post-ESPReboot",
    [string] $LogFilePath = $PostESPRebootFolderPath + "\Logs\Post-ESPReboot-InstallScriptLog.log",
    [string] $PostESPRebootNotificationScriptPath = $PostESPRebootFolderPath + "\Post-ESPReboot-Notification.ps1",
    [string] $PostESPRebootScriptPath = $PostESPRebootFolderPath + "\Post-ESPReboot.ps1",
    [string] $PostESPRebootSchdTask = "Post-ESPReboot",
    [string] $PostESPRebootNotificationSchdTask = "Post-ESPReboot-Notification",
    [string] $DetectionTag = $PostESPRebootFolderPath + "\DetectionTag.ps1.tag"
)

# Function for logging
Function Write-Log {
    param(
        [parameter(mandatory)]
        [ValidateSet('Info','Error')]
        [String] $Level,
        
        [Parameter(mandatory)]
        [string] $Message
    )
    $CurrentDate = Get-Date -format "dd-MM-yyyy hh:mm:ss"
    $logmessage = "$($CurrentDate) [$Level] - $Message"
    Add-Content -path $LogFilePath -Value $logmessage -force
}

# If the script the Post-ESPReboot, Post-ESPReboot-Notification scripts and the concerned folder are not there, create it.
if(-not((Test-Path $PostESPRebootFolderPath) -and (Test-Path $PostESPRebootNotificationScriptPath) -and (Test-Path $PostESPRebootScriptPath) -and (Test-Path $LogFilePath))){
    
    Try {

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

        Add-Content -path $PostESPRebootScriptPath -Value $PostESPRebootScriptContent -Force -ErrorAction 'Stop'
        Write-Log -Level 'Info' -Message "Post-ESPReboot script was not there. Hence, created the script and added the code to it."
        
        Add-Content -path $PostESPRebootNotificationScriptPath -Value $PostESPRebootNotificationScriptContent -Force -ErrorAction 'Stop'
        Write-Log -Level 'Info' -Message "Post-ESPReboot-Notification script was not there. Hence, created the script and added the code to it."
    }
    catch {
        $err = $_.Exception.Message
        Write-Log -Level 'Error' -Message "Unable to create the Post-ESPReboot and Post-ESPReboot-Notification scripts as well the concerned folder. : $err."
    }
}


# Registering the scheduled task for both Post-ESPReboot and Post-ESPReboot-Notification
Try{
    Register-ScheduledTask -xml (Get-Content '.\Post-ESPReboot.xml' | Out-String) -TaskName "Post-ESPReboot" -Force -erroraction 'Stop' | Out-Null
    Write-Log -Level 'Info' -Message "Post-ESPReboot scheduled task was created successfully."
}
Catch{
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
