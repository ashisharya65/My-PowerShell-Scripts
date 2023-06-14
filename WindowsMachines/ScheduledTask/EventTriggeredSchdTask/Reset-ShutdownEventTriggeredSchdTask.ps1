<#
  .SYNOPSIS
    PowerShell script to Disable & Enable the device shutdown event triggered schd task after the user connect is triggered.

  .DESCRIPTION
    With this PowerShell script, an event triggered schedule task will be created on the task scheduler of windows device which
    will disable & then enable the device shutdown event triggered schedule task whenever the user connect event is triggered.

  .NOTES
    Author : Ashish Arya
    Date   : 14-June-2023
  
  .EXAMPLE
    .\Reset-AVDShutdownEventTriggeredSchdTask.ps1
#>

# Prompt to get the path of reset script. You will find the reset script
Param(
    [Parameter(Mandatory)]
    $PathOfResetScript
)

# Mentioning Scheduled task details like name, description, trigger & action.
$TaskName = "Reset AVD Shutdown Event Triggered Schd task"
$Taskdescription = "Disable & Enable AVD shutdown event triggered schd task when User Connect event is triggered."
$TaskAction = New-ScheduledTaskAction -Execute $PathOfResetScript
$CIMTriggerClass = Get-CimClass -ClassName 'MSFT_TaskSessionStateChangeTrigger' -Namespace 'Root/Microsoft/Windows/TaskScheduler:MSFT_TaskEventTrigger'
$TaskTrigger = New-CimInstance -CimClass $CIMTriggerClass -ClientOnly
$TaskTrigger.StateChange = "3"     # This will enable the "Connection from Remote computer" radio button in settings of schd task
$TaskTrigger.Enabled = $True
$TaskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Compatibility 'Win8'
$TaskPrincipal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType 'ServiceAccount' -RunLevel 'Highest'
$Task = New-ScheduledTask -Description $Taskdescription -Action $TaskAction -Settings $TaskSettings -Trigger $TaskTrigger -Principal $TaskPrincipal
Register-ScheduledTask -InputObject $Task -TaskName $TaskName 
