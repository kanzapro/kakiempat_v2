# Paket & petunjuk deploy API v2 ke api.kakiempat.com
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$src = Join-Path $root 'hosting\api.kakiempat.com'
$dest = Join-Path $root 'build\deploy_api'
if (Test-Path $dest) { Remove-Item $dest -Recurse -Force }
New-Item -ItemType Directory -Force -Path $dest | Out-Null

$items = @(
    'auth_v2.php', 'user_v2.php', 'owner_v2.php', 'pet_v2.php', 'sitter_v2.php',
    'service_v2.php',
    'booking_v2.php', 'marketplace_v2.php', 'chat_v2.php', 'notification_v2.php',
    'review_v2.php', 'admin_v2.php', 'partner_v2.php', 'community_v2.php', 'business_v2.php',
    'cors.php', 'v2_api_common.php', 'index.php',
    'apply_v2_migration.php', 'health.php', 'wallet_v2.php',
    'payment_v2.php', 'payment_webhook.php',
    'payment_status.php', 'get_notifications.php', 'get_unread_notifications.php',
    'backup_db_v2.php', '.htaccess', 'robots.txt',
    'lib', 'schema', 'data', 'backups', 'uploads'
)
foreach ($name in $items) {
    $from = Join-Path $src $name
    if (-not (Test-Path $from)) { throw "Missing $from" }
    Copy-Item $from (Join-Path $dest $name) -Recurse -Force
}
foreach ($dot in @('.payment_webhook_secret', '.payment_config.php', '.mysql_v2.php', '.migrate_v2_secret')) {
    $from = Join-Path $src $dot
    if (Test-Path $from) {
        Copy-Item $from (Join-Path $dest $dot) -Force
    }
}

$sql = Join-Path $dest 'schema\mysql\001_core_tables.sql'
$bytes = (Get-Item $sql).Length
if ($bytes -lt 2048) { throw "001_core_tables.sql terlalu kecil ($bytes bytes)" }

Write-Host "Paket API: $dest ($bytes bytes SQL)"
Write-Host 'Commit build/deploy_api/ lalu git push — .cpanel.yml rsync ke api.kakiempat.com (wajib schema/mysql/).'
Write-Host 'Server: .mysql_v2.php + .migrate_v2_secret. Lalu scripts/run_v2_migration.ps1'
