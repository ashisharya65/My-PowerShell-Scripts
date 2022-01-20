<#
    .SYNOPSIS
    Get all logged in users from the remote computers.
    
    .DESCRIPTION
    Getting all the users which are logged in to the remote computers stored in a file (csv or txt).
    
    .PARAMETER ComputerName
    Specifies the computer name.
    
    .EXAMPLE
    $Servers = get-content "Enter the Full path of the text file."
    $Servers | Get-LoggedOnUser
    
    Author : Ashish Arya
    
#>

function Get-LoggedOnUsers {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)]
        [string[]]$ComputerName   
          )
    
    Begin{}
    
    process{

                foreach ($comp in $ComputerName)
                {
                    $processinfo = Get-WmiObject -Query "select * from win32_process where name='explorer.exe'" -ComputerName $comp
                    $Username = $processinfo | ForEach-Object { $_.GetOwner().User } | Sort-Object -Unique
                        
                        if($null -ne $Username){
                            
                            $myobject = [PSCustomObject]@{
                            ComputerName = $comp 
                            UserName = $Username 
                            }
                        }
                        else{

                            $myObject.UserName = 'No Users are logged in'
                        }                  
                      
                 
                    write-host "===================================================================" -ForegroundColor 'Green'
                    write-host "Number of Users logged into $($myobject.ComputerName) computer are:" -ForegroundColor 'Green'
                    write-host "===================================================================" -ForegroundColor 'Green'
                    $AllUsernames = $($myobject.Username) -join "`n"
                    write-host "$($AllUsernames)`n" -ForegroundColor 'Blue'
                
                    
 
               }
            }
    End{}

}
write-host

# You just need to change enter the path of text file having server names
$Servers = get-content -path "Full path of the file which stores the server names."

$Servers | Get-LoggedOnUsers