
[cmdletbinding()]

param(
    [string] $LogFolderPath = "C:\Temp\Post-ESPReboot",
    [string] $LogFilePath = $LogFolderPath + "\Logs\Post-ESPReboot-NotificationScriptLog.log"
)

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

Write-Log -Level 'Info' -Message "Script execution started."
$wshell = New-Object -ComObject wscript.shell
$wshell.Popup("The computer will restart in 10 mins to finish configuration. Please save your work.")

Write-Log -Level 'Info' -Message "Script execution ended."