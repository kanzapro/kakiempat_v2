<?php
declare(strict_types=1);

const V2_RATE_LIMIT_MAX = 5;
const V2_RATE_LIMIT_WINDOW = 300;

function v2ApiClientIp(): string
{
    $candidates = [
        trim((string) ($_SERVER['HTTP_CF_CONNECTING_IP'] ?? '')),
        trim((string) ($_SERVER['HTTP_X_FORWARDED_FOR'] ?? '')),
        trim((string) ($_SERVER['REMOTE_ADDR'] ?? '')),
    ];
    foreach ($candidates as $candidate) {
        if ($candidate === '') {
            continue;
        }
        $ip = trim(explode(',', $candidate)[0]);
        if (filter_var($ip, FILTER_VALIDATE_IP) !== false) {
            return $ip;
        }
    }
    return '0.0.0.0';
}

function v2ApiApplySecurityHeaders(): void
{
    if (headers_sent()) {
        return;
    }
    header('X-Content-Type-Options: nosniff');
    header('X-Frame-Options: DENY');
    header('X-XSS-Protection: 1; mode=block');
    header('Referrer-Policy: strict-origin-when-cross-origin');
    if (!empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off') {
        header('Strict-Transport-Security: max-age=31536000; includeSubDomains');
    }
}

function v2ApiSanitizeText(string $value, int $maxLen = 255): string
{
    $clean = trim(strip_tags($value));
    if (strlen($clean) > $maxLen) {
        $clean = substr($clean, 0, $maxLen);
    }
    return $clean;
}

function v2ApiRateLimitDataDir(): string
{
    $dir = dirname(__DIR__) . '/data/rate_limits';
    if (!is_dir($dir)) {
        mkdir($dir, 0750, true);
    }
    return $dir;
}

function v2ApiRateLimitFile(string $endpoint, int $maxAttempts, int $windowSeconds): void
{
    $ip = v2ApiClientIp();
    $key = hash('sha256', $ip . ':' . $endpoint);
    $path = v2ApiRateLimitDataDir() . '/' . $key . '.json';
    $now = time();
    $record = ['count' => 0, 'window_start' => $now];

    if (is_readable($path)) {
        $decoded = json_decode((string) file_get_contents($path), true);
        if (is_array($decoded)) {
            $record = $decoded;
        }
    }

    $windowStart = (int) ($record['window_start'] ?? $now);
    $count = (int) ($record['count'] ?? 0);
    if ($now - $windowStart >= $windowSeconds) {
        $windowStart = $now;
        $count = 0;
    }

    $count++;
    file_put_contents($path, json_encode(['count' => $count, 'window_start' => $windowStart]), LOCK_EX);

    if ($count > $maxAttempts) {
        v2ApiFail(
            'rate_limit_exceeded',
            'Terlalu banyak percobaan. Coba lagi dalam beberapa menit.',
            429,
        );
    }
}

function v2ApiRateLimit(PDO $pdo, string $endpoint, int $maxAttempts = V2_RATE_LIMIT_MAX, int $windowSeconds = V2_RATE_LIMIT_WINDOW): void
{
    if (!function_exists('v2ApiTableExists') || !v2ApiTableExists($pdo, 'kakiempa_rate_limits')) {
        v2ApiRateLimitFile($endpoint, $maxAttempts, $windowSeconds);
        return;
    }

    $ip = v2ApiClientIp();
    $rateKey = hash('sha256', $ip . ':' . $endpoint);

    $pdo->beginTransaction();
    try {
        $stmt = $pdo->prepare(
            'SELECT attempt_count, window_start FROM kakiempa_rate_limits WHERE rate_key = ? FOR UPDATE',
        );
        $stmt->execute([$rateKey]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        $now = new DateTimeImmutable('now', new DateTimeZone('UTC'));

        if (!is_array($row)) {
            $pdo->prepare(
                'INSERT INTO kakiempa_rate_limits (rate_key, attempt_count, window_start) VALUES (?, 1, ?)',
            )->execute([$rateKey, $now->format('Y-m-d H:i:s')]);
            $pdo->commit();
            return;
        }

        $windowStart = new DateTimeImmutable((string) $row['window_start'], new DateTimeZone('UTC'));
        $count = (int) $row['attempt_count'];
        if ($now->getTimestamp() - $windowStart->getTimestamp() >= $windowSeconds) {
            $count = 0;
            $windowStart = $now;
        }

        $count++;
        $pdo->prepare(
            'UPDATE kakiempa_rate_limits SET attempt_count = ?, window_start = ? WHERE rate_key = ?',
        )->execute([$count, $windowStart->format('Y-m-d H:i:s'), $rateKey]);
        $pdo->commit();

        if ($count > $maxAttempts) {
            v2ApiFail(
                'rate_limit_exceeded',
                'Terlalu banyak percobaan. Coba lagi dalam beberapa menit.',
                429,
            );
        }
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        v2ApiRateLimitFile($endpoint, $maxAttempts, $windowSeconds);
    }
}

function v2ApiSecurityLog(PDO $pdo, string $eventType, ?int $userId = null, ?array $details = null): void
{
    $payload = [
        'ip' => v2ApiClientIp(),
        'uri' => (string) ($_SERVER['REQUEST_URI'] ?? ''),
        'method' => (string) ($_SERVER['REQUEST_METHOD'] ?? ''),
    ];
    if ($details !== null) {
        $payload = array_merge($payload, $details);
    }

    if (function_exists('v2ApiTableExists') && v2ApiTableExists($pdo, 'kakiempa_security_log')) {
        try {
            $pdo->prepare(
                'INSERT INTO kakiempa_security_log (event_type, ip_address, user_id, details)
                 VALUES (?, ?, ?, ?)',
            )->execute([
                $eventType,
                v2ApiClientIp(),
                $userId,
                json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
            ]);
            return;
        } catch (Throwable $e) {
            error_log('security_log db: ' . $e->getMessage());
        }
    }

    error_log(sprintf(
        '[kakiempat_security] %s user=%s %s',
        $eventType,
        $userId === null ? '-' : (string) $userId,
        json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
    ));
}
