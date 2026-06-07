<?php
declare(strict_types=1);

require_once dirname(__DIR__) . '/v2_api_common.php';
require_once __DIR__ . '/kakiempat_auth_v2.php';
require_once __DIR__ . '/kakiempat_event_notifications.php';
require_once __DIR__ . '/kakiempat_platform_fee_v2.php';

/** @return array<string, mixed> */
function kakiempat_payment_v2_config(): array
{
    static $cfg = null;
    if (is_array($cfg)) {
        return $cfg;
    }
    $file = dirname(__DIR__) . '/.payment_config.php';
    if (is_readable($file)) {
        $loaded = require $file;
        $cfg = is_array($loaded) ? $loaded : [];
    } else {
        $cfg = [];
    }
    return $cfg;
}

/** @return array{id:int,name:string,role:string,phone:string} */
function kakiempat_payment_v2_require_user(PDO $pdo): array
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

/** @param list<string> $roles */
function kakiempat_payment_v2_require_role(array $user, array $roles): void
{
    if (!in_array($user['role'], $roles, true)) {
        v2ApiFail('forbidden', 'Anda tidak memiliki akses untuk aksi ini.', 403);
    }
}

function kakiempat_payment_v2_is_admin(array $user): bool
{
    return in_array($user['role'], ['admin', 'founder'], true);
}

