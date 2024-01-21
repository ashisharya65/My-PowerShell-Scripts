
<#
    *
    **
    ***
    ****
    *****
#>
Write-Host "`nRight-Angled Triangle:"
for ($i = 1; $i -le 5; $i++) {
    Write-Host ('*' * $i)
}

<#
    *****
    ****
    ***
    **
    *
#>
Write-Host "`nInverted Right-angled Triangle:"
for ($j = 5; $j -ge 1; $j--) {
    Write-Host ('*' * $j)
}

<#
    *
   ***
  *****
 *******
*********
#>
Write-Host "`n Pyramid:"
for ($i = 1; $i -le 5; $i++) {
    Write-Host (' ' * (5 - $i) + '*' * ((2 * $i) - 1))
}

<#
*********
 *******
  *****
   ***
    *
#>
Write-Host "`nInverted Pyramid:"
for ($i = 5; $i -ge 1; $i--) {
    Write-Host (' ' * (5 - $i) + '*' * ((2 * $i) - 1))
}

<#
    *
   ***
  *****
 *******
*********
 *******
  *****
   ***
    *
#>
Write-Host "`n Diamond:"
for ($i = 1; $i -le 5; $i++) {
    Write-Host (' ' * (5 - $i) + '*' * (2 * $i - 1))
}
for ($i = 4; $i -ge 1; $i--) {
    Write-Host (' ' * (5 - $i) + '*' * ((2 * $i) - 1))
}

