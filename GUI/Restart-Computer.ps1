<#
    Script to create a WPF form that gives you the option to either restart your device or cancel the restart.
#>

# Loading the assembly
Add-Type -AssemblyName PresentationFramework

# Define WPF XAML
$inputXAML = @"
<Window x:Class="Restart_Computer.MainWindow"
        xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        xmlns:d="http://schemas.microsoft.com/expression/blend/2008"
        xmlns:mc="http://schemas.openxmlformats.org/markup-compatibility/2006"
        xmlns:local="clr-namespace:Restart_Computer"
        mc:Ignorable="d"
        Title="Restart-Computer" Height="190" Width="474">
    <Grid>
        <Label Content="The Drive redirection policy is allowed now." HorizontalAlignment="Left" Margin="121,26,0,0" VerticalAlignment="Top"/>
        <Label Content="Do you want to restart your machine to reflect the changes asap?" HorizontalAlignment="Left" Margin="54,48,0,0" VerticalAlignment="Top"/>
        <Button x:Name="YesButton" Content="Yes" HorizontalAlignment="Left" Margin="127,90,0,0" VerticalAlignment="Top" Height="29" Width="40" FontWeight="Bold" FontSize="14"/>
        <Button x:Name="NoButton" Content="No" HorizontalAlignment="Left" Margin="298,90,0,0" VerticalAlignment="Top" Height="29" Width="40" FontWeight="Bold" FontSize="14" RenderTransformOrigin="-0.297,1.331"/>

    </Grid>
</Window>
"@

# Correcting the XML
$inputXAML = $inputXAML -replace 'mc:Ignorable="d"', '' -replace "x:N", "N" -replace '^<Win.*', '<Window'
[xml]$xaml = $inputXAML

# Parse XAML
$reader = (New-Object System.Xml.XmlNodeReader $xaml) 
$Window = [Windows.Markup.XamlReader]::Load($reader)

#Load Controls
$YesButton = $Window.FindName('YesButton')
$NoButton = $Window.FindName('NoButton')

# Button Click controls
$YesButton.add_click({
        $Message = "Your computer is going to restart in next 10 minutes. Please save your work and wait for scheduled restart."
        Shutdown.exe -r -f -t 600
        $Window.close()
    })

$NoButton.add_click({
        $Message = "The scheduled restart has been cancelled."
        shutdown.exe -a 
        $Window.close()
    })

# Show Window
$Window.ShowDialog() | Out-Null
