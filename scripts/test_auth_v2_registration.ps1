# Uji 6 skenario pendaftaran & login auth v2 (API live).
param(
    [string]$ApiBase = 'https://www.api.kakiempat.com'
)

$ErrorActionPreference = 'Stop'
$auth = "$ApiBase/auth_v2.php"
$results = @()

function Write-JsonFile($path, $json) {
    [System.IO.File]::WriteAllText($path, $json)
}

function Invoke-Register($phone, $password, $name, $role) {
    $body = (@{ phone = $phone; password = $password; name = $name; role = $role } | ConvertTo-Json -Compress)
    $f = Join-Path $env:TEMP "auth_reg_$([guid]::NewGuid().ToString('N')).json"
    Write-JsonFile $f $body
    $raw = curl.exe -sS -X POST "$auth`?action=register" -H 'Content-Type: application/json' --data-binary "@$f"
    Remove-Item $f -Force -ErrorAction SilentlyContinue
    return $raw | ConvertFrom-Json
}

function Invoke-Login($phone, $password) {
    $body = (@{ phone = $phone; password = $password } | ConvertTo-Json -Compress)
    $f = Join-Path $env:TEMP "auth_log_$([guid]::NewGuid().ToString('N')).json"
    Write-JsonFile $f $body
    $raw = curl.exe -sS -X POST "$auth`?action=login" -H 'Content-Type: application/json' --data-binary "@$f"
    Remove-Item $f -Force -ErrorAction SilentlyContinue
    return $raw | ConvertFrom-Json
}

function Add-Result($id, $desc, $pass, $detail) {
    $script:results += [pscustomobject]@{ Id = $id; Skenario = $desc; Lulus = $pass; Detail = $detail }
}

Write-Host '=== AUTH V2 — uji pendaftaran ===' -ForegroundColor Cyan

# 1. Owner format 081234567890 (gunakan nomor unik jika sudah terdaftar)
$ownerPhone = '0812' + (Get-Random -Maximum 99999999).ToString('D8')
$r1 = Invoke-Register $ownerPhone 'test1234' 'Owner Uji' 'owner'
Add-Result 1 'Daftar owner (format 08xx)' ($r1.ok -eq $true) ($r1 | ConvertTo-Json -Compress)

# 2. Sitter format 6281234567891 (unik)
$sitterPhone = '62812' + (Get-Random -Maximum 999999999).ToString('D9')
$r2 = Invoke-Register $sitterPhone 'test1234' 'Sitter Uji' 'sitter'
Add-Result 2 'Daftar sitter (format 62xx)' ($r2.ok -eq $true) ($r2 | ConvertTo-Json -Compress)

# 3. Nomor sama → pesan duplikat
$r3 = Invoke-Register $ownerPhone 'test1234' 'Duplikat' 'owner'
$msg3 = $r3.message
Add-Result 3 'Daftar nomor sama' (
    $r3.ok -eq $false -and $msg3 -like '*sudah terdaftar*'
) ($r3 | ConvertTo-Json -Compress)

# 4. Password pendek
$r4 = Invoke-Register ('62813' + (Get-Random -Maximum 999999999).ToString('D9')) '12345' 'X' 'owner'
Add-Result 4 'Password 5 karakter ditolak' (
    $r4.ok -eq $false -and $r4.message -like '*minimal 6*'
) ($r4 | ConvertTo-Json -Compress)

# 5. Login sukses
$r5 = Invoke-Login $ownerPhone 'test1234'
Add-Result 5 'Login nomor baru' ($r5.ok -eq $true) ($r5 | ConvertTo-Json -Compress)

# 6. Password salah
$r6 = Invoke-Login $ownerPhone 'salah123'
Add-Result 6 'Login password salah' (
    $r6.ok -eq $false -and $r6.message -like '*Kata sandi salah*'
) ($r6 | ConvertTo-Json -Compress)

$results | Format-Table -AutoSize
$failed = @($results | Where-Object { -not $_.Lulus })
if ($failed.Count -gt 0) {
    Write-Host "GAGAL: $($failed.Count) skenario" -ForegroundColor Red
    exit 1
}
Write-Host 'Semua 6 skenario LULUS.' -ForegroundColor Green
