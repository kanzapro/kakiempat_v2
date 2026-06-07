param(
    [string]$ApiBase = 'https://www.api.kakiempat.com',
    [string]$MasterPhone = '6281248826888',
    [string]$MasterPassword = '123456'
)
$ErrorActionPreference = 'Stop'
$auth = "$ApiBase/auth_v2.php"
function Post-Auth($action, $body) {
    $json = $body | ConvertTo-Json -Compress
    curl.exe -sS -X POST "$auth`?action=$action" -H "Content-Type: application/json" -d $json
}
Write-Host '=== Register owner ==='
$ownerPhone = '628' + (Get-Random -Maximum 9999999999).ToString('D10')
Post-Auth register @{ phone = $ownerPhone; password = 'test1234'; name = 'Owner Test'; role = 'owner' }
Write-Host '=== Register sitter ==='
$sitterPhone = '628' + (Get-Random -Maximum 9999999999).ToString('D10')
Post-Auth register @{ phone = $sitterPhone; password = 'test1234'; name = 'Sitter Test'; role = 'sitter' }
Write-Host '=== Login master ==='
$login = Post-Auth login @{ phone = $MasterPhone; password = $MasterPassword }
Write-Host $login
$obj = $login | ConvertFrom-Json
if (-not $obj.ok) { throw 'Master login failed' }
Write-Host '=== Validate token ==='
curl.exe -sS -H "Authorization: Bearer $($obj.token)" "$auth`?action=validate_token"
Write-Host "`n=== Logout (client) ==="
Write-Host 'OK'
