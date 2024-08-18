# Renaming device during Autopilot V2 profile deployment

- With my testing related to Autopilot V2 profile aka <b>Windows Autopilot device preparation</b> profile, we got no way to rename the device while it is enrolling to Intune.
- We used few customized ways to rename the device during the Intune Enrollment status page (ESP) process.
- Renaming the device still requires a restart from user end.
- If the device gets restarted during the ESP phase, at user ESP, user will again have to authenticate to the device in order to proceed with the rest of the pending steps in ESP.
- So, with this way, we are coming up with creating two schedule tasks.
- One of the scheduled task will monitor the Event id - 4725 (that is logged when the <b>defaultuser0</b> account gets disabled) means wgenever the ESP phase is completed and invoke the Post-ESPReboot script.
- Second scheduled task is response for showing one pop window to save all the work before restart the machine post completion of ESP.
- Here, one way is to deploy a Win32 app storing all the necessary scripts and scheduled task XMLs.
- Second way is to deploy a single script to create the concerned scheduled tasks.
