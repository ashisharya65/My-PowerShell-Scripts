<#
  .SYNOPSIS
    PowerShell script to Disable & Enable the device shutdown event triggered schd task after the user connect is triggered.

  .DESCRIPTION
    With this PowerShell script, an event triggered schedule task will be created on windows device which will be triggered to reset 
    the device shutdown event triggered schedule task, whenever the user connect event is generated in the event viewer.

  .NOTES
    Author : Ashish Arya
    Date   : 14-June-2023
  
  .EXAMPLE
    .\Reset-DeviceShutdownEventTriggeredSchdTask.ps1
#>

# Prompt to get the path of reset script. You will find the reset script
$ResetScriptPath = "C:\Temp\ResetDeviceShutdownSchdTask"
$ResetScriptContent = @"
`$DeviceShutDownTaskName = "DeviceShutdownEventTriggeredSchdTask"
Disable-ScheduledTask -TaskName `$DeviceShutDownTaskName 
Enable-ScheduledTask -TaskName `$DeviceShutDownTaskName
"@
If(!(Test-Path $ResetScriptPath)){
  New-Item $ResetScriptPath -ItemType Directory -Force | Out-Null
  $ResetScriptFullPath = $ResetScriptPath + "\Reset.ps1"
  $ResetScriptContent | Out-File $ResetScriptFullPath
}

# Mentioning Scheduled task details like name, description, trigger & action.
$TaskName = "Reset-DeviceShutdownEventTriggeredSchdTask"
$Taskdescription = "Reset the device shutdown event triggered schd task when User Connect event is triggered."
$TaskAction = New-ScheduledTaskAction -Execute $ResetScriptFullPath
$CIMTriggerClass = Get-CimClass -ClassName 'MSFT_TaskSessionStateChangeTrigger' -Namespace 'Root/Microsoft/Windows/TaskScheduler:MSFT_TaskEventTrigger'
$TaskTrigger = New-CimInstance -CimClass $CIMTriggerClass -ClientOnly
$TaskTrigger.StateChange = "3"     # This will enable the "Connection from Remote computer" radio button in settings of schd task
$TaskTrigger.Enabled = $True
$TaskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Compatibility 'Win8'
$TaskPrincipal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType 'ServiceAccount' -RunLevel 'Highest'
$Task = New-ScheduledTask -Description $Taskdescription -Action $TaskAction -Settings $TaskSettings -Trigger $TaskTrigger -Principal $TaskPrincipal
Register-ScheduledTask -InputObject $Task -TaskName $TaskName | Out-Null
