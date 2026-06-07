<?php
declare(strict_types=1);

/**
 * Backup otomatis database kakiempa_v2.
 *
 * Cron CLI (tanpa secret — dijalankan di server):
 *   0 2 * * * /usr/local/bin/php /home/kakiempa/api.kakiempat.com/backup_db_v2.php
 *
 * Cron HTTP (via curl):
 *   0 2 * * * /usr/bin/curl -s "https://api.kakiempat.com/backup_db_v2.php?key=SECRET" > /dev/null 2>&1
 *
 * Secret: file .migrate_v2_secret (docroot API) atau env V2_MIGRATE_SECRET.
 */
define('KAKIEMPAT_SKIP_STRICT_CORS', true);
require_once __DIR__ . '/v2_api_common.php';

const BACKUP_V2_RETENTION_DAYS = 7;
const BACKUP_V2_HOME = '/home/kakiempa';
const BACKUP_V2_DIR = BACKUP_V2_HOME . '/backups';
const BACKUP_V2_LOG_DIR = BACKUP_V2_HOME . '/logs';
const BACKUP_V2_LOG_FILE = BACKUP_V2_LOG_DIR . '/backup_v2.log';

function backup_v2_resolve_secret(): ?string
{
    $fromEnv = getenv('V2_MIGRATE_SECRET');
    if (is_string($fromEnv) && trim($fromEnv) !== '') {
        return trim($fromEnv);
    }
    $secretFile = __DIR__ . '/.migrate_v2_secret';
    if (is_readable($secretFile)) {
        $secret = trim((string) file_get_contents($secretFile));
        return $secret !== '' ? $secret : null;
    }
    return null;
}

function backup_v2_ensure_dir(string $path): void
{
    if (!is_dir($path)) {
        mkdir($path, 0750, true);
    }
}

function backup_v2_ensure_htaccess(string $dir): void
{
    $htaccess = $dir . '/.htaccess';
    if (!is_file($htaccess)) {
        file_put_contents($htaccess, "Require all denied\n");
    }
}

function backup_v2_log(string $level, string $message, ?array $context = null): void
{
    backup_v2_ensure_dir(BACKUP_V2_LOG_DIR);
    $line = gmdate('Y-m-d H:i:s') . ' UTC [' . strtoupper($level) . '] ' . $message;
    if ($context !== null) {
        $line .= ' ' . json_encode($context, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    }
    file_put_contents(BACKUP_V2_LOG_FILE, $line . PHP_EOL, FILE_APPEND | LOCK_EX);
}

function backup_v2_respond(array $payload, int $status = 200): void
{
    if (PHP_SAPI !== 'cli') {
        http_response_code($status);
        header('Content-Type: application/json; charset=utf-8');
    }
    echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES) . PHP_EOL;
    exit($payload['ok'] === true ? 0 : 1);
}

function backup_v2_fail(string $error, string $message, int $status = 500): void
{
    backup_v2_log('error', $message, ['error' => $error]);
    backup_v2_respond(['ok' => false, 'error' => $error, 'message' => $message], $status);
}

function backup_v2_find_mysqldump(): string
{
    $mysqldump = trim((string) shell_exec('command -v mysqldump 2>/dev/null'));
    if ($mysqldump !== '') {
        return $mysqldump;
    }
    foreach (['/usr/bin/mysqldump', '/usr/local/bin/mysqldump', '/usr/local/mysql/bin/mysqldump'] as $candidate) {
        if (is_executable($candidate)) {
            return $candidate;
        }
    }
    return '';
}

function backup_v2_dump_via_pdo(PDO $pdo, string $sqlPath): bool
{
    $tables = [];
    $stmt = $pdo->query('SHOW TABLES');
    while ($row = $stmt->fetch(PDO::FETCH_NUM)) {
        $tables[] = (string) $row[0];
    }

    $sql = '-- Kaki Empat v2 backup ' . gmdate('c') . "\nSET NAMES utf8mb4;\nSET FOREIGN_KEY_CHECKS=0;\n";
    foreach ($tables as $table) {
        if (!preg_match('/^(kakiempa_v2_|kakiempa_)/', $table)) {
            continue;
        }
        $safeTable = str_replace('`', '``', $table);
        $create = $pdo->query('SHOW CREATE TABLE `' . $safeTable . '`')->fetch(PDO::FETCH_NUM);
        if (!is_array($create)) {
            continue;
        }
        $sql .= "\nDROP TABLE IF EXISTS `{$table}`;\n{$create[1]};\n";
        $rows = $pdo->query('SELECT * FROM `' . $safeTable . '`');
        while ($data = $rows->fetch(PDO::FETCH_ASSOC)) {
            $cols = array_keys($data);
            $vals = array_map(static function ($value) use ($pdo) {
                return $value === null ? 'NULL' : $pdo->quote((string) $value);
            }, array_values($data));
            $sql .= 'INSERT INTO `' . $table . '` (`' . implode('`,`', $cols) . '`) VALUES (' . implode(',', $vals) . ");\n";
        }
    }
    $sql .= "SET FOREIGN_KEY_CHECKS=1;\n";

    return file_put_contents($sqlPath, $sql) !== false;
}

