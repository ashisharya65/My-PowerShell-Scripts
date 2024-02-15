<#

    .SYNOPSIS
    Azure function app script to shut down the Azure Virtual Desktop machines that do not have an active user session.

    .DESCRIPTION
    You can use that script in your PowerShell Azure function app to shut down the AVDs which are having no active user session.

    .NOTES
    AUTHOR : Ashish Arya
    Date   : 18-Jan-2024

#>

# For the Function App
param($Timer)

# Recording the starting time for the script execution
$ScriptStartTime = Get-Date -Format "dd-MM-yyyy hh:mm:ss"
Write-Output "`n##########################################"
Write-Output "Script start time: $ScriptStartTime"
Write-Output "##########################################`n"

###########Variables ############
$AVDRG = "AVDs resource group name"
$RegExPattern = "Regular expression pattern for fetching the running AVDs from the above mentioned resource group"

# Declaring the concerned host pools
$allHostPools = @(
    [pscustomobject]@{
        HostPool   = "HostPool Name"
        HostPoolRG = "HostPool ResourceGroup"
    },
    [PSCustomObject]@{
        HostPool   = "HostPool Name"
        HostPoolRG = "HostPool ResourceGroup"
    }
)

# Looping through the host pools
For ($i = 0; $i -lt $allHostPools.Length; $i++) {

    $pool = $allHostPools[$i].HostPool
    $poolrg = $allHostPools[$i].HostPoolRG

    Write-Output "########################################################"
    Write-Output "HostPool Name           : $pool"
    Write-output "HostPool Resource group : $poolRg"
    Write-Output "########################################################`n"

    # Getting all the running AVDs which are having the names matching with the RegExPattern
    $VMs = Get-AzVM -ResourceGroupName $AVDRG -Status | Where-Object { ($_.Name -match "$RegExPattern") -and ($_.PowerState -ne "VM deallocated") } |`
        Sort-Object { [int]($_.Name -replace '.*-(\d+)', '$1') }

    $Count = 0
    $DeallocatedVMsCount = 0    
    # Looping through all the running AVDs
    Foreach ($VM in $VMs) {
        $AVDName = $VM.Name          
        # Getting the AVD details
        $AVD = Get-AzWvdSessionHost -HostPoolName $Pool -ResourceGroupName $PoolRg -Name "$($AVDName)" -ErrorAction 'Silentlycontinue'        
        # Selecting those active Win11 AVDs which are there at the AVD portal
        If(-not(([string]::IsNullOrWhiteSpace($AVD))-or([string]::IsNullOrEmpty($AVD)))){
            $Count += 1
            # Stopping those AVDs which are in Drain mode off state and does not have any active session
            If (($AVD.AllowNewSession -eq $true) -and ($AVD.Session -eq 0)) {
                Try {
                    Stop-AzVM -Name $AVDName -ResourceGroupName $VMRG -Force -NoWait -ErrorAction 'Stop' | Out-Null
                    Write-Output "$count. The $AVDName AVD does not have any active user session. Hence, shutting it down."
                    $DeallocatedVMsCount += 1
                }
                Catch {
                    $ErrorMessage = $_.Exception.Message
                    Write-Error ("Error Message: " + $ErrorMessage)
                }
            }
            Else {
                Write-Output "$Count. The $AVDName AVD already has an active user session."
            }
        }
    }      
    Write-Output "`n##############################################################################################"               
    Write-Output "The number of AVDs which got deallocated from the $pool hostpool : $DeallocatedVMsCount"
    Write-Output "##############################################################################################`n"               
}

# Recording the end time of script execution
$ScriptEndTime = Get-Date -Format "dd-MM-yyyy hh:mm:ss"
Write-Output "`n= = = = = = = = = = = = = = = = = = = = ="
Write-Output "Script end time : $ScriptEndTime"
Write-Output "= = = = = = = = = = = = = = = = = = = = =`n"

