# Uji payment_v2.php — submit bukti (perlu token owner) & list pending (token admin).
param(
    [string]$ApiBase = "https://www.api.kakiempat.com",
    [string]$OwnerToken = "",
    [string]$AdminToken = "",
    [string]$BookingId = "1",
    [string]$ReferenceCode = "WISE-TEST-001"
)

$ErrorActionPreference = "Stop"

Write-Host "=== Uji payment_v2 ===" -ForegroundColor Cyan

$config = Invoke-RestMethod -Uri "$ApiBase/payment_v2.php?action=get_payment_config" -Method Get
Write-Host "Config:" ($config | ConvertTo-Json -Compress)

if ($OwnerToken) {
    $headers = @{
        "Authorization" = "Bearer $OwnerToken"
        "Content-Type"  = "application/json"
    }
    $body = @{
        booking_id     = $BookingId
        reference_code = $ReferenceCode
    } | ConvertTo-Json
    Write-Host "`nSubmit proof..."
    $submit = Invoke-RestMethod -Uri "$ApiBase/payment_v2.php?action=submit_payment_proof" -Method Post -Headers $headers -Body $body
    $submit | ConvertTo-Json | Write-Host
}

if ($AdminToken) {
    $headers = @{ "Authorization" = "Bearer $AdminToken" }
    Write-Host "`nList pending..."
    $list = Invoke-RestMethod -Uri "$ApiBase/payment_v2.php?action=list_pending_verification" -Method Get -Headers $headers
    $list | ConvertTo-Json -Depth 5 | Write-Host
}

if (-not $OwnerToken -and -not $AdminToken) {
    Write-Host "`nSet -OwnerToken / -AdminToken untuk uji lengkap (login via auth_v2.php)." -ForegroundColor Yellow
}
