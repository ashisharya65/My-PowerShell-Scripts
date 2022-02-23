
<#
    This script can be used to send password expiry email notifications to the active users whose Active Directory account passwords are going to expire in the
    next seven days.
    
    Author: Ashish Arya
    Github: AshishArya_In
#>

#Import AD
Import-Module ActiveDirectory

#Email Variables
$MailSender = ""
$Subject    = 'Your account password will expire soon!!!'
$EmailStub1 = @"

Hi, 

This is to inform you that your password
"@

$EmailStub2 = 'is going to expire in'
$EmailStub3 = 'days i.e.. on'
$EmailStub4 = @"

Please find the attached document which you may use to change your password on your company provided laptop.
                      
Please try to change your password before it gets expired.

In case you face any issue, feel free to contact our IT Helpdesk team. 

Regards,
IT Operations

"@ 

#region SMTP Server's Fully qualified domain
$SMTPServer = ''

#region finding accounts that are Active, their passwords is going to expire in next 7 days, those accounts should be having an email address.
$users = Get-ADUser -filter {Enabled -eq $True -and PasswordNeverExpires -eq $False -and PasswordLastSet -gt 0} `
        -Properties "Name","EmployeeID", "EmailAddress", "msDS-UserPasswordExpiryTimeComputed" | Select-Object -Property "Name", `
       "EmailAddress", @{Name = "PasswordExpiry"; Expression = {[datetime]::FromFileTime($_."msDS-UserPasswordExpiryTimeComputed") }}|`
        where {($_.EmailAddress -ne $null) -and (($_.PasswordExpiry -gt (get-date)) -and ($_.PasswordExpiry -le (get-date).AddDays(7)))} 


#region sending emails with PDF attachment to All the concerned users mentioning the date of their Account password expiration.
foreach ($user in $users) {
       $days      = $user.PasswordExpiry - (get-date)
       $WarnDate  = $user.PasswordExpiry.ToLongDateString() + "."	 
       $EmailBody = $EmailStub1,$EmailStub2,$days.Days,$EmailStub3,$WarnDate,$EmailStub4 -join ' '
		   Send-MailMessage -To $user.EmailAddress -From $MailSender -SmtpServer $SMTPServer -Subject $Subject -Body $EmailBody -Attachments "C:\Change_Your_Password.pdf"
 }
