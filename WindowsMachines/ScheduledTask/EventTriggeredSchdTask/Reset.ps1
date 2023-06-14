$TaskName = "AVD shutdown on User Logoff event"
Disable-ScheduledTask -TaskName $TaskName 
Enable-ScheduledTask -TaskName $TaskName