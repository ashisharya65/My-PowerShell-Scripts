<#
  .SYNOPSIS
    PowerShell Script to create an event triggered scheduled task to shutdown device after user log off event is triggered.

  .DESCRIPTION
    With this PowerShell script, an event triggered scheduled task will be created on windows device which will be triggered to shutdown the device
    whenever the user logoff event (Event id 4647) is generated in the event viewer.
    
  .NOTES
    Author : Ashish Arya
    Date   : 14-June-2023
  
  .EXAMPLE
    .\Create-DeviceShutdownEventTriggeredSchdTask.ps1
#>

# Mentioning Scheduled task details like name, description, trigger & action.
$TaskName = "DeviceShutdownEventTriggeredSchdTask"
$Taskdescription = "Task to shutdown the device whenever the user logoff event (Eventid-4647) happens."
$TaskAction = New-ScheduledTaskAction -Execute "C:\Windows\System32\shutdown.exe" -Argument "/f /s /t 0"
$CIMTriggerClass = Get-CimClass -ClassName 'MSFT_TaskEventTrigger' -Namespace 'Root/Microsoft/Windows/TaskScheduler:MSFT_TaskEventTrigger'
$TaskTrigger = New-CimInstance -CimClass $CIMTriggerClass -ClientOnly

# This is for mentioning the XML query for user log off event
$TaskTrigger.Subscription =    
@"
<QueryList>
  <Query Id="0" Path="Security">
    <Select Path="Security">*[System[EventID=4647]]</Select>     
  </Query>
</QueryList>
"@
$TaskTrigger.Delay = "PT30M"      # 30 mins of delay on triggering the scheduled task.
$TaskTrigger.Enabled = $True
$TaskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Compatibility 'Win8'
$TaskPrincipal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType 'ServiceAccount' -RunLevel 'Highest'
$Task = New-ScheduledTask -Description $Taskdescription -Action $TaskAction -Settings $TaskSettings -Trigger $TaskTrigger -Principal $TaskPrincipal
Register-ScheduledTask -InputObject $Task -TaskName $TaskName | Out-Null


