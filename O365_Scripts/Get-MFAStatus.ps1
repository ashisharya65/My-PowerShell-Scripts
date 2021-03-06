<#
    Script to get MFA status for all users in your office365 tenant.
    Author : Ashish Arya
    Github : @ashisharya65
#>

connect-msolservice

Get-MsolUser -All | Select-Object DisplayName, BlockCredential, UserPrincipalName, @{N = "MFA Status"; E = { 
        if ( $_.StrongAuthenticationRequirements.State -ne $null) { 
            $_.StrongAuthenticationRequirements.State 
        } 
        else { 
            "Disabled" 
        } 
    }
} 
