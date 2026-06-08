<?php
declare(strict_types=1);

require_once __DIR__ . '/../v2_api_common.php';

/** @return array<string, mixed>|null */
function kakiempat_platform_v2_authenticate_request(PDO $pdo): ?array
{
    $rawKey = trim((string) ($_SERVER['HTTP_X_PLATFORM_KEY'] ?? ''));
    if ($rawKey === '') {
        return null;
    }
    $hash = hash('sha256', $rawKey);
    $stmt = $pdo->prepare(
        'SELECT id, code, name, allowed_scopes, webhook_url, webhook_secret
         FROM kakiempa_v2_partner_apps
         WHERE api_key_hash = ? AND is_active = 1
         LIMIT 1',
    );
    $stmt->execute([$hash]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);

    return is_array($row) ? $row : null;
}

/** @param array<string, mixed> $app */
function kakiempat_platform_v2_has_scope(array $app, string $scope): bool
{
    $raw = $app['allowed_scopes'] ?? null;
    if (!is_string($raw) || $raw === '') {
        return false;
    }
    $decoded = json_decode($raw, true);
    if (!is_array($decoded)) {
        return false;
    }

    return in_array($scope, $decoded, true);
}

/** @param array<string, mixed> $payload */
function kakiempat_platform_v2_emit_event(PDO $pdo, string $eventType, array $payload): void
{
    if (!v2ApiTableExists($pdo, 'kakiempa_v2_platform_events')) {
        return;
    }

    $appsStmt = $pdo->query(
        'SELECT id, webhook_url, webhook_secret
         FROM kakiempa_v2_partner_apps
         WHERE is_active = 1 AND webhook_url IS NOT NULL AND webhook_url != \'\'',
    );
    if (!$appsStmt) {
        return;
    }

    $payloadJson = json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    if ($payloadJson === false) {
        return;
    }

    while ($app = $appsStmt->fetch(PDO::FETCH_ASSOC)) {
        if (!is_array($app)) {
            continue;
        }
        $appId = (int) ($app['id'] ?? 0);
        if ($appId < 1) {
            continue;
        }

        $pdo->prepare(
            'INSERT INTO kakiempa_v2_platform_events
                (partner_app_id, event_type, payload_json, delivery_status, attempts)
             VALUES (?, ?, ?, \'pending\', 0)',
        )->execute([$appId, $eventType, $payloadJson]);

        $eventId = (int) $pdo->lastInsertId();
        kakiempat_platform_v2_deliver_event($pdo, $eventId, $app, $eventType, $payload);
    }
}

/**
 * @param array<string, mixed> $app
 * @param array<string, mixed> $payload
 */
function kakiempat_platform_v2_deliver_event(
    PDO $pdo,
    int $eventId,
    array $app,
    string $eventType,
    array $payload,
): void {
    $url = trim((string) ($app['webhook_url'] ?? ''));
    if ($url === '') {
        return;
    }

    $secret = (string) ($app['webhook_secret'] ?? '');
    $body = json_encode([
        'event' => $eventType,
        'payload' => $payload,
        'timestamp' => gmdate('c'),
    ], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    if ($body === false) {
        return;
    }

    $signature = hash_hmac('sha256', $body, $secret);

    $ch = curl_init($url);
    if ($ch === false) {
        kakiempat_platform_v2_mark_delivery($pdo, $eventId, false, 'curl_init failed');
        return;
    }

    curl_setopt_array($ch, [
        CURLOPT_POST => true,
        CURLOPT_POSTFIELDS => $body,
        CURLOPT_HTTPHEADER => [
            'Content-Type: application/json',
            'X-Platform-Signature: ' . $signature,
            'X-Platform-Event: ' . $eventType,
        ],
        CURLOPT_RETURNTRANSFER => true,
        CURLOPT_TIMEOUT => 8,
        CURLOPT_CONNECTTIMEOUT => 4,
    ]);

    $response = curl_exec($ch);
    $httpCode = (int) curl_getinfo($ch, CURLINFO_HTTP_CODE);
    $curlError = curl_error($ch);
    curl_close($ch);

    $ok = $httpCode >= 200 && $httpCode < 300;
    $error = $ok ? null : ($curlError !== '' ? $curlError : 'HTTP ' . $httpCode . ': ' . substr((string) $response, 0, 200));
    kakiempat_platform_v2_mark_delivery($pdo, $eventId, $ok, $error);
}

function kakiempat_platform_v2_mark_delivery(
    PDO $pdo,
    int $eventId,
    bool $ok,
    ?string $error,
): void {
    $pdo->prepare(
        'UPDATE kakiempa_v2_platform_events
         SET delivery_status = ?, attempts = attempts + 1,
             last_error = ?, delivered_at = IF(?, CURRENT_TIMESTAMP(6), NULL)
         WHERE id = ?',
    )->execute([
        $ok ? 'delivered' : 'failed',
        $error,
        $ok ? 1 : 0,
        $eventId,
    ]);
}

/** @param array<string, mixed> $body */
function kakiempat_platform_v2_admin_create_app(array $body): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['admin', 'founder']);
    $pdo = v2ApiPdo();

    if (!v2ApiTableExists($pdo, 'kakiempa_v2_partner_apps')) {
        v2ApiFail('schema_missing', 'Platform API belum dimigrasi (026).', 503);
    }

    $code = strtolower(trim((string) ($body['code'] ?? '')));
    $name = trim((string) ($body['name'] ?? ''));
    $webhookUrl = trim((string) ($body['webhook_url'] ?? ''));
    $scopes = $body['allowed_scopes'] ?? ['booking.read', 'webhook.receive'];

    if ($code === '' || !preg_match('/^[a-z0-9_]{3,32}$/', $code)) {
        v2ApiFail('invalid_code', 'Kode app partner tidak valid.', 400);
    }
    if ($name === '') {
        v2ApiFail('invalid_name', 'Nama app wajib diisi.', 400);
    }
    if (!is_array($scopes)) {
        $scopes = ['booking.read', 'webhook.receive'];
    }

    $rawKey = bin2hex(random_bytes(24));
    $apiKeyHash = hash('sha256', $rawKey);
    $webhookSecret = bin2hex(random_bytes(16));
    $scopesJson = json_encode(array_values($scopes), JSON_UNESCAPED_UNICODE);

    $pdo->prepare(
        'INSERT INTO kakiempa_v2_partner_apps
            (code, name, api_key_hash, webhook_secret, webhook_url, allowed_scopes, is_active)
         VALUES (?, ?, ?, ?, ?, ?, 0)',
    )->execute([
        $code,
        $name,
        $apiKeyHash,
        $webhookSecret,
        $webhookUrl !== '' ? $webhookUrl : null,
        $scopesJson,
    ]);

    v2ApiRespondData([
        'app_id' => (string) $pdo->lastInsertId(),
        'code' => $code,
        'name' => $name,
        'api_key' => $rawKey,
        'webhook_secret' => $webhookSecret,
        'is_active' => false,
        'message' => 'Partner app dibuat. Simpan api_key — tidak ditampilkan lagi.',
    ]);
}

