<#
    .SYNOPSIS
        PowerShell GUI app for a scheduled restart.
    .DESCRIPTION
        This is a PowerShell script that will show a form to prompt the user for a scheduled restart in next 10 minutes.
    .NOTES
        Author : Ashish Arya
        Date   : 26-March-2024
    .EXAMPLE
        .\Restart-Computer.ps1
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
        <Label Content="The Drive redirection policy is allowed now." HorizontalAlignment="Left" Margin="108,22,0,0" VerticalAlignment="Top"/>
        <Label Content="Do you want to restart your machine to reflect the changes?" HorizontalAlignment="Left" Margin="54,48,0,0" VerticalAlignment="Top"/>
        <Button x:Name="YesButton" Content="Yes" HorizontalAlignment="Left" Margin="120,88,0,0" VerticalAlignment="Top" Height="29" Width="40" FontWeight="Bold" FontSize="14"/>
        <Button x:Name="NoButton" Content="No" HorizontalAlignment="Left" Margin="291,88,0,0" VerticalAlignment="Top" Height="29" Width="40" FontWeight="Bold" FontSize="14" RenderTransformOrigin="-0.297,1.331"/>

    </Grid>
</Window>
"@

# Correcting the XAML
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
        Shutdown.exe -r -f -t 600
        $Window.close()
    })

$NoButton.add_click({
        shutdown.exe -a 
        $Window.close()
    })

# Show Window
$Window.ShowDialog() | Out-Null
