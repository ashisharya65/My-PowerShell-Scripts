<#
.SYNOPSIS
    Displays a survey window and handles user interactions.

.DESCRIPTION
    This PowerShell script creates a graphical window using XAML to display a survey message. It includes buttons for completing the 
    survey or doing it later. The script also manages registry keys to track survey completion status.

.NOTES
    Author         : Ashish Arya
    Prerequisite   : Requires the PresentationFramework assembly.
#>

# Add-Type cmdlet to load the PresentationFramework assembly
Add-Type -AssemblyName PresentationFramework

# XAML content for the window
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" 
        Title="Your Voice Matters!" Height="200" Width="525" WindowStartupLocation="CenterScreen" Background="#7199D7" FontSize="16" FontFamily="Cambria">
    <Grid>
        <!-- TextBlock for the main message -->
        <TextBlock TextAlignment="Center" VerticalAlignment="Top" Margin="10" Foreground="#000000" FontSize="16">
            <Run FontSize="16">Your feedback is vital to improving our services.</Run>
            <LineBreak/>
            <Run FontSize="16">Please complete this mandatory survey</Run>
            <Run FontSize="16" xml:space="preserve" Foreground="Blue"> now </Run> <!-- Bold "now" text -->
            <Run FontSize="16" Foreground="#000000">to help us serve you better.</Run>
            <LineBreak/>
        </TextBlock>
        
        <!-- TextBlock for the duration -->
        <TextBlock TextAlignment="Center" VerticalAlignment="Center" Margin="10" Foreground="White">
            <Run FontSize="14" FontWeight="Bold" xml:space="preserve" Foreground="#000000">Duration: 3mins</Run> <!-- Bold duration text -->
        </TextBlock>
        
        <!-- StackPanel for buttons -->
        <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Bottom" Margin="10">
            <Button FontSize="14" FontWeight="Bold" Name="FillSurveyButton" Content="Complete the Survey" Width="160" Height="30" Margin="15" Background="#5920EC" Foreground="#FFFFFF">
                <Button.Template>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="10" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Button.Template>
            </Button>
            <Button FontSize="14" FontWeight="Bold" Name="DoItLaterButton" Content="Do it Later" Width="150" Height="30" Margin="15" Background="#606063" Foreground="#FFFFFF">
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


# Create a new Window from the XAML
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$form = [Windows.Markup.XamlReader]::Load($reader)

# Load Controls
$fillSurveyButton = $form.FindName("FillSurveyButton")
$doItLaterButton = $form.FindName("DoItLaterButton")

# Function to create the registry keys
Function Create-RegKey {
    param(
        $RegKeyValue,
        $KeyPath = "HKCU:\Software\Total\RemediationScripts\FillSurvey",
        $Keyname = "IsSurveyFilled",
        $KeyType = "String"
    )

    #Verify if the registry path already exists
    if(!(Test-Path $KeyPath)) {
        try {
            #Create registry path
            New-Item -Path $KeyPath -Force -ErrorAction Stop
        }
        catch {
            Write-Output "FAILED to create the registry path"
        }
    }
    #Verify if the registry key already exists
    if($null -eq (((Get-ItemProperty $KeyPath).$KeyName))){
        try {
            #Create registry key 
            New-ItemProperty -Path $KeyPath -Name $KeyName -PropertyType $KeyType -Value $RegKeyValue -ErrorAction 'stop'
        }
        catch {
            Write-Output "FAILED to create the registry key"
        }
    }
    elseif((Get-ItemProperty $KeyPath).$KeyName) {
        try {
            #Create registry key 
            Set-ItemProperty -Path $KeyPath -Name $KeyName -Value $RegKeyValue -ErrorAction 'stop'
        }
        catch {
            Write-Output "FAILED to create the registry key"
        }
    }
}

# Action for the FillSurvey button
$fillSurveyButton.Add_Click({
    # Open a web browser to the survey link
    $SurveyLink = "https://google.com"
    Start-Process $SurveyLink 

    # Set registry key to indicate survey completion
    Create-RegKey -RegKeyValue $true 
    $form.close() # Close the form
})

# Action for the DoItLater button
$doItLaterButton.Add_Click({
    # Set registry key to indicate survey not completed
    Create-RegKey -RegKeyValue $false 

    # Close the form
    $form.Close() 
})

# Show the form
$form.ShowDialog() | Out-Null
