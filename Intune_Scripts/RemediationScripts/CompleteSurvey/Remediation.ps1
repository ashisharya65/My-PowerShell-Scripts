# Add-Type cmdlet to load the PresentationFramework assembly
Add-Type -AssemblyName PresentationFramework

# XAML content for the window
[xml] $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation" 
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml" 
        Title="Complete Survey!" Height="180" Width="430" WindowStartupLocation="CenterScreen">
    <Grid>
        <!-- TextBlock for the main message -->
        <TextBlock TextAlignment="Center" VerticalAlignment="Top" Margin="10">
            <Run>Your feedback is vital to improving our services.</Run>
            <LineBreak/>
            <Run>Please complete this mandatory survey</Run>
            <Run FontWeight="Bold" xml:space="preserve"> now </Run> <!-- Bold "now" text -->
            <Run>to help us serve you better.</Run>
            <LineBreak/>
        </TextBlock>
        
        <!-- TextBlock for the duration -->
        <TextBlock TextAlignment="Center" VerticalAlignment="Center" Margin="10">
            <Run FontWeight="Bold" xml:space="preserve">Duration: 3mins</Run> <!-- Bold duration text -->
        </TextBlock>
        
        <!-- StackPanel for buttons -->
        <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" VerticalAlignment="Bottom" Margin="10">
            <Button Name="FillSurveyButton" Content="Complete the Survey" Width="118" Margin="10"/>
            <Button Name="DoItLaterButton" Content="Do it Later" Width="90" Margin="10"/>
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
        $KeyPath = "HKLM:\SOFTWARE\CustomReg\FillSurvey",
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
    Start-Process "Survey URL" 

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