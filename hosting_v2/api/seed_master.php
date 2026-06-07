<?php
declare(strict_types=1);

/**
 * One-shot seed akun master/founder ke database kakiempa_v2 saja.
 * POST ?key=<V2_MIGRATE_SECRET>
 */
require_once __DIR__ . '/cors.php';

header('Content-Type: application/json; charset=utf-8');

if (!in_array($_SERVER['REQUEST_METHOD'] ?? 'GET', ['POST', 'GET'], true)) {
    http_response_code(405);
    echo json_encode(['ok' => false, 'error' => 'method_not_allowed']);
    exit;
}

function seedMasterFail(int $status, array $payload): void
{
    http_response_code($status);
    echo json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function seedMasterExpectedSecret(): string
{
    $fromEnv = getenv('V2_MIGRATE_SECRET');
    if (is_string($fromEnv) && trim($fromEnv) !== '') {
        return trim($fromEnv);
    }
    $secretFile = __DIR__ . '/.migrate_v2_secret';
    if (is_readable($secretFile)) {
        return trim((string) file_get_contents($secretFile));
    }
    return '';
}

$expected = seedMasterExpectedSecret();
$given = trim((string) ($_GET['key'] ?? $_POST['key'] ?? ''));
if ($expected === '' || $given === '' || !hash_equals($expected, $given)) {
    seedMasterFail(403, ['ok' => false, 'error' => 'secret_invalid']);
}

$configFile = __DIR__ . '/.mysql_v2.php';
if (!is_readable($configFile)) {
    seedMasterFail(503, ['ok' => false, 'error' => 'config_missing', 'hint' => '.mysql_v2.php']);
}

/** @var array{host:string,db:string,user:string,pass:string,port?:int} $cfg */
$cfg = require $configFile;

try {
    $pdo = new PDO(
        sprintf(
            'mysql:host=%s;port=%d;dbname=%s;charset=utf8mb4',
            $cfg['host'],
            (int) ($cfg['port'] ?? 3306),
            $cfg['db'],
        ),
        $cfg['user'],
        $cfg['pass'],
        [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        ],
    );
    $pdo->exec("SET NAMES utf8mb4 COLLATE utf8mb4_unicode_ci");
    $pdo->exec("SET time_zone = '+00:00'");
} catch (PDOException $e) {
    seedMasterFail(500, ['ok' => false, 'error' => 'db_connect', 'message' => $e->getMessage()]);
}

/**
 * @return array<string, bool>
 */
function seedMasterTableColumns(PDO $pdo, string $table): array
{
    $stmt = $pdo->prepare(
        'SELECT COLUMN_NAME FROM information_schema.COLUMNS
         WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ?',
    );
    $stmt->execute([$table]);
    $out = [];
    foreach ($stmt->fetchAll(PDO::FETCH_COLUMN) as $name) {
        $out[(string) $name] = true;
    }
    return $out;
}

function seedMasterTableExists(PDO $pdo, string $table): bool
{
    $stmt = $pdo->prepare(
        'SELECT 1 FROM information_schema.TABLES
         WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = ? LIMIT 1',
    );
    $stmt->execute([$table]);
    return (bool) $stmt->fetchColumn();
}

function seedMasterEnsureFounderRole(PDO $pdo): void
{
    $stmt = $pdo->query(
        "SELECT COLUMN_TYPE FROM information_schema.COLUMNS
         WHERE TABLE_SCHEMA = DATABASE()
           AND TABLE_NAME = 'kakiempa_users'
           AND COLUMN_NAME = 'role'
         LIMIT 1",
    );
    $row = $stmt ? $stmt->fetch(PDO::FETCH_ASSOC) : false;
    $type = strtolower((string) ($row['COLUMN_TYPE'] ?? ''));
    if ($type !== '' && !str_contains($type, 'founder')) {
        $pdo->exec(
            "ALTER TABLE `kakiempa_users`
             MODIFY `role` ENUM('admin','sitter','owner','founder') NOT NULL DEFAULT 'owner'",
        );
    }
}

function seedMasterEnsureExternalUidColumn(PDO $pdo): void
{
    $cols = seedMasterTableColumns($pdo, 'kakiempa_users');
    if (isset($cols['supabase_user_id'])) {
        return;
    }
    $pdo->exec(
        'ALTER TABLE `kakiempa_users`
         ADD COLUMN `supabase_user_id` VARCHAR(64) NULL AFTER `role`',
    );
}

function seedMasterEnsureNativeSessionsTable(PDO $pdo): void
{
    if (seedMasterTableExists($pdo, 'kakiempa_native_sessions')) {
        return;
    }
    if (seedMasterTableExists($pdo, 'kakiempa_sessions')) {
        $pdo->exec(
            'CREATE TABLE IF NOT EXISTS `kakiempa_native_sessions` LIKE `kakiempa_sessions`',
        );
        return;
    }
    $pdo->exec(
        'CREATE TABLE IF NOT EXISTS `kakiempa_native_sessions` (
          `token_hash` CHAR(64) NOT NULL,
          `user_id` BIGINT UNSIGNED NOT NULL,
          `phone` VARCHAR(32) NOT NULL,
          `role` ENUM(\'owner\', \'sitter\', \'admin\', \'founder\') NOT NULL DEFAULT \'admin\',
          `expires_at` TIMESTAMP(6) NOT NULL,
          `created_at` TIMESTAMP(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
          PRIMARY KEY (`token_hash`),
          KEY `idx_native_sessions_user` (`user_id`),
          KEY `idx_native_sessions_expires` (`expires_at`),
          CONSTRAINT `fk_native_sessions_user_v2` FOREIGN KEY (`user_id`)
            REFERENCES `kakiempa_users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci',
    );
}

function seedMasterUuidV4(): string
{
    $bytes = random_bytes(16);
    $bytes[6] = chr((ord($bytes[6]) & 0x0f) | 0x40);
    $bytes[8] = chr((ord($bytes[8]) & 0x3f) | 0x80);
    $hex = bin2hex($bytes);
    return sprintf(
        '%s-%s-%s-%s-%s',
        substr($hex, 0, 8),
        substr($hex, 8, 4),
        substr($hex, 12, 4),
        substr($hex, 16, 4),
        substr($hex, 20, 12),
    );
}

function seedMasterAuthEmail(string $phoneE164): string
{
    return 'p' . preg_replace('/\D/', '', $phoneE164) . '@phone.kakiempat.app';
}

const SEED_MASTER_PHONE = '6281248826888';
const SEED_MASTER_PASSWORD_PLAIN = '123456';
const SEED_MASTER_DISPLAY_NAME = 'Master Admin';
const SEED_MASTER_ROLE = 'founder';
const SEED_MASTER_TOKEN_EXPIRY_SEC = 2592000;

try {
    seedMasterEnsureFounderRole($pdo);
    seedMasterEnsureExternalUidColumn($pdo);
    seedMasterEnsureNativeSessionsTable($pdo);

    $userCols = seedMasterTableColumns($pdo, 'kakiempa_users');
    if (!isset($userCols['password'])) {
        seedMasterFail(500, ['ok' => false, 'error' => 'users_schema_invalid']);
    }

    $phone = SEED_MASTER_PHONE;
    $email = seedMasterAuthEmail($phone);
    $hash = password_hash(SEED_MASTER_PASSWORD_PLAIN, PASSWORD_BCRYPT);
    $userUuid = seedMasterUuidV4();

    $phoneCol = isset($userCols['phone']) ? 'phone' : 'whatsapp';
    $nameCol = isset($userCols['display_name']) ? 'display_name' : 'name';

    $lookup = $pdo->prepare(
        "SELECT `id`, `supabase_user_id` FROM `kakiempa_users`
         WHERE `email` = ? OR `{$phoneCol}` = ? LIMIT 1",
    );
    $lookup->execute([$email, $phone]);
    $existing = $lookup->fetch(PDO::FETCH_ASSOC);

    if ($existing) {
        $mysqlUserId = (int) $existing['id'];
        $storedUuid = trim((string) ($existing['supabase_user_id'] ?? ''));
        if ($storedUuid !== '') {
            $userUuid = $storedUuid;
        }
        $updateSql = "UPDATE `kakiempa_users` SET `{$nameCol}` = ?, `password` = ?, `role` = ?,
            `{$phoneCol}` = ?, `supabase_user_id` = COALESCE(NULLIF(TRIM(`supabase_user_id`), ''), ?)
            WHERE `id` = ?";
        $pdo->prepare($updateSql)->execute([
            SEED_MASTER_DISPLAY_NAME,
            $hash,
            SEED_MASTER_ROLE,
            $phone,
            $userUuid,
            $mysqlUserId,
        ]);
    } else {
        $insertCols = ["`{$nameCol}`", '`email`', '`password`', '`role`', '`supabase_user_id`', "`{$phoneCol}`"];
        $placeholders = array_fill(0, count($insertCols), '?');
        $values = [
            SEED_MASTER_DISPLAY_NAME,
            $email,
            $hash,
            SEED_MASTER_ROLE,
            $userUuid,
            $phone,
        ];
        if (isset($userCols['created_at'])) {
            $insertCols[] = '`created_at`';
            $placeholders[] = 'CURRENT_TIMESTAMP(6)';
        }
        $sql = 'INSERT INTO `kakiempa_users` (' . implode(', ', $insertCols) . ')
            VALUES (' . implode(', ', $placeholders) . ')';
        $stmt = $pdo->prepare($sql);
        $stmt->execute($values);
        $mysqlUserId = (int) $pdo->lastInsertId();
    }

    $raw = bin2hex(random_bytes(32));
    $token = 'native_' . $raw;
    $tokenHash = hash('sha256', $raw);
    $expiresAt = (new DateTimeImmutable('+' . SEED_MASTER_TOKEN_EXPIRY_SEC . ' seconds'))
        ->format('Y-m-d H:i:s.u');
    $sessionRole = 'admin';

    $sessionCols = seedMasterTableColumns($pdo, 'kakiempa_native_sessions');
    if (isset($sessionCols['token']) && !isset($sessionCols['token_hash'])) {
        $sessionUserId = $mysqlUserId;
        if (isset($sessionCols['user_id'])) {
            $typeStmt = $pdo->prepare(
                "SELECT DATA_TYPE FROM information_schema.COLUMNS
                 WHERE TABLE_SCHEMA = DATABASE()
                   AND TABLE_NAME = 'kakiempa_native_sessions'
                   AND COLUMN_NAME = 'user_id' LIMIT 1",
            );
            $typeStmt->execute();
            $dataType = strtolower((string) $typeStmt->fetchColumn());
            if ($dataType === 'char' || $dataType === 'varchar' || $dataType === 'binary') {
                $sessionUserId = $userUuid;
            }
        }
        $pdo->prepare(
            'INSERT INTO `kakiempa_native_sessions`
            (`token`, `user_id`, `phone`, `role`, `expires_at`)
            VALUES (?, ?, ?, ?, ?)',
        )->execute([$token, $sessionUserId, $phone, SEED_MASTER_ROLE, $expiresAt]);
    } else {
        $pdo->prepare(
            'INSERT INTO `kakiempa_native_sessions`
            (`token_hash`, `user_id`, `phone`, `role`, `expires_at`)
            VALUES (?, ?, ?, ?, ?)',
        )->execute([$tokenHash, $mysqlUserId, $phone, $sessionRole, $expiresAt]);
    }

    echo json_encode([
        'ok' => true,
        'user_id' => $userUuid,
        'token' => $token,
        'mysql_user_id' => $mysqlUserId,
        'database' => $cfg['db'],
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
} catch (Throwable $e) {
    seedMasterFail(500, ['ok' => false, 'error' => 'seed_failed', 'message' => $e->getMessage()]);
}
