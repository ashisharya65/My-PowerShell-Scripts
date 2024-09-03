<#
.SYNOPSIS
    This script automates the creation and management of scheduled tasks and related files for post ESP (Enrollment Status Page) reboot operations in an Intune-managed environment.

.DESCRIPTION
    The script performs several tasks:
    - Creates necessary directories and log files if they do not exist.
    - Generates and stores PowerShell scripts for displaying Post-ESPReboot-Notification and handling Post-ESPReboot processes.
    - Sets up scheduled tasks to execute the Post-ESPReboot-Notification and post-ESPReboot scripts based on specific triggers.
    - Logs the progress and any errors encountered during script execution.

.PARAMETER PostESPRebootFolderPath
    The directory path where the Post-ESPReboot and Post-ESPReboot-Notification scripts will be stored. Defaults to "C:\Temp\PostESPReboot".

.PARAMETER PostESPRebootNotificationScriptPath
    The file path for the toast notification script. Defaults to "C:\Temp\PostESPReboot\Toast.ps1".

.PARAMETER PostESPRebootScriptPath
    The file path for the post-ESP reboot script. Defaults to "C:\Temp\PostESPReboot\Post-ESPReboot.ps1".

.PARAMETER LogFolderPath
    The directory path where log files for the device rename process will be stored. Defaults to "$env:ProgramData\Microsoft\RenameDevice".

.PARAMETER LogFilePath
    The file path for the main log file. Defaults to "$LogFolderPath\RenameDeviceLog.log".

.FUNCTION Write-Log
    Logs messages with a timestamp to the specified log file. Supports 'Info' and 'Error' log levels.

.FUNCTION New-Post-ESPRebootSchdTask
    Creates a scheduled task that triggers the Post-ESPReboot script when a specific event (event ID 4725) is logged.

.FUNCTION New-Post-ESPReboot-NotificationSchdTask
    Creates a scheduled task that triggers the Post-ESPReboot-Notification script, which shows the popup to the user that the computer will restart soon.

.NOTES
    Author: Ashish Arya
    Date: 18-August-2024
    Version: 1.0
    This script is intended for use in environments managed by Intune and requires administrative privileges to run.

.EXAMPLE
    .\Post-ESPRebootSetup.ps1
    This command runs the script with default parameters, setting up the necessary scripts and scheduled tasks.

#>


[cmdletbinding()]
param(
    [string] $PostESPRebootFolderPath = "C:\Temp\Post-ESPReboot",
    [string] $LogFilePath = $PostESPRebootFolderPath + "\Logs\Post-ESPReboot-InstallScriptLog.log",
    [string] $PostESPRebootNotificationScriptPath = $PostESPRebootFolderPath + "\Post-ESPReboot-Notification.ps1",
    [string] $PostESPRebootScriptPath = $PostESPRebootFolderPath + "\Post-ESPReboot.ps1",
    [string] $PostESPRebootSchdTask = "Post-ESPReboot",
    [string] $PostESPRebootNotificationSchdTask = "Post-ESPReboot-Notification",
    [string] $DetectionTag = $PostESPRebootFolderPath + "\DetectionTag.ps1.tag"
)

# Function for logging
Function Write-Log {
    param(
        [parameter(mandatory)]
        [ValidateSet('Info','Error')]
        [String] $Level,
        
        [Parameter(mandatory)]
        [string] $Message
    )
    $CurrentDate = Get-Date -format "dd-MM-yyyy hh:mm:ss"
    $logmessage = "$($CurrentDate) [$Level] - $Message"
    Add-Content -path $LogFilePath -Value $logmessage -force
}

# Post-ESPReboot-Notification script content
$PostESPRebootNotificationScriptContent = 
@"
# Add-Type cmdlet to load the PresentationFramework assembly
Add-Type -AssemblyName PresentationFramework

[cmdletbinding()]

