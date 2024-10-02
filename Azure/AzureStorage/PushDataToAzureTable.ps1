
# Variable declaration
$rgname = "MyRg"
$location = "eastus"
$storageaccountname = "mystorageaccount1810202"
$tablename = "MyData"

#region Azure Authentication
Try {
    Write-Host "Connecting to Azure..." -foregroundcolor "Yellow"
    Connect-AzAccount -erroraction "Stop" | Out-Null
    Write-Host "Connected to Azure." -foregroundcolor "Green"
}
Catch {
    $err = $_.Exception.Message
    Write-Host "ERROR: Unable to connect to Azure. $err." -foregroundcolor 'Red'
}
#regionend

#region Resource group creation
$resourcegroup = Get-AzResourceGroup -Name $rgname -location $location -erroraction "silentlycontinue"
if ($null -eq $resourcegroup){
    Try {
        New-AzResourcegroup -ResourceGroupName $rgname -location $location -erroraction "Stop" | Out-Null
        Write-Host "The resource group was created successfully." -foregroundcolor "Green"
    }
    Catch {
        $err = $_.Exception.Message
        Write-Host "ERROR: Unable to create the resource group. $err." -foregroundcolor 'Red'
    }
}
else {
    Write-Host "$($rgname) resource group is already created." -foregroundcolor "Yellow"
}
#regionend

#region Storage account creation
$params = @{
    ResourceGroupName = $rgname
    Name = $storageaccountname
    Location = $location
    SkuName = 'Standard_LRS'
    Kind = 'Storage'
    ErrorAction = 'Stop'
}

$storageaccount = Get-AzStorageAccount -Name $storageaccountname -ResourceGroupName $rgname -erroraction "silentlycontinue"
if($null -eq $storageaccount){
    Try {
        Write-Host "Creating the Azure storage account." -foregroundcolor "Yellow"
        $storageacctinfo = New-AzStorageAccount @params
        $ctx = $storageacctinfo.Context
        Write-Host "The $($storageaccountname) storage account was created succesfully." -foregroundcolor "Green"
    }   
    Catch {
        $err = $_.Exception.Message
        Write-Host "ERROR: Unable to create the Azure storage account. $err." -foregroundcolor 'Red'
    }

}
else {
    $ctx = $storageaccount.Context
    Write-Host "The $($storageaccountname) storage account is already created." -foregroundcolor "Yellow"
}
#regionend

#region Azure Table creation
$storageTable = (Get-AzStorageTable -Table $tablename -Context $ctx -erroraction "Silentlycontinue")
if ($null -eq $Table){
    Try {
        Write-Host "Creating the Azure table." -foregroundcolor "Yellow"
        New-AzStorageTable -Name $tablename -Context $ctx -erroraction 'Stop'
    }
    Catch {
        $err = $_.Exception.Message
        Write-Host "ERROR: Unable to create the Azure table. $err." -foregroundcolor 'Red'
    }
}
else {
    Write-Host "$($tablename) Azure table is already created." -foregroundcolor "Yellow"
}
#regionend

#region defining the sample data 
$cloudTable = $storageTable.CloudTable
$properties = @(
    @{
        devicename = "ABC-789"
        partitionkey = "KB5043050"
        UpdateStatus  = "Installed"
        UpdateCategory = "Security Update"
        InstalledDate = (Get-Date).toString("dd-MM-yyyy_hh:mm:ss")
    },
    @{
        devicename = "ABC-550"
        partitionkey = "KB5043050"
        UpdateStatus = "Failed"
        UpdateCategory = "Security Update"
        InstalledDate = (Get-Date).toString("dd-MM-yyyy_hh:mm:ss")
    },
    @{
        devicename = "ABC-1000"
        partitionkey = "KB5043095"
        UpdateStatus = "Failed"
        UpdateCategory = "Security Update"
        InstalledDate = (Get-Date).toString("dd-MM-yyyy_hh:mm:ss")
    },
    @{
        devicename = "ABC-220"
        partitionkey = "KB5043055"
        UpdateStatus = "Failed"
        UpdateCategory = "Security Update"
        InstalledDate = (Get-Date).toString("dd-MM-yyyy_hh:mm:ss")
    }
)
#regionend

#region adding table rows
Foreach($item in $properties){
    Try {
        Add-AzTableRow -table $cloudTable -partitionKey $partitionkey -rowkey "$([Guid]::newGuid().toString())" -property $item | Out-Null
        Write-Host "Entity with device name $($item.devicename) was added to the azure table."
    }
    Catch {
        $err = $_.Exception.Message
        Write-Host "ERROR: Unable to create add the entity to the table. $err." -foregroundcolor 'Red'
    } 
}
#regionend

#fetching the data from the azure table
Get-AzTableRow -table $cloudTable | Format-Table

# deleting all the entities from the table
Get-AzTableRow -table $cloudTable | Remove-AzTableRow -table $cloudTable 

#region removing azure resource group
Try {
    Remove-AzResourceGroup -Name $rgname -force | Out-Null
}
Catch {
    $err = $_.Exception.Message
    Write-Host "ERROR: Unable to remove the resource group. $err." -foregroundcolor 'Red'
}
#regionend
