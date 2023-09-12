
param(
        [Parameter(Mandatory,HelpMessage = "Enter the Tenand Id.")] $TenantId,
        [Parameter(Mandatory, HelpMessage = "Enter the name of Azure subscription.")] $subscription,
        [Parameter(Mandatory, HelpMessage = "Enter the Azure subscription id.")] $subscriptionId,
        [Parameter(Mandatory, HelpMessage = "Enter the Resource group name which contains Azure VM.")] $resourceGroupName,
        [Parameter(Mandatory, HelpMessage = "Enter the Azure VM Name.")] $vmName,
        [Parameter(Mandatory, HelpMessage = "Enter the Location of Azure VM.")] $location,
        [Parameter(Mandatory, HelpMessage = "Enter the time for auto-shutdown time. For eg. 2215 for 10:15 PM.")] $time,
        [Parameter(Mandatory, HelpMessage = "Enter the timezone which you need to set. For eg. India Standard Time.")] $timezone,
        [Parameter(Mandatory, HelpMessage = "Enter the Receipient's Email address for receipving Email notification of autoshutdown.")] $emailrecipient
)

Function Enable-AzVMAutoShutdownWithNotification {
    param(
        $VMName
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
    "properties" : {
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
        Write-Host "$($errormessage)" -ForegroundColor 'Red'
    } 
}

Connect-AzAccount -Tenant $TenantId -Subscription $Subscription  | Out-Null
Enable-AzVMAutoShutdownWithNotification -VMName $vmName
