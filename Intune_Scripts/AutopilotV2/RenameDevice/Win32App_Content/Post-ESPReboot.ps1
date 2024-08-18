[cmdletbinding()]

param(
    [string] $PostESPRebootFolderPath = "C:\Temp\Post-ESPReboot",
    [string] $PostESPRebootNotificationScriptPath = $PostESPRebootFolderPath + "\Post-ESPReboot-Notification.ps1",
    [string] $PostESPRebootSchdTask = "Post-ESPReboot",
    [string] $PostESPRebootNotificationSchdTask = "Post-ESPReboot-Notification",
    [string] $LogFilePath = $PostESPRebootFolderPath + "Logs\Post-ESPRebootScriptLog.log"
)

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

Write-Log -Level 'Info' -Message "Script execution start."
Try {
    Start-ScheduledTask -TaskName $PostESPRebootSchdTask -erroraction 'Stop'
    Write-Log -Level 'Info' -Message "Successfully started the $PostESPRebootSchdTask scheduled task."
    Start-Sleep -seconds 600
    Write-Log -Level 'Info' -Message "Sleeping for 10 mins."
}
Catch {
    $err = $_.Exception.Message
    Write-Log -Level 'Error' -Message "Unable to start the $PostESPRebootSchdTask scheduled task: $err."
}

Disable-ScheduledTask -taskName $PostESPRebootSchdTask -Erroraction 'silentlycontinue' -verbose
Disable-Scheduledtask -taskName $PostESPRebootNotificationSchdTask -ErrorAction 'Continue' -verbose
Unregister-ScheduledTask -taskName $PostESPRebootSchdTask -confirm:$false
Unregister-ScheduledTask -taskName $PostESPRebootNotificationSchdTask -confirm:$false
Write-Log -Level 'Info' -Message "Successfully disabled and unregister both $PostESPRebootSchdTask and $PostESPRebootNotificationSchdTask scheduled tasks."

Remove-Item -path $PostESPRebootNotificationScriptPath -Force
Write-Log -Level 'Info' -Message "Removing the Post-ESPReboot-Notification script."

Write-Log -Level 'Info' -Message "Successfully initiated the reboot command."
Write-Log -Level 'Info' -Message "Script execution end."
Restart-Computer -Force -Verbose