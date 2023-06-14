# PowerShell scripts to create Event Triggered schedule tasks
- This repo contains the scripts which I used recently to create event triggered schedule task on Intune managed VMs so as to shutdown the unused VMs.
- The [DeviceShutdownEventTriggeredSchdTask](https://github.com/ashisharya65/My-PowerShell-Scripts/blob/main/WindowsMachines/ScheduledTask/EventTriggeredSchdTask/DeviceShutdownEventTriggeredSchdTask.ps1) script will be creating the Scheduled task for monitoring the user log off event (event id - 4647) and will shutdown the device once the event occurs.
