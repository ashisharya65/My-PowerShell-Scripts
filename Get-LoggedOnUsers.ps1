
<#
    Script to get logged in Users on Servers store in a text file.
#>


function Get-LoggedOnUser {
    [CmdletBinding()]
    param (
        [parameter(ValueFromPipeline)]
        [string[]]$Computername
        
    )
    process{

                foreach ($comp in $ComputerName)
                {
                    $processinfo = Get-WmiObject -Query "select * from win32_process where name='explorer.exe'" -ComputerName $comp
                    $Username = $processinfo | ForEach-Object { $_.GetOwner().User } | Sort-Object -Unique
    
                        $myobject = [PSCustomObject]@{
                        ComputerName = $comp 
                        UserName = $Username
                        }                  
                }        
                 
                write-host "===================================================================" -ForegroundColor 'Green'
                write-host "Number of Users logged into $($myobject.ComputerName) computer are:" -ForegroundColor 'Green'
                write-host "===================================================================" -ForegroundColor 'Green'
                $AllUsernames = $($myobject.Username) -join "`n" 
                write-host "$($AllUsernames)`n" -ForegroundColor 'Blue'

           }
}
write-host

# You just need to change enter the path of text file having server names
$Servers = get-content -path "Path of the text file which stores server names."

$Servers | Get-LoggedOnUser 



