$AVDShutDownTaskName = "AVD-CreateDeviceShutdownEventTriggeredSchdTask"
Disable-ScheduledTask -TaskName $AVDShutDownTaskName 
Enable-ScheduledTask -TaskName $AVDShutDownTaskName