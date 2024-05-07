# This is a set of commands that accompanies a blog post and Youtube video about PowerShell Crecsendo

# Install Crescendo
Install-Module -Name Microsoft.PowerShell.Crescendo -Force
# Install using PowerShellGet v3
Install-PSResource Microsoft.PowerShell.Crescendo -Reinstall

# Here are the native docker commands
docker container list
docker container list --all

# Create a new PowerShell Crescendo configuration
$NewConfiguration = @{
    '$schema' = 'https://aka.ms/PowerShell/Crescendo/Schemas/2021-11'
    Commands = @()
}
$parameters = @{
    Verb = 'Get'
    Noun = 'DockerContainer'
    OriginalName = "C:\Program Files\Docker\Docker\resources\bin\docker.exe"
}
$NewConfiguration.Commands += New-CrescendoCommand @parameters

$NewConfiguration | ConvertTo-Json -Depth 3 | Out-File .\docker.crescendo.json


# Use crescendo to create a PowerShell module
Export-CrescendoModule -ConfigurationFile .\docker.crescendo.json -ModuleName docker.crescendo.psm1

# Import the module we just created
Import-Module .\docker.crescendo.psd1

# View commands available in the module
Get-Command -module docker.crescendo

# Run the new cmdlet, notice that all it is doing currently is running docker.exe, with no arguments
Get-DockerContainer

# Go back to the JSON file and add in some arguments by adding OriginalCommandElements

# clean up the powershell module before we make changes and re-import the module
Remove-Module docker.crescendo
Remove-Item .\docker.crescendo.psd1
Remove-Item .\docker.crescendo.psm1

# Use crescendo to create the PowerShell module again
Export-CrescendoModule -ConfigurationFile .\docker.crescendo.json -ModuleName docker.crescendo.psm1

# Import the module we just created
Import-Module .\docker.crescendo.psd1

# Run the new cmdlet, this time is should run docker container list, and show that output
Get-DockerContainer

# clean up the powershell module before we make changes and re-import the module
Remove-Module docker.crescendo
Remove-Item .\docker.crescendo.psd1
Remove-Item .\docker.crescendo.psm1

# Go back to the JSON file and add arguments so the native command exports a string of JSON as a response

# Use crescendo to create a PowerShell module
Export-CrescendoModule -ConfigurationFile .\docker.crescendo.json -ModuleName docker.crescendo.psm1

# Import the module
Import-Module .\docker.crescendo.psd1

# Run Get-DockerContainer again, observe that this time we are getting a string of JSON as
# a response, and we could now pipe that to ConvertFrom-Json to get a native PowerShell object
Get-DockerContainer
Get-DockerContainer | ConvertFrom-Json

# Go back to the JSON file and add an output handler

# clean up
Remove-Module docker.crescendo
Remove-Item .\docker.crescendo.psd1
Remove-Item .\docker.crescendo.psm1

# Use crescendo to create a PowerShell module
Export-CrescendoModule -ConfigurationFile .\docker.crescendo.json -ModuleName docker.crescendo.psm1

# Import the module
Import-Module .\docker.crescendo.psd1

# Run Get-DockerContainer again, this time we will get a native JSON object and won't
# need to perform any conversion ourselves
Get-DockerContainer

# Now let's add in a parameter

# clean up
Remove-Module docker.crescendo
Remove-Item .\docker.crescendo.psd1
Remove-Item .\docker.crescendo.psm1

# Go back to the JSON file and add a parameter named 'all', to call the underlying '--all' argument
# Use crescendo to create a PowerShell module
Export-CrescendoModule -ConfigurationFile .\docker.crescendo.json -ModuleName docker.crescendo.psm1

# Import the module
Import-Module .\docker.crescendo.psd1

# Make Sure Get-DockerContainer with no parameters still does what we want
Get-DockerContainer

# Call Get-DockerContainer with the -all parameter, which will show all running and not running containers
Get-DockerContainer -all
Get-DockerContainer -all | Select-Object names

# See the help for crescendo
get-help about_crescendo
