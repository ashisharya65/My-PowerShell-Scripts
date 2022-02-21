
function Get-ISPDetails{

[CmdletBinding()]
Param(
    [Parameter()]
    [string[]]$PublicIPs,
    [switch]$ISPOnly
)

if(-not($PublicIPs))
{
    $PublicIPs = (Invoke-WebRequest -Uri http://ifconfig.me/ip -TimeoutSec 60 -UseBasicParsing).Content.Trim()
}
foreach($PublicIP in $PublicIPs)
{
    $SearchURL = "https://api.iplocation.net/?ip=$PublicIPs"
    $ISP = ((Invoke-WebRequest -Uri $SearchURL -UseBasicParsing).content -replace '{', '' -replace '}', '' -replace '"', '' -split ',' | Where-Object {
            $_ -match 'isp:'
        }).replace('isp:', '')

    if($ISP -match 'Private IP Address LAN')
    {
        $ISP = '* IP is not a Public IP *'
    }

    if($IspOnly)
    {
        $ISP
    }
    Else
    {
        Write-Host $('IP: {0,-17} ISP: {1}' -f $PublicIP, $ISP)
    }
}
}