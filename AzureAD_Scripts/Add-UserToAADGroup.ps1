
<#
.SYNOPSIS
Function to add a user to an Azure AD group.
.DESCRIPTION
This function will add a user to an Azure AD group by providing the user's Samaccountname and AAD group name.

.EXAMPLE
PS C:\> Add-UserToAADGroup -Username "Mark.James" -GroupName "AAD-Testgroup"
Function will prompt you to provide username and the Azure AD group name and then will add the user to the group.

Author: Ashish Arya
Github: @ashisharya65
#>

function Add-UserToAADGroup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string] $Username,
        [Parameter(Mandatory)]
        [string] $GroupName
    )

    Begin {
        $GroupObjID = (Get-AzureADGroup -SearchString $GroupName).ObjectId
        $ObjectID = @()
 
    }

    Process {

        try {
            $UserObjectID = (Get-AzureADUser -SearchString $Username).ObjectId

            if ($null -ne $ObjectID) {
                write-host "`n Adding $($Username) to the $($GroupName) group.`n" -ForegroundColor Blue
                Add-AzureADGroupMember -ObjectID $GroupObjID -RefObjectId $UserObjectID -ErrorAction SilentlyContinue

            }
            else {
                
                write-host "$($Username) objectID is null.`n" -ForegroundColor Red
              
            }
        }
        catch {}

    }    
    End {
        write-host  "$($Username) was added to the $($GroupName) group.`n"  -ForegroundColor Green
    }

}

connect-AzureAD | out-null