param(
    [string] `$LogFolderPath = "C:\Temp\Post-ESPReboot",
    [string] `$LogFilePath = `$LogFolderPath + "\Logs\Post-ESPReboot-NotificationScriptLog.log"
)

Function Write-Log {
    param(
        [parameter(mandatory)]
        [ValidateSet('Info', 'Error')]
        [String] `$Level,
        
        [Parameter(mandatory)]
        [string] `$Message
    )
    `$CurrentDate = Get-Date -format "dd-MM-yyyy hh:mm:ss"
    `$logmessage = "`$(`$CurrentDate) [`$Level] - `$Message"
    Add-Content -path `$LogFilePath -Value `$logmessage -force
}

Write-Log -Level 'Info' -Message "Script execution started."

# XAML content for the window
[xml]`$xaml = @`
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" 
        Title="Device is restarting ⚠️" Height="200" Width="400" WindowStartupLocation="CenterScreen" Foreground="#000000" Background="#7199D7" FontSize="16" FontFamily="Cambria"
        Icon="C:\Users\aarya1\Downloads\Bechtel.ico"
        Topmost="True">
    <Grid>
        <!-- StackPanel for the icon and text -->
        <StackPanel Orientation="Vertical" HorizontalAlignment="Center" VerticalAlignment="Top" Margin="10">
            <!-- Image control to display a larger version of the icon -->
            <Image Source="C:\Users\aarya1\Downloads\Bechtel_Logo_RGB.ico" Width="64" Height="64" Margin="0,0,0,10"/>
            
            <!-- TextBlock for the main message -->
            <TextBlock TextAlignment="Center" Foreground="#000000" FontSize="16">
                <Run FontSize="16">Your device is going to restart in </Run>
                <Bold>10 minutes</Bold>.
                <LineBreak/>
                <Run FontSize="16">Please save all work before restart.</Run>
            </TextBlock>
        </StackPanel>
        
        <!-- StackPanel for buttons -->
        <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Bottom" Margin="10">
            <Button FontSize="14" FontWeight="Bold" Name="OkButton" Content="OK" Width="80" Height="30" Margin="15" Background="#5920EC" Foreground="#FFFFFF">
                <Button.Template>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="10" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Button.Template>
            </Button>
        </StackPanel>
    </Grid>
</Window>
`@

# Create a new Window from the XAML
`$reader = (New-Object System.Xml.XmlNodeReader `$xaml)
`$form = [Windows.Markup.XamlReader]::Load(`$reader)

# Load Controls
`$OKButton = `$form.FindName("OkButton")

# Action for the FillSurvey button
`$OKButton.Add_Click({
    `$form.close() # Close the form
})

# Show the form
`$form.ShowDialog() | Out-Null

Write-Log -Level 'Info' -Message "Script execution ended."

"@

# Post ESP Reboot script content
$PostESPRebootScriptContent = 
@"

[cmdletbinding()]

param(
    [string] `$PostESPRebootFolderPath = "C:\Temp\Post-ESPReboot",
    [string] `$PostESPRebootNotificationScriptPath = `$PostESPRebootFolderPath + "\Post-ESPReboot-Notification.ps1",
    [string] `$PostESPRebootSchdTask = "Post-ESPReboot",
    [string] `$PostESPRebootNotificationSchdTask = "Post-ESPReboot-Notification",
    [string] `$LogFilePath = `$PostESPRebootFolderPath + "\Logs\Post-ESPRebootScriptLog.log"
)

Function Write-Log {
    param(
        [parameter(mandatory)]
        [ValidateSet('Info','Error')]
        [String] `$Level,
        
        [Parameter(mandatory)]
        [string] `$Message
    )
    `$CurrentDate = Get-Date -format "dd-MM-yyyy hh:mm:ss"
    `$logmessage = "`$(`$CurrentDate) [`$Level] - `$Message"
    Add-Content -path `$LogFilePath -Value `$logmessage -force
}

Write-Log -Level 'Info' -Message "Script execution started."
Try {
    Start-ScheduledTask -TaskName `$PostESPRebootSchdTask -erroraction 'Stop'
    Write-Log -Level 'Info' -Message "Successfully started the `$PostESPRebootSchdTask scheduled task."
    Start-Sleep -seconds 600
    Write-Log -Level 'Info' -Message "Sleeping for 10 mins."
}
Catch {
    `$err = `$_.Exception.Message
    Write-Log -Level 'Error' -Message "Unable to start the `$PostESPRebootSchdTask scheduled task: `$err."
}

Disable-ScheduledTask -taskName `$PostESPRebootSchdTask -Erroraction 'silentlycontinue' | Out-Null
Disable-Scheduledtask -taskName `$PostESPRebootNotificationSchdTask -ErrorAction 'Continue' | Out-Null
Unregister-ScheduledTask -taskName `$PostESPRebootSchdTask -confirm:`$false
Unregister-ScheduledTask -taskName `$PostESPRebootNotificationSchdTask -confirm:`$false

Write-Log -Level 'Info' -Message "Successfully disabled and unregister both `$PostESPRebootSchdTask and `$PostESPRebootNotificationSchdTask scheduled tasks."

