$Base = 'https://api.kakiempat.com'
$f = Invoke-WebRequest -Uri "$Base/auth_v2.php?action=login" -Method POST `
  -Body '{"phone":"6281248826888","password":"123456"}' -ContentType 'application/json' -UseBasicParsing
$t = ($f.Content | ConvertFrom-Json).token
$url = "$Base/marketplace_v2.php?action=list_offers" + '&request_id=9'
$lo = Invoke-WebRequest -Uri $url -Headers @{ Authorization = "Bearer $t" } -UseBasicParsing
Write-Host "list_offers:" $lo.Content
$bad = Invoke-WebRequest -Uri "$Base/marketplace_v2.php?action=bad_action_test" -Headers @{ Authorization = "Bearer $t" } -UseBasicParsing
Write-Host "bad_action:" $bad.Content
