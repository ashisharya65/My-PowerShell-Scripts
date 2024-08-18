
[cmdletbinding()]
# variable declarations
param(
    [string] $PostESPRebootFolderPath = "C:\Temp\Post-ESPReboot",
    [string] $LogFilePath = $PostESPRebootFolderPath + "\Logs\Post-ESPReboot-UninstallScriptLog.log",
    [string] $PostESPRebootNotificationScriptPath = $PostESPRebootFolderPath + "\Post-ESPReboot-Notification.ps1",
    [string] $PostESPRebootScriptPath = $PostESPRebootFolderPath + "\Post-ESPReboot.ps1",
    [string] $PostESPRebootSchdTask = "Post-ESPReboot",
    [string] $PostESPRebootNotificationSchdTask = "Post-ESPReboot-Notification"
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

# Removing the Post-ESPReboot folder and its content
Write-Log -Level 'Info' -Message "Script execution started."
Remove-Item -path $PostESPRebootNotificationScriptPath -force
Write-Log -Level 'Info' -Message "Removed the Post-ESPReboot-Notification script."

# Disable and unregistering both Post-ESPReboot and Post-ESPReboot-Notification scheduled tasks
Disable-ScheduledTask -TaskName $PostESPRebootSchdTask -Erroraction 'silentlycontinue' | Out-Null
Disable-Scheduledtask -TaskName $PostESPRebootNotificationSchdTask -ErrorAction 'Continue' | Out-Null
Unregister-ScheduledTask -TaskName $PostESPRebootSchdTask -confirm:$false
Unregister-ScheduledTask -TaskName $PostESPRebootNotificationSchdTask -confirm:$false
Write-Log -Level 'Info' -Message "Successfully disabled and unregistered both $PostESPRebootSchdTask and $PostESPRebootNotificationSchdTask scheduled tasks."

Write-Log -Level 'Info' -Message "Script execution ended."