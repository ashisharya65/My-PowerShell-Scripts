<#
    DESCRIPTION:    This script will create a Scheduled Task (which runs at User Login) that executes
                    a powershell script stored in an Azure blob storage account to import the Custom Word Template file
                    for changing the font to Arial 11. 
    AUTHOR:         Ashish Arya (ashisharya65@outlook.com)
    DATE:           20 December 2021
#>

#Script Name and TaskName for your scheduled task

$scriptName = ([System.IO.Path]::GetFileNameWithoutExtension($(Split-Path $script:MyInvocation.MyCommand.Path -Leaf)))
$logFile = $($env:ProgramData) + "\Intune-PowerShell-Logs\$scriptName-" + $(get-date -format "dd_MM_yyyy") + ".log" 
Start-Transcript -Path $logFile -Append

#enter the path to your script StorageAccounts->"account"->Blobs->"container"->"script"->URL
$scriptLocation = "<Location of Azure blob where your FontChange script is placed.>" 


#########################################################################################################################
                                              # Setup the Scheduled Task #
#########################################################################################################################

$taskName = "LogonScriptSchdtask"
$schedTaskCommand = "Invoke-Expression ((New-Object Net.WebClient).DownloadString($([char]39)$($scriptLocation)$([char]39)))"
$schedTaskArgs= "-ExecutionPolicy Bypass -windowstyle hidden -command $($schedTaskCommand)"
$schedTaskExists = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
$taskdescription = "Schedule task for running the LogonScript"

function Update-SchedTask{
    Write-Output "Creating Schdeuled Task.."
    $schedTaskAction = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument $schedTaskArgs
    $schedTaskTrigger = New-ScheduledTaskTrigger -AtLogon 
    $schedTaskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -Compatibility Win8
    $schedTaskPrincipal = New-ScheduledTaskPrincipal -GroupId "S-1-5-32-545" -RunLevel Highest
    $schedTask = New-ScheduledTask -Description $taskdescription -Action $schedTaskAction -Settings $schedTaskSettings -Trigger $schedTaskTrigger -Principal $schedTaskPrincipal -ErrorVariable $NewSchedTaskError
    Register-ScheduledTask -InputObject $schedTask -TaskName $taskName -ErrorVariable $RegSchedTaskError
}

if($schedTaskExists){
    Write-Output "Task Exists.."

    #Deleting the existing scheduled task
    Write-Output "OldTask: $((Get-ScheduledTask -TaskName $taskName).Actions.arguments)"
    Write-Output "NewTask: $($schedTaskCommand)"
    Write-Output "Deleting Scheduled Task.."
    Unregister-ScheduledTask -TaskName $taskName -Confirm:$false -ErrorAction SilentlyContinue

    #Function call to create a new scheduled task
    Update-SchedTask
}
else{
       
    Write-Output "Task doesnot exists.."
    
    #Function call to create a new scheduled task
    Update-SchedTask
}

Stop-Transcript
