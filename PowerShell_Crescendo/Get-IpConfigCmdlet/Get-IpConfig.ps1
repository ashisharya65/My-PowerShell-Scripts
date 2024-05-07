<#
    All the commands which will be helping you to create your own PowerShell cmdlet called Get-IpConfig.
#>

# Install Crescendo
Install-Module -Name Microsoft.PowerShell.Crescendo -Force
# Install using PowerShellGet v3
Install-PSResource Microsoft.PowerShell.Crescendo -Reinstall

# Create a new PowerShell Crescendo configuration
$NewConfiguration = @{
    '$schema' = 'https://aka.ms/PowerShell/Crescendo/Schemas/2021-11'
    Commands = @()
}
$parameters = @{
    Verb = 'Get'
    Noun = 'IpConfig'
    OriginalName = "C:\Windows\System32\ipconfig.exe"
}
$NewConfiguration.Commands += New-CrescendoCommand @parameters

$NewConfiguration | ConvertTo-Json -Depth 3 | Out-File "$($PSScriptRoot)\ipconfig.crescendo.json"

# Use crescendo to create a PowerShell module
Export-CrescendoModule -ConfigurationFile "$($PSScriptRoot)\ipconfig.crescendo.json" -ModuleName ipconfig.crescendo.psm1

# Import the module we just created
Import-Module "$($PSScriptRoot)\ipconfig.crescendo.psd1"

# View commands available in the module
Get-Command -module ipconfig.crescendo

# Run the new cmdlet, notice that all it is doing currently is running ipconfig.exe, with no arguments
Get-IpConfig

# clean up the powershell module before we make changes and re-import the module
Remove-Module ipconfig.crescendo
Remove-Item .\ipconfig.crescendo.psd1
Remove-Item .\ipconfig.crescendo.psm1

# Use crescendo to create the PowerShell module again
Export-CrescendoModule -ConfigurationFile .\docker.crescendo.json -ModuleName docker.crescendo.psm1

# Import the module we just created
Import-Module .\docker.crescendo.psd1

# Call Get-IpConfig with the -all parameter, which will show all the ip addresses assigned to the machine
Get-IpConfig -all


