
# Check if the registry key exists and its value
$KeyPath = "HKCU:\Software\RemediationScripts\FillSurvey"
$KeyName = "IsSurveyFilled"
$RegKeyValue = Get-ItemProperty -Path $KeyPath -Name $KeyName -ErrorAction SilentlyContinue

if ($null -eq $RegKeyValue -or $RegKeyValue.$KeyName -ne $true) {
    Write-Output "Survey not filled"
    exit 1
} else {
    Write-Output "Survey filled"
    exit 0
}
