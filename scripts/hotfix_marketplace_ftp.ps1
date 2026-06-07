$root = 'd:\Project_Flutter\kakiempat_v2'
& (Join-Path $root 'scripts\deploy_api.ps1') | Out-Null
$cred = Get-Content (Join-Path $root '.cursor\secrets\hosting.credentials') -Raw
function Get-IniValue($text, $section, $key) {
    $in = $false
    foreach ($line in $text -split "`n") {
        $t = $line.Trim()
        if ($t -match '^\[(.+)\]$') { $in = ($Matches[1] -eq $section); continue }
        if ($in -and $t -match "^${key}=(.*)$") { return $Matches[1].Trim() }
    }
    return $null
}
$u = Get-IniValue $cred 'cpanel' 'username'
$p = Get-IniValue $cred 'cpanel' 'password'
$local = Join-Path $root 'build\deploy_api\lib\kakiempat_marketplace_v2.php'
Write-Host 'Upload marketplace lib hotfix'
curl.exe -sS --ftp-pasv -u "${u}:${p}" -T $local 'ftp://ftp.kakiempat.com/api.kakiempat.com/lib/kakiempat_marketplace_v2.php'