Remove-Item -path `$PostESPRebootNotificationScriptPath -Force
Write-Log -Level 'Info' -Message "Removing the Post-ESPReboot-Notification script."

Write-Log -Level 'Info' -Message "Successfully initiated the reboot command."
Write-Log -Level 'Info' -Message "Script execution ended."
Restart-Computer -Force -Verbose

"@

# If the script the Post-ESPReboot, Post-ESPReboot-Notification scripts and the concerned folder are not there, create it.
if(-not((Test-Path $PostESPRebootFolderPath) -and (Test-Path $PostESPRebootNotificationScriptPath) -and (Test-Path $PostESPRebootScriptPath) -and (Test-Path $LogFilePath))){
    
    Try {

        New-Item -path $LogFilePath -Itemtype 'File' -force |  Out-Null
        Set-Content -Path $DetectionTag -Value "Installed" -erroraction 'Stop'
        Write-Log -Level 'Info' -Message "Script execution started."
        Write-Log -Level 'Info' -Message "Successfully created both the Post-ESPReboot folder and detection tag file."
    }
    Catch {
        $err = $_.Exception.Message
        Write-Log -Level 'Error' -Message "Unable to create the log file as well as the device rename tag file: $err."
    }

    Try {

        Add-Content -path $PostESPRebootScriptPath -Value $PostESPRebootScriptContent -Force -ErrorAction 'Stop'
        Write-Log -Level 'Info' -Message "Post-ESPReboot script was not there. Hence, created the script and added the code to it."
        
        Add-Content -path $PostESPRebootNotificationScriptPath -Value $PostESPRebootNotificationScriptContent -Force -ErrorAction 'Stop'
        Write-Log -Level 'Info' -Message "Post-ESPReboot-Notification script was not there. Hence, created the script and added the code to it."
    }
    catch {
        $err = $_.Exception.Message
        Write-Log -Level 'Error' -Message "Unable to create the Post-ESPReboot and Post-ESPReboot-Notification scripts as well the concerned folder. : $err."
    }
}

# Function to create the Post ESP Reboot scheduled task
Function New-PostESPRebootSchdTask {
    [cmdletbinding()]
    param(
        $PostESPRebootSchdTask = "Post-ESPReboot"
    )

    Try {
        $schdTaskDescription = "Task to execute the Post-ESPReboot script when an event with 4725 id is logged in event viewer."
        $schdTaskArgs = "-noprofile -executionpolicy bypass -file $PostESPRebootScriptPath"
        $schdTaskAction = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument $schdTaskArgs
        $cimTriggerClass = Get-CimClass -ClassName 'MSFT_TaskEventTrigger' -Namespace 'Root/Microsoft/Windows/TaskScheduler:MSFT_TaskEventTrigger'
        $schdTaskTrigger = New-CimInstance -CimClass $cimTriggerClass -ClientOnly

# This is for mentioning the XML query for user account disable event (event id - 4725)
$schdTaskTrigger.Subscription = 
@"
<QueryList>
  <Query Id="0" Path="Security">
    <Select Path="Security">*[System[EventID=4725]]</Select>     
  </Query>
</QueryList>
"@
        $schdTaskTrigger.Enabled = $True
        $schdTaskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Compatibility Win8
        $schdTaskPrincipal = New-ScheduledTaskPrincipal -UserId 'SYSTEM' -LogonType 'ServiceAccount' -RunLevel 'Highest'
        $schdTask = New-ScheduledTask -Description $schdTaskDescription -Action $schdTaskAction -Settings $schdTaskSettings -Trigger $schdTaskTrigger -Principal $schdTaskPrincipal    
        Register-ScheduledTask -InputObject $schdTask -TaskName $PostESPRebootSchdTask -erroraction 'Stop' | Out-Null
        Write-Log -Level 'Info' -Message "Post-ESPReboot scheduled task was created successfully."
    }
    Catch{
        $err = $_.Exception.Message
        Write-Log -Level 'Error' -Message "Unable to create the Post-ESPReboot scheduled task: $err."
    }
   
}

# Function to create the Post ESP Reboot notification scheduled task
Function New-PostESPRebootNotificationSchdTask {
    [cmdletbinding()]
    param(
        $PostESPRebootNotificationSchdTask = "Post-ESPReboot-Notification"
    )

    Try {
        $schdTaskDescription = "Task to execute the Post-ESPReboot-Notification script."
        $schdTaskArgs = "-noprofile -executionpolicy Unrestricted -file $PostESPRebootNotificationScriptPath"
        $schdTaskAction = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument $schdTaskArgs
        $schdTaskTrigger = New-ScheduledTaskTrigger -At "$(Get-Date)" -Once
        $schdTaskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Compatibility Win8
        $schdTaskPrincipal = New-ScheduledTaskPrincipal -GroupId 'S-1-5-32-545'
        $schdTask = New-ScheduledTask -Description $schdTaskDescription -Action $schdTaskAction -Settings $schdTaskSettings -Trigger $schdTaskTrigger -Principal $schdTaskPrincipal    
        Register-ScheduledTask -InputObject $schdTask -TaskName $PostESPRebootNotificationSchdTask -erroraction 'Stop' | Out-Null
        Write-Log -Level 'Info' -Message "Post-ESPReboot-Notification scheduled task was created successfully."
    }
    Catch {
        $err = $_.Exception.Message
        Write-Log -Level 'Error' -Message "Unable to create the Post-ESPReboot-Notification scheduled task : $err."
    }
    
}


# Function calls 
New-PostESPRebootSchdTask
New-PostESPRebootNotificationSchdTask

# Logging the script execution end
Write-Log -Level 'Info' -Message "Script execution ended."
