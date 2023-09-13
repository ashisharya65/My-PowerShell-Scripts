<#
    .SYNOPSIS
    PowerShell script to install those apps & PowerShell modules which you need on a fresh machine.

    .DESCRIPTION
    PowerShell Script to install my favorite apps and my favourite PowerShell modules which I need on a fresh device using Windows inbuilt package manager winget.
    This script assumes that WSL is already installed.

    .NOTES
    Author : Ashish Arya
    Date   : 24-Feb-2023

#>

# Setting the execution policy to bypass
Set-ExecutionPolicy Bypass -Scope CurrentUser -Force

# Getting the current user information
$CurrentWindowsIdentity = [System.Security.Principal.WindowsIdentity]::GetCurrent()

# Creating WindowsPrincipal class's object and passing the current user object
$CurrentWindowsPrincipal = New-Object System.Security.Principal.WindowsPrincipal($CurrentWindowsIdentity)

If ($CurrentWindowsPrincipal.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {

    # Installing few of the applications on your device
    @(  
        [PSCustomObject]@{
            Name = ".NET SDK"
            Id   = "Microsoft .NET SDK"
        },
        [PSCustomObject]@{
            Name = "Google Chrome"
            Id   = "Google.Chrome"
        },
        [PSCustomObject]@{
            Name = "PowerShell"
            Id   = "Microsoft.PowerShell"
        },
        [PSCustomObject]@{
            Name = "Oh-My-Posh"
            Id   = "JanDeDobbeleer.OhMyPosh"
        },
        [PSCustomObject]@{
            Name = "Visual Studio Code"
            Id   = "Microsoft.VisualStudioCode"
        },
        [PSCustomObject]@{
            Name = "Azure Bicep"
            Id   = "Microsoft.Bicep"
        },
        [PSCustomObject]@{
            Name = "Azure CLI"
            Id   = "Microsoft.AzureCLI"
        },
        [PSCustomObject]@{
            Name = "GitHub Desktop"
            Id   = "GitHub.GitHubDesktop"
        },
        [PSCustomObject]@{
            Name = "Git"
            Id   = "Git.Git"
        },
        [PSCustomObject]@{
            Name = "Go"
            Id   = "GoLang.go"
        },
        [PSCustomObject]@{
            Name = "Windows Terminal"
            Id   = "Microsoft.WindowsTerminal"
        },
        [PSCustomObject]@{
            Name = "Functions Core Tools"
            Id   = "Microsoft.Azure.FunctionsCoreTools"
        }
    ) | Foreach-Object {
        If ($_.Name -eq ".NET SDK") {
            #Getting all the available .Net SDKs using winget package manager 
            $DotNetSDKs = winget search $_.Id

            #Skipping the headers and the .NET SDK's preview version
            $SDKsNewList = $DotNetSDKs | Select-Object -Skip 4 

            # replace 2 or more spaces with ONE comma
            $NewData = $SDKsNewList -replace '[ ]{2,}', ','

            # Convert plain text to PowerShell object with custom headers
            $Result = $NewData | ConvertFrom-Csv -Header 'Name', 'Id', 'Version', 'Source'

            #Installing the latest dotnet SDK using winget
            winget install "$($Result[0].Name)" --silent --force | Out-Null

            Write-Host "`n .Net SDK's latest version, has been successfully installed on the device.`n" -ForegroundColor 'Green'
        }
        Else {
            winget install --id $_.Id --force --silent | Out-Null
            Write-Host "`n $($_.Name) latest version has been installed on the device.`n" -ForegroundColor 'Green'
        }
    }

    # Enabling and installing the Windows Subsystem for linux (WSL) on your device
    Try{
        dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart
        dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart
        Write-Host "WSL componenet have been enabled on this machine" -Foregroundcolor "Green"
    }
    Catch {
        $errormessage = $_.Exception.Message
        Write-Host "$($errormessage)" -ForegroundColor 'Red'
    }

    Write-Host "Installing Ubuntu distro WSL" -f 'Yellow'
    wsl --install -d 'Ubuntu-22.04'

    # Installing required PowerShell modules
    @(
        "Az",
        "Microsoft.Graph",
        "MSAL.PS",
        "oh-my-posh",
        "PSHTML",
        "Pode"

    ) | Foreach-Object { 

        Try {
            Write-Host "Installing the $_ powershell module on the system.." -ForegroundColor 'Yellow'
            Install-Module $_ -Scope CurrentUser -Force -erroraction 'Stop' | Out-Null
            Write-Host "$_ powershell module is now installed on the device." -ForegroundColor 'Green'
        }
        Catch{
            $errormessage = $_.Exception.Message
            Write-Host "$($errormessage)" -ForegroundColor 'Red'
        }
    }

    # Setting Terraform Folder and its executable path
    Write-Host "Setting the Terraform path in the system." -F 'Yellow'
    $TerrformFolderPath = "C:\terraform"
    $TerraformExecutablePath = $TerrformFolderPath + "\Terraform.exe"
    
    # Check if Terraform folder is created or not. If not, create it.
    If (!(Test-path $TerrformFolderPath)) {
        New-Item -Path $TerrformFolderPath -Itemtype 'Directory' -Force | Out-Null
    }
    Else {
        # Terraform folder is already created and now test if the executable is there at the TerraformFolderPath.
        If (Test-Path $TerraformExecutablePath) {
            # Save currentuser path value 
            $CurrentUserReg = "HKCU:\Environment"
            $CurrentUserPath = (Get-ItemProperty -path $CurrentUserReg).Path

            # Check if $CurrentUserPath contains $TerrformFolderPath. If not, add the terraform path to the path environment variable.
            If ($CurrentUserPath.contains($TerrformFolderPath)) {
                Write-Host "Terrform executable path is already set so check the Terraform version using 'Terraform --version' command." -ForegroundColor 'Yellow'
                Write-Host "Exiting the script." -ForegroundColor 'Yellow'
                Exit
            }
            Else {
                # TerraformFolderPath is not added to the path environment variable so adding it.
                Write-Host "Terraform executable path is not added to path environment variable so adding it." -ForegroundColor 'Yellow'
                
                # Add $TerrformFolderPath to $currentPath and saved as $newPath.
                $NewCurrentUserPath = $CurrentUserPath + ";$TerrformFolderPath"

                # Set PATH environment variable to $NewCurrentUserPath value.
                Try {
                    Set-ItemProperty -Path $CurrentUserReg -Name 'PATH' -Value $NewCurrentUserPath -Force -ErrorAction 'Stop'
                }
                Catch {
                    Write-Error -Exception $_.Exception.Message 
                }
            }
        }
        Else {
            # Terraform executable is not there so providing the link to download it.
            Write-Host "Please download the Terraform executable from https://developer.hashicorp.com/terraform/downloads link and place it at $($TerrformFolderPath) path." -ForegroundColor "Yellow"
        }
    }
}
Else {
    Write-Warning "Insufficient permissions to run this script. Open PowerShell console as an administrator and run this script again."
}
