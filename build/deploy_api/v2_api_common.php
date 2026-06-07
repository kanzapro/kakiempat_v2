<?php
declare(strict_types=1);

require_once __DIR__ . '/cors.php';
require_once __DIR__ . '/lib/kakiempat_security_v2.php';

function v2ApiRespond(array $payload, int $status = 200): void
{
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

/** Response standar Batch 1: {ok: true, data: ...} */
function v2ApiRespondData(mixed $data, int $status = 200): void
{
    v2ApiRespond(['ok' => true, 'data' => $data], $status);
}

function v2ApiFail(string $error, string $message, int $status = 400): void
{
    v2ApiRespond(['ok' => false, 'error' => $error, 'message' => $message], $status);
}

function v2ApiAssertLocalMysqlHost(string $host): void
{
    $normalized = strtolower(trim($host));
    $allowed = ['localhost', '127.0.0.1', '::1'];
    if (!in_array($normalized, $allowed, true)) {
        error_log('v2_api: MySQL host tidak diizinkan (harus localhost).');
        v2ApiFail('config_invalid', 'Konfigurasi database tidak valid.', 503);
    }
}

/** @param array<string, mixed> $cfg */
function v2ApiBuildPdoOptions(array $cfg): array
{
    $options = [
        PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES => false,
    ];

    $connectTimeout = (int) ($cfg['connect_timeout'] ?? 5);
    if ($connectTimeout > 0) {
        $options[PDO::ATTR_TIMEOUT] = $connectTimeout;
        if (defined('PDO::MYSQL_ATTR_CONNECT_TIMEOUT')) {
            $options[PDO::MYSQL_ATTR_CONNECT_TIMEOUT] = $connectTimeout;
        }
    }

    if (!empty($cfg['persistent'])) {
        $options[PDO::ATTR_PERSISTENT] = true;
    }

    if (defined('PDO::MYSQL_ATTR_INIT_COMMAND')) {
        $options[PDO::MYSQL_ATTR_INIT_COMMAND] =
            "SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci, time_zone = '+00:00'";
    }

    return $options;
}

function v2ApiPdoPing(PDO $pdo): bool
{
    try {
        $pdo->query('SELECT 1');

        return true;
    } catch (PDOException $e) {
        $code = (int) ($e->errorInfo[1] ?? 0);
        $goneAway = in_array($code, [2006, 2013], true)
            || str_contains(strtolower($e->getMessage()), 'gone away');

        return !$goneAway;
    }
}

function v2ApiCreatePdo(): PDO
{
    $configFile = __DIR__ . '/.mysql_v2.php';
    if (!is_readable($configFile)) {
        v2ApiFail('config_missing', 'Layanan belum siap. Hubungi admin.', 503);
    }
    /** @var array{host:string,db:string,user:string,pass:string,port?:int,persistent?:bool,connect_timeout?:int} $cfg */
    $cfg = require $configFile;
    v2ApiAssertLocalMysqlHost((string) ($cfg['host'] ?? ''));

    $pdo = new PDO(
        sprintf(
            'mysql:host=%s;port=%d;dbname=%s;charset=utf8mb4',
            $cfg['host'],
            (int) ($cfg['port'] ?? 3306),
            $cfg['db'],
        ),
        $cfg['user'],
        $cfg['pass'],
        v2ApiBuildPdoOptions($cfg),
    );

    if (!defined('PDO::MYSQL_ATTR_INIT_COMMAND')) {
        $pdo->exec('SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci');
        $pdo->exec("SET time_zone = '+00:00'");
    }

    return $pdo;
}

function v2ApiPdo(): PDO
{
    static $pdo = null;
    if ($pdo instanceof PDO) {
        if (!v2ApiPdoPing($pdo)) {
            $pdo = null;
        } else {
            return $pdo;
        }
    }

    $pdo = v2ApiCreatePdo();

    return $pdo;
}

/** @return array<string, int|float|null> */
function v2ApiMysqlPoolMetrics(?PDO $pdo = null): array
{
    try {
        $pdo = $pdo ?? v2ApiPdo();
        $vars = $pdo->query(
            "SHOW GLOBAL VARIABLES WHERE Variable_name IN ('max_connections', 'wait_timeout')",
        )->fetchAll(PDO::FETCH_KEY_PAIR);
        $status = $pdo->query(
            "SHOW GLOBAL STATUS WHERE Variable_name IN (
                'Threads_connected', 'Threads_running', 'Max_used_connections', 'Aborted_connects'
            )",
        )->fetchAll(PDO::FETCH_KEY_PAIR);

        $maxConn = (int) ($vars['max_connections'] ?? 0);
        $threads = (int) ($status['Threads_connected'] ?? 0);

        return [
            'max_connections' => $maxConn,
            'threads_connected' => $threads,
            'threads_running' => (int) ($status['Threads_running'] ?? 0),
            'max_used_connections' => (int) ($status['Max_used_connections'] ?? 0),
            'aborted_connects' => (int) ($status['Aborted_connects'] ?? 0),
            'wait_timeout_sec' => (int) ($vars['wait_timeout'] ?? 0),
            'utilization_pct' => $maxConn > 0 ? round(($threads / $maxConn) * 100, 2) : null,
        ];
    } catch (Throwable) {
        return [];
    }
}

