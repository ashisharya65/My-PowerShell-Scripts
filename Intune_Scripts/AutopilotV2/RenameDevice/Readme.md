# Renaming Device During Autopilot V2 Profile Deployment

Renaming devices during the deployment of an Autopilot V2 profile, also known as the **Windows Autopilot device preparation** profile, can be a critical step in ensuring that devices adhere to organizational naming conventions from the moment they are enrolled in Intune. However, one of the challenges faced during this process is that there is no native option to rename the device while it is enrolling into Intune as part of the Autopilot process.

To address this challenge, a customized approach can be employed, allowing devices to be renamed during the Enrollment Status Page (ESP) phase of the deployment. This process involves the use of a Win32 app that is designed to create and manage two scheduled tasks that facilitate the renaming operation.

## The Customized Approach

### 1. Creating a Win32 App
The process begins by creating a Win32 app that will be deployed during the Autopilot deployment. This app is responsible for setting up two scheduled tasks:

- **`Post-ESPReboot`:** This task monitors for `Event ID 4725`, which is logged when the `defaultuser0` account is disabled. The occurrence of this event signifies that the ESP phase is complete. Upon detecting this event, the task triggers the execution of the `Reboot.ps1` script.

- **`Post-ESPReboot-Notification`:** Triggered by the `Reboot.ps1` script, this task runs a secondary script called `Toast.ps1`, which displays a notification to the user.

### 2. Executing the Reboot.ps1 Script
Once the ESP phase is completed and `Event ID 4725` is detected, the `Reboot.ps1` script is invoked. This script serves as the central point of coordination between the two scheduled tasks. It waits for the completion of the `Post-ESPReboot-Notification` task before proceeding with any further actions.

### 3. User Interaction Through Toast.ps1
The `Toast.ps1` script is responsible for displaying a graphical user interface (GUI) to the user, prompting them with two options:

- **Yes:** If the user selects this option, a `Reboot.ps1.tag` file is created in a specified directory. This file is used as a detection mechanism by the Win32 app to confirm that the user has approved the reboot.

- **No:** Selecting this option results in no action being taken, and the GUI window simply closes.

### 4. Final Decision and Reboot
After the `Post-ESPReboot-Notification` task completes, control returns to the `Reboot.ps1` script. The script checks for the existence of the `Reboot.ps1.tag` file. If the file is present, it indicates that the user opted to reboot the device. The script then proceeds to restart the machine, ensuring that the device renaming is applied as part of the reboot process.

If the `Reboot.ps1.tag` file is not found, the script logs that the user selected "No," and no reboot will occur. This provides flexibility, allowing the user to defer the reboot if necessary.

## Conclusion

By leveraging this customized approach, organizations can ensure that devices are renamed during the Autopilot V2 profile deployment, even though there is no native support for renaming during the initial enrollment phase. This method not only ensures compliance with naming conventions but also provides a seamless user experience by integrating the renaming process within the familiar framework of Windows Autopilot. Through the use of scheduled tasks and script-driven logic, the solution provides an effective and user-friendly way to manage device renaming during Autopilot deployments.
