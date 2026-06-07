<?php
declare(strict_types=1);

require_once __DIR__ . '/kakiempat_auth_v2.php';

/**
 * Notifikasi in-app self-hosted: DB utama (polling) + file JSON fallback.
 */

function kakiempat_event_notifications_dir(): string
{
    static $dir = null;
    if ($dir !== null) {
        return $dir;
    }

    $configured = null;
    $configFile = dirname(__DIR__) . '/.notifications_path.php';
    if (is_readable($configFile)) {
        $cfg = require $configFile;
        if (is_array($cfg) && !empty($cfg['path'])) {
            $configured = (string) $cfg['path'];
        }
    }

    $dir = $configured !== null
        ? rtrim($configured, '/\\')
        : dirname(__DIR__) . '/uploads/notifications';

    if (!is_dir($dir)) {
        mkdir($dir, 0755, true);
    }

    return $dir;
}

function kakiempat_event_notifications_file_path(int $userId): string
{
    if ($userId < 1) {
        throw new InvalidArgumentException('user_id invalid');
    }
    return kakiempat_event_notifications_dir() . '/user_' . $userId . '.json';
}

function kakiempat_in_app_notifications_table_exists(PDO $pdo): bool
{
    static $exists = null;
    if ($exists !== null) {
        return $exists;
    }
    $stmt = $pdo->query("SHOW TABLES LIKE 'kakiempa_v2_in_app_notifications'");
    $exists = $stmt !== false && $stmt->fetchColumn() !== false;
    return $exists;
}

function kakiempat_in_app_notifications_insert(
    PDO $pdo,
    int $userId,
    string $title,
    string $message,
    ?int $bookingId = null,
    string $type = 'general',
): ?int {
    if (!kakiempat_in_app_notifications_table_exists($pdo)) {
        return null;
    }
    $stmt = $pdo->prepare(
        'INSERT INTO kakiempa_v2_in_app_notifications
            (user_id, title, message, booking_id, notification_type, is_read, admin_reviewed)
         VALUES (?, ?, ?, ?, ?, 0, 0)',
    );
    $stmt->execute([$userId, $title, $message, $bookingId, $type]);
    return (int) $pdo->lastInsertId();
}

