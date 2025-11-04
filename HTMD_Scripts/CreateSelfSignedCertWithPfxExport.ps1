<#
.SYNOPSIS
    Creates a self-signed certificate and exports it to both .cer and .pfx files, encoding the password in Base64.

.DESCRIPTION
    This function generates a self-signed RSA certificate in the user certificate store, exports the public key to a .cer file, exports the private key to a password-protected .pfx file, encodes the password in Base64, and then removes the certificate from the certificate store. Useful for development and automation scenarios requiring certificates for authentication.

.PARAMETER CertName
    The subject name for the self-signed certificate.
    Default: "CN=PwshGraphApp"

.PARAMETER CertStoreLocation
    The certificate store path where the certificate will be created.
    Default: "cert:\CurrentUser\My"

.PARAMETER CerExportPath
    The file path to export the public key certificate (.cer).
    Default: "$env:SystemDrive\SelfSignedCerts\PwshGraphApp.cer"

.PARAMETER PfxExportPath
    The file path to export the private key certificate (.pfx).
    Default: "$env:SystemDrive\SelfSignedCerts\PwshGraphApp.pfx"

.PARAMETER PfxPassword
    The password (as a SecureString) to protect the exported .pfx file.

.EXAMPLE
    # Run script to create a self-signed certificate with a prompt for the PFX password.
    .\CreateSelfSignedCertWithPfxExport.ps1

.EXAMPLE
    # Call the function directly with custom parameters.
    New-SelfSignedCertWithPfxExport -CertName "CN=DemoApp" -CerExportPath "C:\Certs\DemoApp.cer" -PfxExportPath "C:\Certs\DemoApp.pfx" -PfxPassword (Read-Host -AsSecureString)

.NOTES
    Author: Ashish Arya
    Created: 24-October-2025
    This script is intended for development purposes and should not be used for production certificate provisioning.
#>

#region Self Signed cert function
function New-SelfSignedCertWithPfxExport {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false)][string]$CertName = "CN=PwshGraphApp",

        [Parameter(Mandatory = $false)][string]$CertStoreLocation = "cert:\CurrentUser\My",

        [Parameter(Mandatory = $false)][string]$CerExportPath = "$env:SystemDrive\SelfSignedCerts\PwshGraphApp.cer",

        [Parameter(Mandatory = $false)][string]$PfxExportPath = "$env:SystemDrive\SelfSignedCerts\PwshGraphApp.pfx",

        [Parameter(Mandatory = $true)][SecureString]$PfxPassword
    )

    try {
        # Ensure export directory exists
        $exportDir = Split-Path $CerExportPath
        if (!(Test-Path $exportDir)) {
            New-Item -Path $exportDir -ItemType Directory -Force | Out-Null
        }

        # Certificate parameters
        $certParams = @{
            Subject           = $CertName
            CertStoreLocation = $CertStoreLocation
            KeyExportPolicy   = "Exportable"
            KeyLength         = "2048"
            KeyAlgorithm      = "RSA"
            NotAfter          = (Get-Date).AddYears(2)
        }
 
        # Create certificate
        $cert = New-SelfSignedCertificate @certParams
        Write-Host " - Self-Signed Certificate created successfully." -Foregroundcolor "Green"
        Write-Host " - Thumbprint: $($cert.Thumbprint)" -Foregroundcolor "Green"

        # Export public key (.cer)
        Export-Certificate -Cert $cert -FilePath $CerExportPath | Out-Null
        Write-Host " - Exported .cer to path: $CerExportPath" -Foregroundcolor "Green"

        # Export private key (.pfx) with password
        Export-PfxCertificate -Cert $cert -FilePath $PfxExportPath -Password $PfxPassword | Out-Null
        Write-Host " - Exported .pfx to path: $PfxExportPath" -Foregroundcolor "Green"

        # Removing the certificate from user certificate store
        Get-ChildItem -Path $CertStoreLocation | Where-Object { $_.Thumbprint -eq $cert.Thumbprint } | Remove-Item

        # Convert password to Base64
        $base64Password = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto(
            [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($PfxPassword)
        )
        $base64Password = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($base64Password))
        Write-Host " - Encoded password: $base64Password`n" -Foregroundcolor "Green"

    }
    catch {
        $errMsg = $_.Exception.Message
        Write-Host " - Failed to create or export certificate: $errMsg`n" -Foregroundcolor "Red"
    }
}
#endregion 

#region Main Execution
Write-Host
Write-Host "#############################################################################################################################################################################" -Foregroundcolor "Cyan"
Write-Host "#                                                                 SELF SIGNED CERTIFICATE CREATION - START                                                                  #" -Foregroundcolor "Cyan"
Write-Host "#############################################################################################################################################################################" -Foregroundcolor "Cyan"

# Prompt for Pfx certificate password
Write-Host "`nEnter the Pfx certificate password: " -Foregroundcolor "Yellow" -NoNewLine
[SecureString]$PfxPwd = Read-Host -AsSecureString
Write-Host

New-SelfSignedCertWithPfxExport -PfxPassword $PfxPwd

Write-Host "#############################################################################################################################################################################" -Foregroundcolor "Cyan"
Write-Host "#                                                                 SELF SIGNED CERTIFICATE CREATION - END                                                                    #" -Foregroundcolor "Cyan"
Write-Host "#############################################################################################################################################################################`n`n" -Foregroundcolor "Cyan"

#endregion
