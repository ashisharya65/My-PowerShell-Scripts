
param (
    [Parameter(Mandatory)] $UserUPN,
    [Parameter(Mandatory)] $VMName,
    [Parameter(Mandatory)] $SubscriptionID,
    [Parameter(Mandatory)] $ResourceGroupName,
    [Parameter(Mandatory)] $Role,
    $erroractionpreference = "Stop"
)

Connect-AzAccount | Out-Null

Try { 
    Set-AzContext -Subscription $SubscriptionID | Out-Null
}
Catch {
    Write-Error $_.Exception.Message
    Break;
}

$RemoveAzRoleAssigment = @{
    "SignInName"         = $UserUPN
    "RoleDefinitionName" = $Role
    "Scope"              = "/subscriptions/$($SubscriptionID)/resourceGroups/$($ResourceGroupName)/providers/Microsoft.Compute/virtualMachines/$($VMName)"
}

Write-Host "`nRemoving the role assignment.." -ForegroundColor 'DarkCyan'
Try {
    Remove-AzRoleAssignment @RemoveAzRoleAssigment | Out-Null
    Write-Host "$($Role) Azure role assignment was removed on $($VMName) VM for $($UserUPN.Split("@")[0]) user.`n" -ForegroundColor 'Green'
}
Catch {
    Write-Error $_.Exception.Message
    Break;
}
