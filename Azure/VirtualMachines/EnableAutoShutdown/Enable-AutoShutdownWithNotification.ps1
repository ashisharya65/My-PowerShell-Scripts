Connect-AzAccount

Function Enable-AzVMAutoShutdownWithNotification {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory,
            HelpMessage = "The Azure subscription id.")] 
        $subscriptionId,
        [Parameter(Mandatory,
            HelpMessage = "Resource group name which contains the Azure VM.")]
        $resourceGroupName,
        [Parameter(Mandatory,
            HelpMessage = "Name of the Azure VM.")] 
        $vmName,
        [Parameter(Mandatory,
            HelpMessage = "Location of Azure VM.")] 
        $location,
        [Parameter(Mandatory,
            HelpMessage = "Set the autoshutdown time in a similar way like this 2215 for 10:15 PM.")] 
        $time,
        [Parameter(Mandatory,
            HelpMessage = "The concerned timezone which you need to set. For eg. Indian Standard Time.")] 
        $timezone,
        [Parameter(Mandatory,
            HelpMessage = "Email address of receipient of Email notification.")]
        $emailrecipient
    )

    $token = Get-AzAccessToken

    $authHeader = @{
        'Content-Type'  = 'application/json'
        'Authorization' = 'Bearer ' + $token.Token
    }
    
    $resource = "$($subscriptionId)/resourceGroups/$($resourceGroupName)/providers/Microsoft.DevTestLab/schedules/shutdown-computevm-$($vmName)?api-version=2018-10-15-preview"
    $uri = "https://management.azure.com/subscriptions/$($resource)"

    $requestbody = @"
{
    "location" : "$($location)",
    properties : {
        "dailyRecurrence" : {
            "time" : "$($time)"
        },
        "notificationSettings" : {
           "emailRecipient" : "$($emailrecipient)",
           "notificationLocale" : "en",
            "status" : "Enabled",
            "timeInMinutes" : "30",
        },
        "status" : "Enabled",
        "targetResourceId" : "/subscriptions/$($subscriptionId)/resourceGroups/$($resourceGroupName)/providers/Microsoft.Compute/virtualMachines/$($vmName)",
        "taskType" : "ComputeVmShutdownTask",
        "timeZoneId" : "$($timezone)"
    }
}
"@
    Try {
        Write-Host "Enabling the autoshutdown on $($vmName) VM with email notification.." -ForegroundColor 'Yellow' -NoNewline
        For ($i = 0; $i -le 4; $i++) {
            Start-sleep 1
            Write-Host "." -NoNewline -ForegroundColor 'Yellow'     
        }
        Invoke-RestMethod -Uri $uri -Method 'PUT' -Headers $authHeader -Body $requestbody -erroraction 'Stop' | Out-Null
        Write-Host "`nThe autoshutdown setting has been successfully enabled on the $($vmName) VM with email notification to $($emailrecipient) email address." -ForegroundColor 'Green'

    }
    Catch {
        $errormessage = $_.Exception.Message
        Write-Error $errormessage
    } 
}