/** @return array<string, mixed> */
function v2ApiBody(): array
{
    $raw = file_get_contents('php://input') ?: '';
    if ($raw === '') {
        return [];
    }
    $decoded = json_decode($raw, true);
    return is_array($decoded) ? $decoded : [];
}

function v2ApiTableExists(PDO $pdo, string $table): bool
{
    $stmt = $pdo->prepare(
        'SELECT 1 FROM information_schema.TABLES
         WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? LIMIT 1',
    );
    $stmt->execute([$table]);
    return (bool) $stmt->fetchColumn();
}

function v2ApiColumnExists(PDO $pdo, string $table, string $column): bool
{
    $stmt = $pdo->prepare(
        'SELECT 1 FROM information_schema.COLUMNS
         WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? AND COLUMN_NAME = ? LIMIT 1',
    );
    $stmt->execute([$table, $column]);
    return (bool) $stmt->fetchColumn();
}

function v2ApiExtractBearerToken(): string
{
    $header = trim((string) ($_SERVER['HTTP_AUTHORIZATION'] ?? ''));
    if (str_starts_with(strtolower($header), 'bearer ')) {
        return trim(substr($header, 7));
    }
    $native = trim((string) ($_SERVER['HTTP_X_NATIVE_SESSION'] ?? ''));
    if ($native !== '') {
        return $native;
    }
    return trim((string) ($_GET['token'] ?? ''));
}

/**
 * @return array{user_id:int,id:int,name:string,role:string,phone:string}
 */
function v2ApiRequireAuth(?PDO $pdo = null): array
{
    $pdo = $pdo ?? v2ApiPdo();
    $token = v2ApiExtractBearerToken();
    if ($token === '' || !preg_match('/^native_[a-f0-9]{64}$/', $token)) {
        v2ApiSecurityLog($pdo, 'invalid_token_format');
        v2ApiFail('token_required', 'Silakan masuk terlebih dahulu.', 401);
    }

    $stmt = $pdo->prepare(
        'SELECT u.id, u.name, u.role, u.whatsapp, s.expires_at
         FROM kakiempa_v2_sessions s
         INNER JOIN kakiempa_v2_users u ON u.id = s.user_id
         WHERE s.token_hash = :hash AND u.is_active = 1 LIMIT 1',
    );
    $stmt->execute(['hash' => hash('sha256', $token)]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!is_array($row)) {
        v2ApiSecurityLog($pdo, 'invalid_token');
        v2ApiFail('invalid_token', 'Sesi tidak valid. Silakan masuk lagi.', 401);
    }

    $expires = new DateTimeImmutable((string) $row['expires_at'], new DateTimeZone('UTC'));
    if ($expires < new DateTimeImmutable('now', new DateTimeZone('UTC'))) {
        v2ApiSecurityLog($pdo, 'token_expired', (int) $row['id']);
        v2ApiFail('token_expired', 'Sesi kedaluwarsa. Silakan masuk lagi.', 401);
    }

    $userId = (int) $row['id'];
    $role = (string) $row['role'];
    $roles = function_exists('kakiempat_v2_fetch_user_roles')
        ? kakiempat_v2_fetch_user_roles($pdo, $userId, $role)
        : [$role];

    return [
        'user_id' => $userId,
        'id' => $userId,
        'name' => (string) $row['name'],
        'role' => $role,
        'roles' => $roles,
        'phone' => (string) ($row['whatsapp'] ?? ''),
    ];
}

/** @param list<string> $roles */
function v2ApiRequireRole(array $auth, array $roles): void
{
    $effective = $auth['roles'] ?? [$auth['role']];
    if (!is_array($effective)) {
        $effective = [(string) $auth['role']];
    }
    foreach ($roles as $required) {
        if (in_array($required, $effective, true)) {
            return;
        }
    }
    v2ApiFail('forbidden', 'Anda tidak memiliki akses untuk aksi ini.', 403);
}

function v2ApiIsAdmin(array $auth): bool
{
    return in_array($auth['role'], ['admin', 'founder'], true);
}

function v2ApiRequireFounder(array $auth): void
{
    if ($auth['role'] !== 'founder') {
        try {
            v2ApiSecurityLog(v2ApiPdo(), 'admin_access_denied', (int) $auth['user_id'], [
                'role' => $auth['role'],
            ]);
        } catch (Throwable) {
            // ignore logging failures
        }
        v2ApiFail('forbidden', 'Hanya founder yang dapat mengakses endpoint admin.', 403);
    }
}

/** @return array<string, mixed>|null */
function v2ApiFetchUser(PDO $pdo, int $userId): ?array
{
    $stmt = $pdo->prepare(
        'SELECT id, name, whatsapp, role FROM kakiempa_v2_users WHERE id = ? LIMIT 1',
    );
    $stmt->execute([$userId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    return is_array($row) ? $row : null;
}
