# Smoke test fondasi API v2: auth, owner, sitter, service, booking, admin.
param(
    [string]$ApiBase = 'https://www.api.kakiempat.com',
    [string]$OwnerPhone = '',
    [string]$OwnerPassword = '',
    [string]$SitterPhone = '',
    [string]$SitterPassword = '',
    [string]$AdminToken = ''
)

$ErrorActionPreference = 'Stop'

function Invoke-V2Get([string]$path, [hashtable]$Headers = @{}) {
    $args = @('-sS', '-A', 'KakiEmpatTest/1.0', '-H', 'Accept: application/json')
    foreach ($k in $Headers.Keys) { $args += @('-H', "$k`:$($Headers[$k])") }
    $args += "$ApiBase/$path"
    curl.exe @args
}

function Invoke-V2Post([string]$path, [string]$json, [hashtable]$Headers = @{}) {
    $args = @('-sS', '-A', 'KakiEmpatTest/1.0', '-H', 'Accept: application/json', '-H', 'Content-Type: application/json')
    foreach ($k in $Headers.Keys) { $args += @('-H', "$k`:$($Headers[$k])") }
    $args += @('-X', 'POST', '-d', $json, "$ApiBase/$path")
    curl.exe @args
}

Write-Host "=== Health ===" -ForegroundColor Cyan
Invoke-V2Get 'index.php' | Write-Host

if ($OwnerPhone -and $OwnerPassword) {
    Write-Host "`n=== Owner login ===" -ForegroundColor Cyan
    $loginBody = "{`"phone`":`"$OwnerPhone`",`"password`":`"$OwnerPassword`"}"
    $ownerAuth = Invoke-V2Post 'auth_v2.php?action=login' $loginBody | ConvertFrom-Json
    if (-not $ownerAuth.ok) { throw "Owner login gagal" }
    $ownerToken = $ownerAuth.token
    Write-Host "Owner OK: $($ownerAuth.user.name)"

    Write-Host "`n=== Service catalog (auth) ===" -ForegroundColor Cyan
    $cat = Invoke-V2Get 'service_v2.php?action=get_catalog' @{ Authorization = "Bearer $ownerToken" }
    Write-Host ($cat.Substring(0, [Math]::Min(200, $cat.Length))) '...'

    Write-Host "`n=== Owner profile ===" -ForegroundColor Cyan
    Invoke-V2Get 'owner_v2.php?action=get_profile' @{ Authorization = "Bearer $ownerToken" } | Write-Host

    Write-Host "`n=== Owner bookings ===" -ForegroundColor Cyan
    Invoke-V2Get 'booking_v2.php?action=list_my_bookings' @{ Authorization = "Bearer $ownerToken" } | Write-Host
}

if ($SitterPhone -and $SitterPassword) {
    Write-Host "`n=== Sitter login ===" -ForegroundColor Cyan
    $loginBody = "{`"phone`":`"$SitterPhone`",`"password`":`"$SitterPassword`"}"
    $sitterAuth = Invoke-V2Post 'auth_v2.php?action=login' $loginBody | ConvertFrom-Json
    if (-not $sitterAuth.ok) { throw "Sitter login gagal" }
    $sitterToken = $sitterAuth.token
    Write-Host "Sitter OK: $($sitterAuth.user.name)"

    Write-Host "`n=== Sitter profile ===" -ForegroundColor Cyan
    Invoke-V2Get 'sitter_v2.php?action=get_profile' @{ Authorization = "Bearer $sitterToken" } | Write-Host

    Write-Host "`n=== Marketplace list (open pool) ===" -ForegroundColor Cyan
    Invoke-V2Get 'marketplace_v2.php?action=list_requests&pool=open' @{ Authorization = "Bearer $sitterToken" } | Write-Host

    Write-Host "`n=== Incoming requests (legacy) ===" -ForegroundColor Cyan
    Invoke-V2Get 'booking_v2.php?action=list_incoming_requests' @{ Authorization = "Bearer $sitterToken" } | Write-Host
}

if ($AdminToken) {
    Write-Host "`n=== Admin pending sitters ===" -ForegroundColor Cyan
    Invoke-V2Get 'admin_v2.php?action=list_pending_sitters' @{ Authorization = "Bearer $AdminToken" } | Write-Host
}

Write-Host "`nSelesai." -ForegroundColor Green
