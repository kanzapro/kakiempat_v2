# Verifikasi endpoint API setelah deploy
$ErrorActionPreference = 'Stop'
$Base = 'https://api.kakiempat.com'
$AdminPhone = '6281248826888'
$AdminPass = '123456'

function Parse-Json($t) { try { $t | ConvertFrom-Json } catch { $null } }

Write-Host '=== Health ==='
$h = curl.exe -sS "$Base/health.php"
Write-Host $h

Write-Host '`n=== Admin login ==='
$loginBody = (@{ phone = $AdminPhone; password = $AdminPass } | ConvertTo-Json -Compress)
$login = curl.exe -sS -X POST "$Base/auth_v2.php?action=login" -H "Content-Type: application/json" -d $loginBody
$loginJ = Parse-Json $login
if (-not $loginJ.token) { throw "Login gagal: $login" }
$token = $loginJ.token
Write-Host "OK user id=$($loginJ.user.id) role=$($loginJ.user.role)"

Write-Host '`n=== list_my_requests (founder) ==='
$lr = curl.exe -sS "$Base/marketplace_v2.php?action=list_my_requests" -H "Authorization: Bearer $token"
Write-Host $lr.Substring(0, [Math]::Min(300, $lr.Length))

Write-Host '`n=== marketplace actions in PHP ==='
$bad = curl.exe -sS "$Base/marketplace_v2.php?action=invalid_test"
Write-Host $bad

if ($lr -notmatch 'list_my_requests|requests|action_required|forbidden') {
    if ($bad -match 'list_my_requests|list_offers') { Write-Host 'OK: new actions registered' }
    elseif ($lr -match '"ok":true') { Write-Host 'OK: list_my_requests responds' }
    else { Write-Host "WARN: $lr" }
}