function kakiempat_platform_v2_admin_list_apps(): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['admin', 'founder']);
    $pdo = v2ApiPdo();

    if (!v2ApiTableExists($pdo, 'kakiempa_v2_partner_apps')) {
        v2ApiRespondData(['apps' => [], 'total' => 0]);
        return;
    }

    $stmt = $pdo->query(
        'SELECT id, code, name, webhook_url, allowed_scopes, is_active, created_at
         FROM kakiempa_v2_partner_apps
         ORDER BY created_at DESC',
    );
    $apps = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        if (!is_array($row)) {
            continue;
        }
        $apps[] = [
            'id' => (string) ($row['id'] ?? ''),
            'code' => (string) ($row['code'] ?? ''),
            'name' => (string) ($row['name'] ?? ''),
            'webhook_url' => (string) ($row['webhook_url'] ?? ''),
            'allowed_scopes' => json_decode((string) ($row['allowed_scopes'] ?? '[]'), true) ?: [],
            'is_active' => (int) ($row['is_active'] ?? 0) === 1,
            'created_at' => (string) ($row['created_at'] ?? ''),
        ];
    }

    v2ApiRespondData(['apps' => $apps, 'total' => count($apps)]);
}

/** @param array<string, mixed> $body */
function kakiempat_platform_v2_admin_approve_app(array $body): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['admin', 'founder']);
    $pdo = v2ApiPdo();

    $appId = (int) ($body['app_id'] ?? 0);
    if ($appId < 1) {
        v2ApiFail('invalid_app_id', 'app_id wajib.', 400);
    }

    $pdo->prepare(
        'UPDATE kakiempa_v2_partner_apps
         SET is_active = 1, approved_by = ?
         WHERE id = ?',
    )->execute([$auth['user_id'], $appId]);

    v2ApiRespondData([
        'app_id' => (string) $appId,
        'is_active' => true,
        'message' => 'Partner app diaktifkan.',
    ]);
}

