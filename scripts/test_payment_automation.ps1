# Simulasi webhook SeaBank → cek status pembayaran (lokal atau produksi).
param(
    [string]$ApiBase = "https://www.api.kakiempat.com",
    [int]$Nominal = 250000,
    [string]$BookingId = "1",
    [Parameter(Mandatory = $true)]
    [string]$WebhookSecret
)

$ErrorActionPreference = "Stop"

Write-Host "=== Uji otomatisasi pembayaran ===" -ForegroundColor Cyan
Write-Host "API: $ApiBase"

$webhookBody = @{
    nominal        = $Nominal
    bank_pengirim  = "SeaBank"
    nama_pengirim  = "BUDI TEST"
    timestamp      = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
} | ConvertTo-Json

$headers = @{
    "Content-Type"               = "application/json"
    "X-Payment-Webhook-Secret" = $WebhookSecret
}

Write-Host "`n1. POST payment_webhook.php (simulasi notifikasi)..."
$webhook = Invoke-RestMethod -Uri "$ApiBase/payment_webhook.php" -Method Post -Body $webhookBody -Headers $headers
$webhook | ConvertTo-Json -Depth 5 | Write-Host

Write-Host "`n2. GET payment_status.php?booking_id=$BookingId ..."
$status = Invoke-RestMethod -Uri "$ApiBase/payment_status.php?booking_id=$BookingId" -Method Get
$status | ConvertTo-Json -Depth 5 | Write-Host

if ($status.payment_state -eq "received") {
    Write-Host "`nOK: Owner akan melihat 'Pembayaran Diterima' di Flutter." -ForegroundColor Green
} else {
    Write-Host "`nCatatan: status=$($status.payment_state). Pastikan migrasi 004 + booking awaitingPayment dengan nominal $Nominal." -ForegroundColor Yellow
}