$isCli = PHP_SAPI === 'cli';

if (!$isCli) {
    $expected = backup_v2_resolve_secret();
    if ($expected === null) {
        backup_v2_fail('config_missing', 'Secret backup belum dikonfigurasi.', 503);
    }
    $given = (string) ($_GET['key'] ?? $_GET['secret'] ?? '');
    if ($given === '' || !hash_equals($expected, $given)) {
        backup_v2_fail('key_invalid', 'Kunci backup tidak valid.', 403);
    }
}

$configFile = __DIR__ . '/.mysql_v2.php';
if (!is_readable($configFile)) {
    backup_v2_fail('mysql_config_missing', 'Konfigurasi MySQL tidak tersedia.', 503);
}

/** @var array{host:string,db:string,user:string,pass:string,port?:int} $cfg */
$cfg = require $configFile;
$dbName = (string) ($cfg['db'] ?? 'kakiempa_v2');
$port = (int) ($cfg['port'] ?? 3306);

$backupRoot = BACKUP_V2_DIR;
if (!is_dir($backupRoot) && !str_starts_with(BACKUP_V2_HOME, '/home/')) {
    $backupRoot = __DIR__ . '/backups';
}
backup_v2_ensure_dir($backupRoot);
backup_v2_ensure_htaccess($backupRoot);
backup_v2_ensure_dir(BACKUP_V2_LOG_DIR);

$stamp = gmdate('Ymd_His');
$isoTs = gmdate('c');
$baseName = 'backup_v2_' . $stamp;
$sqlFile = $backupRoot . '/' . $baseName . '.sql';
$gzFile = $backupRoot . '/' . $baseName . '.sql.gz';

backup_v2_log('info', 'Backup started', ['database' => $dbName, 'mode' => $isCli ? 'cli' : 'http']);

$dumped = false;
$mysqldump = backup_v2_find_mysqldump();

if ($mysqldump !== '') {
    $cmd = sprintf(
        '%s --host=%s --port=%d --user=%s --password=%s --single-transaction --routines --triggers %s > %s 2>/dev/null',
        escapeshellarg($mysqldump),
        escapeshellarg((string) $cfg['host']),
        $port,
        escapeshellarg((string) $cfg['user']),
        escapeshellarg((string) $cfg['pass']),
        escapeshellarg($dbName),
        escapeshellarg($sqlFile),
    );
    exec($cmd, $output, $exitCode);
    if ($exitCode === 0 && is_file($sqlFile) && filesize($sqlFile) > 128) {
        $gz = gzopen($gzFile, 'wb9');
        if ($gz !== false) {
            $raw = (string) file_get_contents($sqlFile);
            gzwrite($gz, $raw);
            gzclose($gz);
            @unlink($sqlFile);
            $dumped = is_file($gzFile) && filesize($gzFile) > 128;
        }
    } else {
        @unlink($sqlFile);
    }
}

if (!$dumped) {
    try {
        $pdo = v2ApiPdo();
        if (backup_v2_dump_via_pdo($pdo, $sqlFile)) {
            $gz = gzopen($gzFile, 'wb9');
            if ($gz === false) {
                throw new RuntimeException('Gagal membuka file gzip.');
            }
            gzwrite($gz, (string) file_get_contents($sqlFile));
            gzclose($gz);
            @unlink($sqlFile);
            $dumped = is_file($gzFile) && filesize($gzFile) > 128;
        }
    } catch (Throwable $e) {
        @unlink($sqlFile);
        @unlink($gzFile);
        backup_v2_fail('backup_failed', $e->getMessage(), 500);
    }
}

if (!$dumped) {
    backup_v2_fail('backup_failed', 'Dump database gagal.', 500);
}

$cutoff = time() - (BACKUP_V2_RETENTION_DAYS * 86400);
$deleted = 0;
foreach (glob($backupRoot . '/backup_v2_*.sql.gz') ?: [] as $oldFile) {
    $mtime = filemtime($oldFile);
    if ($mtime !== false && $mtime < $cutoff) {
        if (@unlink($oldFile)) {
            $deleted++;
            backup_v2_log('info', 'Deleted old backup', ['file' => basename($oldFile)]);
        }
    }
}

$size = (int) filesize($gzFile);
$fileName = basename($gzFile);

$result = [
    'ok' => true,
    'file' => $fileName,
    'size' => $size,
    'timestamp' => $isoTs,
];

backup_v2_log('info', 'Backup completed', [
    'file' => $fileName,
    'size' => $size,
    'deleted_old' => $deleted,
]);

backup_v2_respond($result, 200);
