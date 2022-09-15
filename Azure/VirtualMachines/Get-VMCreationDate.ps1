
function Get-VMCreationDate {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        $Subscriptionid,
        [Parameter(Mandatory)]
        $ResourceGrouplocation
    )

    $token = Get-AzAccessToken

    $authHeader = @{
        'Content-Type'  = 'application/json'
        'Authorization' = 'Bearer ' + $token.Token
    }
    
    $resources = Invoke-RestMethod -Uri https://management.azure.com/subscriptions/$subid/providers/Microsoft.Compute/locations/$location/virtualMachines?api-version=2022-03-01 `
    -Method GET -Headers $authHeader

    $resources.value | ForEach-Object {
        [psobject]@{
            VMName = $_.name
            TimeCreated = $_.properties.timeCreated
        }
    } | Select-Object VMName, TimeCreated

}

