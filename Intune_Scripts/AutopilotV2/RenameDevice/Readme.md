# Renaming Device During Autopilot V2 Profile Deployment

- During my testing related to the Autopilot V2 profile, also known as the **Windows Autopilot device preparation** profile, I found that there is no native option to rename the device while it is enrolling into Intune.
- We employed a customized method to rename the device during the Intune Enrollment Status Page (ESP) process, as renaming the device still requires a restart initiated by the user.
- In this approach, we will create a Win32 app that sets up two scheduled tasks.
- The first scheduled task, `Post-ESPReboot`, monitors `Event ID 4725` (which is logged when the `defaultuser0` account is disabled). This indicates that the ESP phase is complete and triggers the `Reboot.ps1` script.
- The `Reboot.ps1` script then triggers the second scheduled task, `Post-ESPReboot-Notification`, which runs another script called `Toast.ps1`.
- The `Reboot.ps1` script waits for the `Post-ESPReboot-Notification` scheduled task to complete.
- The second scheduled task, `Post-ESPReboot-Notification`, displays a pop-up window with two options: clicking the `Yes` button or the `No` button.
- If the user clicks the `Yes` button, a `Reboot.ps1.tag` file is created in the specified path. This tag file is used as a detection file for the Win32 app.
- If the user clicks the `No` button, no action is taken, and the GUI window closes.
- Once the second scheduled task, `Post-ESPReboot-Notification`, is completed, control returns to the `Reboot.ps1` script (associated with the first scheduled task, `Post-ESPReboot`).
- The script then checks whether the `Reboot.ps1.tag` file was created. If the file exists, the script will restart the machine; otherwise, it will log a message indicating that the user clicked the No button and no restart will occur.
