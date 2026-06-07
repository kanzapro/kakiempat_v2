# Jalankan migrasi SQL v2 di server (setelah upload build/deploy_api + schema/).
param(
    [string]$SecretFile = (Join-Path (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) 'build\migrate_secret.txt'),
    [string]$File = '001_core_tables.sql',
    [string]$SecretIniSection = 'api_deploy',
    [string]$SecretIniKey = 'migrate_secret',
    [string]$ApiBase = 'https://www.api.kakiempat.com'
)

$ErrorActionPreference = 'Stop'
$secret = $null
if (Test-Path $SecretFile) {
    $secret = (Get-Content -Raw $SecretFile).Trim()
} else {
    $credPath = Join-Path (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) '.cursor\secrets\hosting.credentials'
    if (Test-Path $credPath) {
        function Get-IniValue($text, $section, $key) {
            $in = $false
            foreach ($line in $text -split "`n") {
                $t = $line.Trim()
                if ($t -match '^\[(.+)\]$') { $in = ($Matches[1] -eq $section); continue }
                if ($in -and $t -match "^$key=(.*)$") { return $Matches[1].Trim() }
            }
            return $null
        }
        $ini = Get-Content $credPath -Raw
        $secret = Get-IniValue $ini $SecretIniSection $SecretIniKey
    }
}
if (-not $secret) {
    throw 'Secret migrasi tidak ditemukan (build/migrate_secret.txt atau hosting.credentials [api_deploy]).'
}
$qSecret = [uri]::EscapeDataString($secret)
$qFile = [uri]::EscapeDataString($File)
$url = "${ApiBase}/apply_v2_migration.php?secret=${qSecret}&file=${qFile}"
Write-Host "Migrasi: $File ..."
$curlHeaders = @('-H', 'Accept: application/json', '-A', 'KakiEmpatDeploy/1.0')
$body = curl.exe -sS @curlHeaders $url
Write-Host $body
Write-Host ''
Write-Host 'Health check:'
curl.exe -sS @curlHeaders "${ApiBase}/index.php"