/** @return array<string, mixed> */
function kakiempat_payment_v2_get_booking(PDO $pdo, int $bookingId): array
{
    $stmt = $pdo->prepare(
        'SELECT b.id, b.status, b.payment_amount, b.owner_user_id, b.sitter_user_id,
                u.name AS owner_name
         FROM kakiempa_v2_bookings b
         LEFT JOIN kakiempa_v2_users u ON u.id = b.owner_user_id
         WHERE b.id = ? LIMIT 1',
    );
    $stmt->execute([$bookingId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!is_array($row)) {
        v2ApiFail('booking_not_found', 'Booking tidak ditemukan.', 404);
    }
    return $row;
}

function kakiempat_payment_v2_uploads_dir(): string
{
    $dir = dirname(__DIR__) . '/uploads/payment_proofs';
    if (!is_dir($dir)) {
        mkdir($dir, 0755, true);
    }
    return $dir;
}

function kakiempat_payment_v2_save_screenshot(?string $base64, ?string $mime): ?string
{
    if ($base64 === null || trim($base64) === '') {
        return null;
    }
    $raw = base64_decode(preg_replace('/\s+/', '', $base64) ?? '', true);
    if ($raw === false || strlen($raw) < 32) {
        v2ApiFail('invalid_screenshot', 'Screenshot tidak valid.', 400);
    }
    if (strlen($raw) > 8 * 1024 * 1024) {
        v2ApiFail('screenshot_too_large', 'Ukuran screenshot maksimal 8 MB.', 400);
    }
    $ext = 'jpg';
    if ($mime !== null) {
        $mime = strtolower(trim($mime));
        $ext = match ($mime) {
            'image/png' => 'png',
            'image/webp' => 'webp',
            'image/gif' => 'gif',
            default => 'jpg',
        };
    }
    $name = 'proof_' . bin2hex(random_bytes(16)) . '.' . $ext;
    $path = kakiempat_payment_v2_uploads_dir() . '/' . $name;
    if (file_put_contents($path, $raw) === false) {
        v2ApiFail('upload_failed', 'Gagal menyimpan screenshot.', 500);
    }
    return '/uploads/payment_proofs/' . $name;
}

function kakiempat_payment_v2_public_config(): void
{
    $cfg = kakiempat_payment_v2_config();
    v2ApiRespond([
        'ok' => true,
        'seabank_account_number' => (string) ($cfg['seabank_account_number'] ?? ''),
        'seabank_account_name' => (string) ($cfg['seabank_account_name'] ?? ''),
        'bank_label' => (string) ($cfg['bank_label'] ?? 'SeaBank Indonesia'),
    ]);
}

function kakiempat_payment_v2_submit_proof(PDO $pdo, array $user, array $body): void
{
    kakiempat_payment_v2_require_role($user, ['owner', 'founder']);

    $bookingId = (int) ($body['booking_id'] ?? 0);
    $referenceCode = trim((string) ($body['reference_code'] ?? ''));
    if ($bookingId < 1) {
        v2ApiFail('invalid_booking_id', 'booking_id wajib.', 400);
    }
    if ($referenceCode === '' || strlen($referenceCode) > 128) {
        v2ApiFail('invalid_reference_code', 'Reference code wajib (maks. 128 karakter).', 400);
    }

    $booking = kakiempat_payment_v2_get_booking($pdo, $bookingId);
    $ownerId = (int) ($booking['owner_user_id'] ?? 0);
    if ($user['role'] === 'owner' && $ownerId !== $user['id']) {
        v2ApiFail('forbidden', 'Booking ini bukan milik Anda.', 403);
    }

    $status = (string) $booking['status'];
    $allowed = ['awaitingPayment', 'AWAITING_PAYMENT', 'PAYMENT_REJECTED'];
    if (!in_array($status, $allowed, true)) {
        v2ApiFail(
            'invalid_booking_status',
            'Booking tidak dalam status yang dapat dikonfirmasi pembayarannya.',
            409,
        );
    }

    $screenshotUrl = kakiempat_payment_v2_save_screenshot(
        isset($body['screenshot_base64']) ? (string) $body['screenshot_base64'] : null,
        isset($body['screenshot_mime']) ? (string) $body['screenshot_mime'] : null,
    );

    $pdo->beginTransaction();
    try {
        $pdo->prepare(
            "UPDATE kakiempa_v2_bookings SET status = 'PENDING_VERIFICATION' WHERE id = ?",
        )->execute([$bookingId]);

        $pdo->prepare(
            'INSERT INTO kakiempa_payment_proofs (booking_id, reference_code, screenshot_url, status)
             VALUES (?, ?, ?, ?)',
        )->execute([$bookingId, $referenceCode, $screenshotUrl, 'pending']);

        $proofId = (int) $pdo->lastInsertId();
        $pdo->commit();

        v2ApiRespond([
            'ok' => true,
            'proof_id' => (string) $proofId,
            'booking_id' => (string) $bookingId,
            'status' => 'PENDING_VERIFICATION',
            'display_label' => 'Menunggu Verifikasi',
        ]);
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        throw $e;
    }
}

/** @return list<array<string, mixed>> */
function kakiempat_payment_v2_list_pending(PDO $pdo): array
{
    $stmt = $pdo->query(
        "SELECT p.id AS proof_id, p.booking_id, p.reference_code, p.screenshot_url,
                p.created_at AS proof_created_at,
                b.payment_amount, b.status AS booking_status,
                u.name AS owner_name
         FROM kakiempa_payment_proofs p
         INNER JOIN kakiempa_v2_bookings b ON b.id = p.booking_id
         LEFT JOIN kakiempa_v2_users u ON u.id = b.owner_user_id
         WHERE p.status = 'pending' AND b.status = 'PENDING_VERIFICATION'
         ORDER BY p.created_at ASC",
    );
    $rows = $stmt ? $stmt->fetchAll(PDO::FETCH_ASSOC) : [];
    $items = [];
    foreach ($rows as $row) {
        if (!is_array($row)) {
            continue;
        }
        $items[] = [
            'proof_id' => (string) $row['proof_id'],
            'booking_id' => (string) $row['booking_id'],
            'owner_name' => (string) ($row['owner_name'] ?? '—'),
            'payment_amount' => (int) ($row['payment_amount'] ?? 0),
            'reference_code' => (string) $row['reference_code'],
            'screenshot_url' => $row['screenshot_url'],
            'proof_created_at' => $row['proof_created_at'],
        ];
    }
    return $items;
}

function kakiempat_payment_v2_admin_approve(PDO $pdo, array $body): void
{
    $bookingId = (int) ($body['booking_id'] ?? 0);
    if ($bookingId < 1) {
        v2ApiFail('invalid_booking_id', 'booking_id wajib.', 400);
    }

    $booking = kakiempat_payment_v2_get_booking($pdo, $bookingId);
    if ((string) $booking['status'] !== 'PENDING_VERIFICATION') {
        v2ApiFail('invalid_booking_status', 'Booking tidak menunggu verifikasi.', 409);
    }

    $pdo->beginTransaction();
    try {
        $pdo->prepare("UPDATE kakiempa_v2_bookings SET status = 'PAID' WHERE id = ?")
            ->execute([$bookingId]);
        $pdo->prepare(
            "UPDATE kakiempa_payment_proofs SET status = 'approved'
             WHERE booking_id = ? AND status = 'pending'",
        )->execute([$bookingId]);

        $platformFeeBreakdown = kakiempat_platform_fee_v2_apply_for_booking($pdo, $bookingId);

        $ownerId = (int) ($booking['owner_user_id'] ?? 0);
        $sitterId = (int) ($booking['sitter_user_id'] ?? 0);

        kakiempat_event_notifications_admin_approved($pdo, $ownerId, $sitterId, $bookingId);

        $pdo->commit();
        v2ApiRespond([
            'ok' => true,
            'booking_id' => (string) $bookingId,
            'status' => 'PAID',
            'platform_fee_breakdown' => $platformFeeBreakdown,
        ]);
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        throw $e;
    }
}

function kakiempat_payment_v2_admin_reject(PDO $pdo, array $body): void
{
    $bookingId = (int) ($body['booking_id'] ?? 0);
    $reason = trim((string) ($body['reason'] ?? ''));
    if ($bookingId < 1) {
        v2ApiFail('invalid_booking_id', 'booking_id wajib.', 400);
    }

    $booking = kakiempat_payment_v2_get_booking($pdo, $bookingId);
    if ((string) $booking['status'] !== 'PENDING_VERIFICATION') {
        v2ApiFail('invalid_booking_status', 'Booking tidak menunggu verifikasi.', 409);
    }

    $pdo->beginTransaction();
    try {
        $pdo->prepare("UPDATE kakiempa_v2_bookings SET status = 'PAYMENT_REJECTED' WHERE id = ?")
            ->execute([$bookingId]);
        $pdo->prepare(
            "UPDATE kakiempa_payment_proofs SET status = 'rejected'
             WHERE booking_id = ? AND status = 'pending'",
        )->execute([$bookingId]);

        $ownerId = (int) ($booking['owner_user_id'] ?? 0);
        if ($ownerId > 0) {
            $msg = $reason !== ''
                ? sprintf('Pembayaran booking #%d ditolak: %s', $bookingId, $reason)
                : sprintf('Pembayaran booking #%d ditolak. Unggah bukti baru.', $bookingId);
            $pdo->prepare(
                'INSERT INTO kakiempa_v2_notifications (user_id, title) VALUES (?, ?)',
            )->execute([$ownerId, $msg]);
        }

        $pdo->commit();
        v2ApiRespond([
            'ok' => true,
            'booking_id' => (string) $bookingId,
            'status' => 'PAYMENT_REJECTED',
        ]);
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        throw $e;
    }
}
