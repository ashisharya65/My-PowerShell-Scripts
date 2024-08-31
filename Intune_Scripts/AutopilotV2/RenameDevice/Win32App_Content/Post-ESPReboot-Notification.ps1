<#
.SYNOPSIS
This script displays a user interface (UI) that prompts the user to reboot their device. The user's choice is logged, and a detection tag file is created if the user agrees to reboot.

.DESCRIPTION
The script performs the following actions:
1. Loads the PresentationFramework assembly to create a WPF-based UI.
2. Initializes paths for log files and a detection tag file.
3. Defines a logging function to capture the execution flow and any issues.
4. Ensures the log file is created if it does not already exist.
5. Displays a UI with "Yes" and "No" buttons prompting the user to reboot their device.
6. Logs the user's choice and creates a detection tag file if the "Yes" button is clicked.

.PARAMETER Level
Specifies the log level ("Info" or "Error") for the `Write-Log` function.

.PARAMETER Message
The message to be logged, associated with the specified log level.

.NOTES
Author: [Ashish Arya]
Date: [31-Aug-2024]
Version: 1.0

.EXAMPLE
PS C:\> .\Toast.ps1
This command executes the script, showing a UI to the user and logging their response regarding the reboot.

#>


# Load the PresentationFramework assembly, required to create the WPF-based UI.
Add-Type -AssemblyName PresentationFramework

# Define paths for the log file and detection tag file.
$LogFolderPath = "C:\Temp\Rename-Device"
$LogFilePath = $LogFolderPath + "\Toast.log"
$DetectionTagFilePath = $LogFolderPath + "\Reboot.ps1.tag"

# Define a function for logging messages to the log file with a timestamp.
Function Write-Log {
    param(
        [parameter(mandatory)]
        [ValidateSet("Info", "Error")]
        [String] $Level,
        
        [Parameter(mandatory)]
        [string] $Message
    )
    $CurrentDate = Get-Date -format "dd-MM-yyyy hh:mm:ss"
    $logmessage = "$($CurrentDate) [$Level] - $Message"
    
    # Append the log message to the log file.
    Add-Content -path $LogFilePath -Value $logmessage -force
}

# Check if the log file exists. If not, create it and log the initialization of the script.
if (-not(Test-Path $LogFilePath)) {
    Try {
        # Create the log file and log the start of the script.
        New-Item -path $LogFilePath -Itemtype "File" -force -erroraction "stop" | Out-Null
        Write-Log -Level "Info" -Message "Script execution started."
        Write-Log -Level "Info" -Message "Log file created at '$($LogFilePath)' path."
    }
    Catch {
        # Log an error if the log file creation fails.
        $err = $_.exception.message
        Write-Log -Level "Error" -Message "Error: Issue in creating either the log file or detection file. '$err'."
    }
   
}
 
# Define the XAML content for the WPF window, which includes the UI elements.
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" 
        Title="Your device needs a reboot !!!" Height="170" Width="515" WindowStartupLocation="CenterScreen" Foreground="#000000" Background="#7199D7" FontSize="16" FontFamily="Cambria">
    <Grid>
        <!-- TextBlock for the main message -->
        <TextBlock TextAlignment="Center" VerticalAlignment="Top" Margin="10" Foreground="#000000" FontSize="16">
            <LineBreak/>
            <Run FontSize="16">Please reboot your device to ensure all the configurations are applied.</Run>
            <LineBreak/>
            <Run FontSize="16">Click</Run>
            <Run FontSize="16" xml:space="preserve" Foreground="Blue"> Yes </Run> <!-- Bold "now" text -->
            <Run FontSize="16" Foreground="#000000">to reboot your device or </Run>
            <Run FontSize="16" xml:space="preserve" Foreground="Blue"> No </Run> <!-- Bold "now" text -->
            <Run FontSize="16" Foreground="#000000">to close the window.</Run>
        </TextBlock>
               
        <!-- StackPanel for buttons -->
        <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Bottom" Margin="10">
            <Button FontSize="14" FontWeight="Bold" Name="YesButton" Content="Yes" Width="80" Height="30" Margin="15" Background="#5920EC" Foreground="#FFFFFF">
                <Button.Template>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="10" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Button.Template>
            </Button>
            <Button FontSize="14" FontWeight="Bold" Name="NoButton" Content="No" Width="80" Height="30" Margin="15" Background="#5920EC" Foreground="#FFFFFF">
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
"@

# Create a new WPF window from the XAML definition.
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$form = [Windows.Markup.XamlReader]::Load($reader)

# Load the "Yes" and "No" buttons from the WPF window.
$YesButton = $form.FindName("YesButton")
$NoButton = $form.FindName("NoButton")

# Define the action for when the "Yes" button is clicked.
$YesButton.Add_Click({
        # Create the detection tag file and log the user's decision to reboot.
        New-Item -path $DetectionTagFilePath -ItemType "File" -force | Out-Null
        Write-Log -Level "Info" -Message "The user clicked on 'Yes' button."
        Write-Log -Level "Info" -Message "Script execution ended."
        Write-Log -Level "Info" -Message "The detection tag file also got created at '$($DetectionTagFilePath)' path."
        $form.close() 
    })

# Define the action for when the "No" button is clicked.
$NoButton.Add_Click({
        # Log the user's decision not to reboot and close the window.
        Write-Log -Level "Info" -Message "The user clicked on 'No' button so no reboot will happen."
        Write-Log -Level "Info" -Message "Script execution ended."
        $form.close() 
    })

# Display the WPF window to the user.
$form.ShowDialog() | Out-Null

