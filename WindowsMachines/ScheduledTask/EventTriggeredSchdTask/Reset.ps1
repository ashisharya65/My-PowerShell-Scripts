$DeviceShutDownTaskName = "DeviceShutdownEventTriggeredSchdTask"
Disable-ScheduledTask -TaskName $DeviceShutDownTaskName 
Enable-ScheduledTask -TaskName $DeviceShutDownTaskName
