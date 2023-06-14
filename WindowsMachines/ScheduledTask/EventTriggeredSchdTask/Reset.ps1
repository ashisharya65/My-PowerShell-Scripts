$TaskName = "Device Shutdown on User Logoff event"
Disable-ScheduledTask -TaskName $TaskName 
Enable-ScheduledTask -TaskName $TaskName
