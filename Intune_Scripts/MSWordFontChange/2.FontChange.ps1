<#
    DESCRIPTION:    Script is running on User Login. 
                    Change the MS Word Font to Arial,11.

    AUTHOR:         Ashish Arya (ashisharya65@outlook.com)
    DATE:           20 December 2021
#>

#Script Logging
$scriptName = "LogonScript"
$logFile = $($env:ProgramData) + "\Intune-PowerShell-Logs\$scriptName-" + $(get-date -format "dd_MM_yyyy") + ".log"
Start-Transcript -Path $LogFile -Append

#########################################################################################################################
                                             # Changing MS Word Font to Arial 11 #
#########################################################################################################################

# Path for Templates folder and Custom Word Template file.
$TemplatesFolder = "$env:Appdata\Microsoft\Templates"
$NormalDotmFile = "$env:Appdata\Microsoft\Templates\Normal.dotm"

#Function for adding our Custom Template file.
function Add-Templatefile{
    #Downloading our Normal.dotm file (which has Arial,11 font) from Azure blob and placing it on the Templates foler
    write-output "Adding our Custom Word Template File.."
    write-host
    Start-BitsTransfer -source "<location of the Normal.dotm file placed on Azure Blob>" -Destination "$env:Appdata\Microsoft\Templates"
}

#Checking the Templates Folder is there or not. If not then will be creating it.

if((Get-Item $env:Appdata\Microsoft\Templates) -isnot [System.IO.DirectoryInfo]){
    write-output "Templates is not a folder but a file so we have to remove it. Hence removing..."
    Remove-Item -Path $TemplatesFolder -Force -Recurse
    write-output "Now creating the Templates folder.."
    New-Item -Path $TemplatesFolder -ItemType "Directory"
    write-host
    
    #function call
    Add-Templatefile

}else{
        write-output "Template is a folder so check and delete the existing Word template file."
        write-host
    
    if((test-path $NormalDotmFile)-and((Get-Item $NormalDotmFile) -is [system.io.fileinfo])){   
    
        write-output "Removing the existing Word template file.."
        Remove-item $NormalDotmFile -Force
        
        #function call
        Add-Templatefile

    }else{
        
        #function call
        Add-Templatefile
    
    }
}
