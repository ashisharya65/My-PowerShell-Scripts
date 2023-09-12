
param(
        [Parameter(Mandatory, HelpMessage = "Enter the Tenand Id.")] $TenantId,
        [Parameter(Mandatory, HelpMessage = "Enter the name of Azure subscription.")] $subscription,
        [Parameter(Mandatory, HelpMessage = "The Azure subscription id.")] $subscriptionId,
        [Parameter(Mandatory, HelpMessage = "Resource group name which contains the Azure VM.")] $resourceGroupName,
        [Parameter(Mandatory, HelpMessage = "Location of Azure VM.")] $location,
        [Parameter(Mandatory, HelpMessage = "Set the autoshutdown time in a similar way like this 2215 for 10:15 PM.")] $time,
        [Parameter(Mandatory, HelpMessage = "The concerned timezone which you need to set. For eg. India Standard Time.")] $timezone 
)

Function Disable-AzVMAutoShutdown {

    param(
        $Vmname
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
        "status" : "Disabled",
        "targetResourceId" : "/subscriptions/$($subscriptionId)/resourceGroups/$($resourceGroupName)/providers/Microsoft.Compute/virtualMachines/$($vmName)",
        "taskType" : "ComputeVmShutdownTask",
        "timeZoneId" : "$($timezone)"
    }
}
"@
    Try {
        Write-Host "Disabling the autoshutdown setting on $($vmName) VM" -ForegroundColor 'Yellow'        
        Invoke-RestMethod -Uri $uri -Method 'PUT' -Headers $authHeader -Body $requestbody -erroraction 'Stop' | Out-Null
        Write-Host "The autoshutdown setting has been successfully disabled on the $($vmName) VM." -ForegroundColor 'Green'
        Write-Host
    }
    Catch {
        $errormessage = $_.Exception.Message
        Write-Host "$($errormessage)" -ForegroundColor 'Red'
    }
}

Connect-AzAccount -Tenant $tenantId -Subscription $subscription  | Out-Null
$AllAVDs = Get-AzVm -ResourceGroupName $resourceGroupName 

Write-Host "Working on disabling the AutoShutdown setting " -ForegroundColor 'Yellow' -NoNewline
For ($i = 1; $i -le 4; $i++) {
    Start-sleep 1
    Write-Host "." -NoNewline -ForegroundColor 'Yellow'     
}

Foreach ($AVD in $AllAVDs) {
    Disable-AzVMAutoShutdown -Vmname $AVD.Name
}
