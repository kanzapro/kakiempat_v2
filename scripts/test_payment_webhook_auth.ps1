# Uji proteksi X-Payment-Webhook-Secret di payment_webhook.php
param(
    [string]$ApiBase = "https://www.api.kakiempat.com",
    [string]$WebhookSecret = "KE_SECURE_NOTIF_TOKEN_2026_BYPASS",
    [int]$Nominal = 150102
)

$ErrorActionPreference = "Stop"
$url = "$ApiBase/payment_webhook.php"
$body = @{
    nominal        = $Nominal
    bank_pengirim  = "SEABANK_WISE"
    nama_pengirim  = "John"
    timestamp      = "12345"
} | ConvertTo-Json

Write-Host "=== Tes 1: Tanpa token (harus 401) ===" -ForegroundColor Cyan
try {
    Invoke-WebRequest -Uri $url -Method Post -Body $body -ContentType "application/json" -UseBasicParsing | Out-Null
    Write-Host "GAGAL: request tanpa token seharusnya ditolak" -ForegroundColor Red
} catch {
    $resp = $_.Exception.Response
    if ($resp -and $resp.StatusCode.value__ -eq 401) {
        $reader = New-Object System.IO.StreamReader($resp.GetResponseStream())
        $json = $reader.ReadToEnd() | ConvertFrom-Json
        Write-Host "OK HTTP 401:" ($json | ConvertTo-Json -Compress) -ForegroundColor Green
    } else {
        throw
    }
}

Write-Host "`n=== Tes 2: Token salah (harus 401) ===" -ForegroundColor Cyan
try {
    $badHeaders = @{
        "Content-Type"               = "application/json"
        "X-Payment-Webhook-Secret" = "TOKEN_SALAH"
    }
    Invoke-WebRequest -Uri $url -Method Post -Body $body -Headers $badHeaders -UseBasicParsing | Out-Null
    Write-Host "GAGAL: token salah seharusnya ditolak" -ForegroundColor Red
} catch {
    $resp = $_.Exception.Response
    if ($resp -and $resp.StatusCode.value__ -eq 401) {
        Write-Host "OK HTTP 401 (token salah ditolak)" -ForegroundColor Green
    } else {
        throw
    }
}

Write-Host "`n=== Tes 3: Token benar (harus 200) ===" -ForegroundColor Cyan
$goodHeaders = @{
    "Content-Type"               = "application/json"
    "X-Payment-Webhook-Secret" = $WebhookSecret
}
$result = Invoke-RestMethod -Uri $url -Method Post -Body $body -Headers $goodHeaders
Write-Host ($result | ConvertTo-Json -Compress) -ForegroundColor Green
