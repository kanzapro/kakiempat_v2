$Base = 'https://api.kakiempat.com'
$login = Invoke-WebRequest -Uri "$Base/auth_v2.php?action=login" -Method POST `
  -Body '{"phone":"6289072643127","password":"TestV2!234"}' -ContentType 'application/json' -UseBasicParsing
$t = ($login.Content | ConvertFrom-Json).token
Write-Host 'login:' $login.Content
$url = "$Base/marketplace_v2.php?action=list_offers" + '&request_id=9'
try {
  $lo = Invoke-WebRequest -Uri $url -Headers @{ Authorization = "Bearer $t" } -UseBasicParsing
  Write-Host 'list_offers:' $lo.Content
} catch {
  $sr = New-Object IO.StreamReader($_.Exception.Response.GetResponseStream())
  Write-Host 'list_offers ERR:' $sr.ReadToEnd()
}
