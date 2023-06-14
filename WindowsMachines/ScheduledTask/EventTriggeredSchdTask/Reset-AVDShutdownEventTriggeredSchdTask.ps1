<#
  .SYNOPSIS
    PowerShell Script to Disable & Enable the AVD shutdown event triggered schd task after the user connect event is triggered.

  .DESCRIPTION
    With this PowerShell script, an event triggered scheduled task will be created on task scheduler of every AVD session host which will reset disable & enable
    the AVD shutdown event triggered schedule task whenever the user 'connect' event is triggered

  .NOTES
    Author : Ashish Arya
    Date   : 14-June-2023
  
  .EXAMPLE
    .\Reset-AVDShutdownEventTriggeredSchdTask.ps1
#>

$TaskName = "Reset AVD Shutdown Event Triggered Schd task"
$Taskdescription = "Disable & Enable AVD shutdown event triggered schd task when User Connect event is triggered."
$TaskAction = New-ScheduledTaskAction -Execute "C:\Users\Hitakshi\Downloads\Reset.ps1"
$CIMTriggerClass = Get-CimClass -ClassName 'MSFT_TaskSessionStateChangeTrigger' -Namespace 'Root/Microsoft/Windows/TaskScheduler:MSFT_TaskEventTrigger'
$TaskTrigger = New-CimInstance -CimClass $CIMTriggerClass -ClientOnly
$TaskTrigger.StateChange = "RemoteConnect"
$TaskTrigger.Enabled = $True
$TaskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Compatibility 'Win8'
$TaskPrincipal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType 'ServiceAccount' -RunLevel 'Highest'
$Task = New-ScheduledTask -Description $Taskdescription -Action $TaskAction -Settings $TaskSettings -Trigger $TaskTrigger -Principal $TaskPrincipal
Register-ScheduledTask -InputObject $Task -TaskName $TaskName -ErrorVariable $RegSchedTaskError
