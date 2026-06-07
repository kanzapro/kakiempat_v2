# Upload build/deploy_api ke docroot via cPanel UAPI (darurat — prefer deploy_git.ps1 + git push).
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

function Get-IniValue($text, $section, $key) {
    $in = $false
    foreach ($line in $text -split "`n") {
        $t = $line.Trim()
        if ($t -match '^\[(.+)\]$') { $in = ($Matches[1] -eq $section); continue }
        if ($in -and $t -match "^$key=(.*)$") { return $Matches[1].Trim() }
    }
    return $null
}

$credPath = Join-Path $root '.cursor\secrets\hosting.credentials'
if (-not (Test-Path $credPath)) { throw "Missing $credPath" }
$ini = Get-Content $credPath -Raw
$user = Get-IniValue $ini 'cpanel' 'username'
$pass = Get-IniValue $ini 'cpanel' 'password'
if (-not $user -or -not $pass) { throw 'cpanel credentials required' }

$apiSrc = Join-Path $root 'build\deploy_api'
if (-not (Test-Path $apiSrc)) {
    & (Join-Path $root 'scripts\deploy_api.ps1')
}
$remoteBase = '/home/kakiempa/api.kakiempat.com'

$files = Get-ChildItem -Path $apiSrc -Recurse -File
Write-Host "Uploading $($files.Count) files -> $remoteBase"
function Send-CpanelFile([string]$local, [string]$dir, [string]$name, [int]$maxRetry = 5) {
    for ($i = 1; $i -le $maxRetry; $i++) {
        $out = curl.exe -sS --connect-timeout 60 --max-time 180 -u "${user}:${pass}" `
            -H 'Accept: application/json' `
            'https://kakiempat.com:2083/execute/Fileman/save_file_content' `
            --data-urlencode "dir=$dir" `
            --data-urlencode "file=$name" `
            --data-urlencode "content@$local" 2>&1
        if ($out -match '"status":1') { return $true }
        if ($i -lt $maxRetry) {
            $wait = [Math]::Min(30, 3 * $i)
            Write-Host "  retry $i/$maxRetry in ${wait}s..."
            Start-Sleep -Seconds $wait
        } else {
            throw "Upload gagal $name : $out"
        }
    }
    return $false
}

$ok = 0
$fail = 0
foreach ($f in $files) {
    $rel = $f.FullName.Substring($apiSrc.Length).TrimStart('\').Replace('\', '/')
    $dir = if ($rel.Contains('/')) {
        "$remoteBase/" + (Split-Path $rel -Parent).Replace('\', '/')
    } else {
        $remoteBase
    }
    try {
        Send-CpanelFile $f.FullName $dir $f.Name | Out-Null
        $ok++
        Write-Host "[OK] $rel"
        Start-Sleep -Milliseconds 500
    } catch {
        $fail++
        Write-Host "[FAIL] $rel : $_"
    }
}
Write-Host "Deploy API selesai: $ok ok, $fail fail" -ForegroundColor $(if ($fail -eq 0) { 'Green' } else { 'Red' })
if ($fail -gt 0) { exit 1 }