function kakiempat_platform_v2_partner_get_booking(): void
{
    $pdo = v2ApiPdo();
    $app = kakiempat_platform_v2_authenticate_request($pdo);
    if ($app === null) {
        v2ApiFail('unauthorized', 'Header X-Platform-Key tidak valid.', 401);
    }
    if (!kakiempat_platform_v2_has_scope($app, 'booking.read')) {
        v2ApiFail('forbidden', 'Scope booking.read diperlukan.', 403);
    }

    $bookingId = (int) ($_GET['booking_id'] ?? 0);
    if ($bookingId < 1) {
        v2ApiFail('invalid_booking_id', 'booking_id wajib.', 400);
    }

    require_once __DIR__ . '/kakiempat_booking_v2.php';
    $stmt = $pdo->prepare(
        'SELECT id, status, service_code, owner_user_id, sitter_user_id,
                payment_amount, created_at
         FROM kakiempa_v2_bookings WHERE id = ? LIMIT 1',
    );
    $stmt->execute([$bookingId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!is_array($row)) {
        v2ApiFail('booking_not_found', 'Booking tidak ditemukan.', 404);
    }

    v2ApiRespondData([
        'booking' => [
            'id' => (string) ($row['id'] ?? ''),
            'status' => (string) ($row['status'] ?? ''),
            'service_code' => (string) ($row['service_code'] ?? ''),
            'owner_user_id' => (string) ($row['owner_user_id'] ?? ''),
            'sitter_user_id' => (string) ($row['sitter_user_id'] ?? ''),
            'payment_amount' => (int) ($row['payment_amount'] ?? 0),
            'created_at' => (string) ($row['created_at'] ?? ''),
        ],
    ]);
}

function kakiempat_platform_v2_retry_pending_events(): void
{
    $pdo = v2ApiPdo();
    if (!v2ApiTableExists($pdo, 'kakiempa_v2_platform_events')) {
        v2ApiRespondData(['retried' => 0]);
        return;
    }

    $stmt = $pdo->query(
        "SELECT e.id, e.event_type, e.payload_json, e.attempts,
                a.webhook_url, a.webhook_secret
         FROM kakiempa_v2_platform_events e
         INNER JOIN kakiempa_v2_partner_apps a ON a.id = e.partner_app_id
         WHERE e.delivery_status = 'failed' AND e.attempts < 5
         ORDER BY e.created_at ASC
         LIMIT 20",
    );
    $retried = 0;
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        if (!is_array($row)) {
            continue;
        }
        $payload = json_decode((string) ($row['payload_json'] ?? '{}'), true);
        if (!is_array($payload)) {
            continue;
        }
        kakiempat_platform_v2_deliver_event(
            $pdo,
            (int) ($row['id'] ?? 0),
            $row,
            (string) ($row['event_type'] ?? ''),
            $payload,
        );
        $retried++;
    }

    v2ApiRespondData(['retried' => $retried]);
}