/** @return array<string, mixed>|null */
function kakiempat_in_app_notifications_latest_unread(PDO $pdo, int $userId): ?array
{
    if (!kakiempat_in_app_notifications_table_exists($pdo)) {
        return null;
    }
    $stmt = $pdo->prepare(
        'SELECT id, user_id, title, message, booking_id, notification_type, is_read,
                UNIX_TIMESTAMP(created_at) AS timestamp_unix, created_at
         FROM kakiempa_v2_in_app_notifications
         WHERE user_id = ? AND is_read = 0
         ORDER BY created_at DESC
         LIMIT 1',
    );
    $stmt->execute([$userId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    return is_array($row) ? $row : null;
}

function kakiempat_in_app_notifications_mark_read(PDO $pdo, int $userId, ?int $notificationId = null): void
{
    if (!kakiempat_in_app_notifications_table_exists($pdo)) {
        return;
    }
    if ($notificationId !== null && $notificationId > 0) {
        $pdo->prepare(
            'UPDATE kakiempa_v2_in_app_notifications SET is_read = 1
             WHERE id = ? AND user_id = ?',
        )->execute([$notificationId, $userId]);
        return;
    }
    $latest = kakiempat_in_app_notifications_latest_unread($pdo, $userId);
    if ($latest !== null) {
        $pdo->prepare(
            'UPDATE kakiempa_v2_in_app_notifications SET is_read = 1 WHERE id = ? AND user_id = ?',
        )->execute([(int) $latest['id'], $userId]);
    }
}

/** @param array<string, mixed> $payload */
function kakiempat_event_notifications_write_file(int $userId, array $payload): bool
{
    $payload['user_id'] = $userId;
    $payload['timestamp'] = $payload['timestamp'] ?? time();
    $payload['unread'] = $payload['unread'] ?? true;

    $json = json_encode($payload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    if ($json === false) {
        return false;
    }

    return file_put_contents(
        kakiempat_event_notifications_file_path($userId),
        $json,
        LOCK_EX,
    ) !== false;
}

function kakiempat_event_notifications_push(
    PDO $pdo,
    int $userId,
    string $title,
    string $message,
    ?int $bookingId = null,
    string $type = 'general',
): void {
    if ($userId < 1) {
        return;
    }

    kakiempat_in_app_notifications_insert($pdo, $userId, $title, $message, $bookingId, $type);

    kakiempat_event_notifications_write_file($userId, [
        'type' => $type,
        'booking_id' => $bookingId,
        'title' => $title,
        'message' => $message,
    ]);
}

function kakiempat_event_notifications_payment_paid(
    PDO $pdo,
    int $ownerId,
    int $sitterId,
    int $bookingId,
    int $nominal = 0,
): void {
    if ($ownerId > 0) {
        kakiempat_event_notifications_push(
            $pdo,
            $ownerId,
            'Payment Confirmed',
            sprintf(
                'We have received your payment via Wise for Booking #%d. Your pet sitter is ready!',
                $bookingId,
            ),
            $bookingId,
            'payment_paid',
        );
    }
    if ($sitterId > 0) {
        kakiempat_event_notifications_push(
            $pdo,
            $sitterId,
            'Booking Paid',
            sprintf(
                'Booking #%d has been paid (Rp %s). You can start the assignment.',
                $bookingId,
                number_format($nominal, 0, ',', '.'),
            ),
            $bookingId,
            'payment_paid',
        );
    }
}

function kakiempat_event_notifications_offer_received(
    PDO $pdo,
    int $ownerId,
    int $requestId,
    int $offerId,
    int $sitterId,
): void {
    if ($ownerId < 1) {
        return;
    }
    kakiempat_event_notifications_push(
        $pdo,
        $ownerId,
        'Penawaran Baru',
        sprintf(
            'Pengasuh mengirim penawaran untuk permintaan #%d. Tinjau dan terima penawaran terbaik.',
            $requestId,
        ),
        null,
        'offer_received',
    );
}

function kakiempat_event_notifications_offer_accepted(
    PDO $pdo,
    int $ownerId,
    int $sitterId,
    int $bookingId,
): void {
    if ($sitterId > 0) {
        kakiempat_event_notifications_push(
            $pdo,
            $sitterId,
            'Penawaran Diterima',
            'Tawaran Anda diterima! Anda bisa mulai chat dengan pemilik.',
            $bookingId,
            'offer_accepted',
        );
    }
    if ($ownerId > 0) {
        kakiempat_event_notifications_push(
            $pdo,
            $ownerId,
            'Booking Terbentuk',
            'Booking terbentuk! Silakan lanjutkan pembayaran.',
            $bookingId,
            'booking_created',
        );
    }
}

function kakiempat_event_notifications_booking_completed(
    PDO $pdo,
    int $ownerId,
    int $sitterId,
    int $bookingId,
): void {
    if ($ownerId > 0) {
        kakiempat_event_notifications_push(
            $pdo,
            $ownerId,
            'Layanan Selesai',
            sprintf('Booking #%d telah diselesaikan oleh pengasuh.', $bookingId),
            $bookingId,
            'booking_completed',
        );
    }
    if ($sitterId > 0) {
        kakiempat_event_notifications_push(
            $pdo,
            $sitterId,
            'Layanan Selesai',
            sprintf('Booking #%d ditandai selesai. Pendapatan dicatat di wallet.', $bookingId),
            $bookingId,
            'booking_completed',
        );
    }
}

/** @param array<string, mixed> $booking */
function kakiempat_event_notifications_booking_cancelled(
    PDO $pdo,
    array $booking,
    int $bookingId,
    int $cancelledByUserId,
): void {
    $ownerId = (int) ($booking['owner_user_id'] ?? 0);
    $sitterId = (int) ($booking['sitter_user_id'] ?? 0);
    $message = sprintf('Booking #%d telah dibatalkan.', $bookingId);

    if ($ownerId > 0 && $ownerId !== $cancelledByUserId) {
        kakiempat_event_notifications_push(
            $pdo,
            $ownerId,
            'Booking Dibatalkan',
            $message,
            $bookingId,
            'booking_cancelled',
        );
    }
    if ($sitterId > 0 && $sitterId !== $cancelledByUserId) {
        kakiempat_event_notifications_push(
            $pdo,
            $sitterId,
            'Booking Dibatalkan',
            $message,
            $bookingId,
            'booking_cancelled',
        );
    }
}

/** @param array<string, mixed> $booking */
function kakiempat_event_notifications_chat_new(
    PDO $pdo,
    array $booking,
    int $senderUserId,
    int $bookingId,
    string $text,
): void {
    $ownerId = (int) ($booking['owner_user_id'] ?? 0);
    $sitterId = (int) ($booking['sitter_user_id'] ?? 0);
    $recipientId = $senderUserId === $ownerId ? $sitterId : $ownerId;
    if ($recipientId < 1 || $recipientId === $senderUserId) {
        return;
    }

    $preview = mb_strlen($text) > 80 ? mb_substr($text, 0, 77) . '...' : $text;
    kakiempat_event_notifications_push(
        $pdo,
        $recipientId,
        'Pesan Baru',
        sprintf('Pesan baru di booking #%d: %s', $bookingId, $preview),
        $bookingId,
        'chat_new',
    );
}

function kakiempat_event_notifications_admin_approved(
    PDO $pdo,
    int $ownerId,
    int $sitterId,
    int $bookingId,
): void {
    if ($ownerId > 0) {
        kakiempat_event_notifications_push(
            $pdo,
            $ownerId,
            'Payment Approved',
            sprintf(
                'Payment approved! Your booking #%d is now active.',
                $bookingId,
            ),
            $bookingId,
            'payment_approved',
        );
    }
    if ($sitterId > 0) {
        kakiempat_event_notifications_push(
            $pdo,
            $sitterId,
            'Payment Approved',
            sprintf(
                'Booking #%d payment was approved by admin.',
                $bookingId,
            ),
            $bookingId,
            'payment_approved',
        );
    }
}

/** @return array{id:int,name:string,role:string,phone:string} */
function kakiempat_event_notifications_require_user(PDO $pdo): array
{
    $token = kakiempat_v2_extract_bearer_token();
    if ($token === '' || !preg_match('/^native_[a-f0-9]{64}$/', $token)) {
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
        v2ApiFail('invalid_token', 'Sesi tidak valid.', 401);
    }
    $expires = new DateTimeImmutable((string) $row['expires_at'], new DateTimeZone('UTC'));
    if ($expires < new DateTimeImmutable('now', new DateTimeZone('UTC'))) {
        v2ApiFail('token_expired', 'Sesi kedaluwarsa.', 401);
    }
    return [
        'id' => (int) $row['id'],
        'name' => (string) $row['name'],
        'role' => (string) $row['role'],
        'phone' => (string) ($row['whatsapp'] ?? ''),
    ];
}

/** @return array<string, mixed>|null */
function kakiempat_event_notifications_read_file(int $userId): ?array
{
    $path = kakiempat_event_notifications_file_path($userId);
    if (!is_readable($path)) {
        return null;
    }
    $raw = file_get_contents($path);
    if ($raw === false || trim($raw) === '') {
        return null;
    }
    $decoded = json_decode($raw, true);
    return is_array($decoded) ? $decoded : null;
}

function kakiempat_event_notifications_mark_read_file(int $userId): void
{
    $data = kakiempat_event_notifications_read_file($userId);
    if ($data === null) {
        return;
    }
    $data['unread'] = false;
    $json = json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    if ($json !== false) {
        file_put_contents(kakiempat_event_notifications_file_path($userId), $json, LOCK_EX);
    }
}

function kakiempat_event_notifications_api_get(PDO $pdo): void
{
    $user = kakiempat_event_notifications_require_user($pdo);

    $requestedId = filter_input(INPUT_GET, 'user_id', FILTER_VALIDATE_INT);
    if ($requestedId !== false && $requestedId !== null && (int) $requestedId !== $user['id']) {
        v2ApiFail('forbidden', 'user_id tidak sesuai sesi.', 403);
    }

    $markRead = filter_input(INPUT_GET, 'mark_read', FILTER_VALIDATE_INT);
    $notifId = filter_input(INPUT_GET, 'notification_id', FILTER_VALIDATE_INT);

    $row = kakiempat_in_app_notifications_latest_unread($pdo, $user['id']);
    if ($row !== null) {
        $payload = [
            'ok' => true,
            'notification_id' => (string) $row['id'],
            'user_id' => (int) $row['user_id'],
            'title' => (string) $row['title'],
            'message' => (string) $row['message'],
            'booking_id' => $row['booking_id'] !== null ? (string) $row['booking_id'] : null,
            'type' => (string) $row['notification_type'],
            'timestamp' => (int) ($row['timestamp_unix'] ?? time()),
            'unread' => (int) $row['is_read'] === 0,
        ];
        if ($markRead === 1) {
            $idToMark = ($notifId !== false && $notifId !== null && (int) $notifId > 0)
                ? (int) $notifId
                : (int) $row['id'];
            kakiempat_in_app_notifications_mark_read($pdo, $user['id'], $idToMark);
            $payload['unread'] = false;
        }
        v2ApiRespond($payload);
        return;
    }

    $fileData = kakiempat_event_notifications_read_file($user['id']);
    if ($fileData === null || ($fileData['unread'] ?? false) !== true) {
        v2ApiRespond([
            'ok' => true,
            'message' => 'No new notifications',
            'unread' => false,
        ]);
        return;
    }

    if ($markRead === 1) {
        kakiempat_event_notifications_mark_read_file($user['id']);
        $fileData['unread'] = false;
    }

    v2ApiRespond(array_merge(['ok' => true], $fileData));
}

/**
 * Ambil semua notifikasi belum dibaca, lalu tandai is_read=1 (satu transaksi).
 *
 * @return list<array<string, mixed>>
 */
function kakiempat_in_app_notifications_fetch_unread_and_mark_read(PDO $pdo, int $userId): array
{
    if (!kakiempat_in_app_notifications_table_exists($pdo)) {
        return [];
    }

    $pdo->beginTransaction();
    try {
        $stmt = $pdo->prepare(
            'SELECT id, title, message, booking_id, notification_type, created_at
             FROM kakiempa_v2_in_app_notifications
             WHERE user_id = ? AND is_read = 0
             ORDER BY created_at ASC',
        );
        $stmt->execute([$userId]);
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC) ?: [];

        if ($rows !== []) {
            $pdo->prepare(
                'UPDATE kakiempa_v2_in_app_notifications SET is_read = 1
                 WHERE user_id = ? AND is_read = 0',
            )->execute([$userId]);
        }

        $pdo->commit();
        return $rows;
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        throw $e;
    }
}

/** @param list<array<string, mixed>> $rows */
function kakiempat_event_notifications_format_poll_rows(array $rows): array
{
    $data = [];
    foreach ($rows as $row) {
        $data[] = [
            'id' => (string) $row['id'],
            'title' => (string) $row['title'],
            'message' => (string) $row['message'],
            'booking_id' => $row['booking_id'] !== null ? (string) $row['booking_id'] : null,
            'type' => (string) ($row['notification_type'] ?? 'general'),
            'created_at' => (string) $row['created_at'],
        ];
    }
    return $data;
}

function kakiempat_event_notifications_api_poll_unread(PDO $pdo): void
{
    $user = kakiempat_event_notifications_require_user($pdo);

    $requestedId = filter_input(INPUT_GET, 'user_id', FILTER_VALIDATE_INT);
    if ($requestedId !== false && $requestedId !== null && (int) $requestedId !== $user['id']) {
        v2ApiFail('forbidden', 'user_id tidak sesuai sesi.', 403);
    }

    try {
        $rows = kakiempat_in_app_notifications_fetch_unread_and_mark_read($pdo, $user['id']);
        $data = kakiempat_event_notifications_format_poll_rows($rows);

        if ($data === []) {
            $fileData = kakiempat_event_notifications_read_file($user['id']);
            if ($fileData !== null && ($fileData['unread'] ?? false) === true) {
                kakiempat_event_notifications_mark_read_file($user['id']);
                $data[] = [
                    'id' => 'file',
                    'title' => (string) ($fileData['title'] ?? 'Notification'),
                    'message' => (string) ($fileData['message'] ?? ''),
                    'booking_id' => isset($fileData['booking_id'])
                        ? (string) $fileData['booking_id']
                        : null,
                    'type' => (string) ($fileData['type'] ?? 'general'),
                    'created_at' => gmdate('c'),
                ];
            }
        }

        v2ApiRespond([
            'ok' => true,
            'count' => count($data),
            'data' => $data,
        ]);
    } catch (Throwable) {
        v2ApiFail('poll_failed', 'Gagal membaca database notifikasi.', 500);
    }
}
