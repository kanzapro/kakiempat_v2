<?php
declare(strict_types=1);

require_once dirname(__DIR__) . '/v2_api_common.php';
require_once __DIR__ . '/kakiempat_event_notifications.php';
require_once __DIR__ . '/kakiempat_platform_fee_v2.php';

/** @return array<string, mixed> */
function kakiempat_payment_read_json_body(): array
{
    $raw = file_get_contents('php://input');
    if ($raw === false || trim($raw) === '') {
        return [];
    }
    $decoded = json_decode($raw, true);
    return is_array($decoded) ? $decoded : [];
}

function kakiempat_payment_webhook_secret(): ?string
{
    static $cached = null;
    if ($cached !== null) {
        return $cached !== '' ? $cached : null;
    }
    $file = dirname(__DIR__) . '/.payment_webhook_secret';
    if (!is_readable($file)) {
        $cached = '';
        return null;
    }
    $secret = trim((string) file_get_contents($file));
    $cached = $secret;
    return $secret !== '' ? $secret : null;
}

/** Header X-Payment-Webhook-Secret — toleran variasi huruf besar/kecil (Apache/Nginx/FCGI). */
function kakiempat_payment_webhook_incoming_secret(): ?string
{
    if (function_exists('getallheaders')) {
        /** @var array<string, string>|false $headers */
        $headers = getallheaders();
        if (is_array($headers)) {
            foreach ($headers as $name => $value) {
                if (strtolower((string) $name) === 'x-payment-webhook-secret') {
                    $trimmed = trim((string) $value);
                    return $trimmed !== '' ? $trimmed : null;
                }
            }
        }
    }
    $fromServer = trim((string) ($_SERVER['HTTP_X_PAYMENT_WEBHOOK_SECRET'] ?? ''));
    return $fromServer !== '' ? $fromServer : null;
}

function kakiempat_payment_webhook_apply_cors(): void
{
    header('Access-Control-Allow-Origin: *');
    header('Access-Control-Allow-Methods: POST, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, X-Payment-Webhook-Secret');
    header('Access-Control-Max-Age: 86400');
    if (strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? '')) === 'OPTIONS') {
        http_response_code(204);
        exit;
    }
}

/** @param array<string, mixed> $extra */
function kakiempat_payment_webhook_deny(int $status, string $error, array $extra = []): void
{
    http_response_code($status);
    header('Content-Type: application/json; charset=utf-8');
    echo json_encode(array_merge([
        'ok' => false,
        'matched' => false,
        'booking_id' => null,
        'error' => $error,
    ], $extra), JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

/**
 * Wajib: token di header harus cocok dengan .payment_webhook_secret (hash_equals).
 * Mencegah timing attack & request palsu tanpa secret Android Forwarder.
 */
function kakiempat_payment_assert_webhook_auth(): void
{
    $expected = kakiempat_payment_webhook_secret();
    if ($expected === null) {
        kakiempat_payment_webhook_deny(
            503,
            'Webhook secret not configured on server',
        );
    }

    $incoming = kakiempat_payment_webhook_incoming_secret();
    if ($incoming === null || !hash_equals($expected, $incoming)) {
        try {
            v2ApiSecurityLog(v2ApiPdo(), 'webhook_auth_failed');
        } catch (Throwable) {
            // ignore
        }
        kakiempat_payment_webhook_deny(
            401,
            'Invalid or missing secure webhook token',
        );
    }
}

function kakiempat_payment_parse_nominal(mixed $value): ?int
{
    if (is_int($value)) {
        return $value > 0 ? $value : null;
    }
    if (is_float($value)) {
        $n = (int) round($value);
        return $n > 0 ? $n : null;
    }
    if (!is_string($value)) {
        return null;
    }
    $digits = preg_replace('/[^\d]/', '', $value) ?? '';
    if ($digits === '') {
        return null;
    }
    $n = (int) $digits;
    return $n > 0 ? $n : null;
}

function kakiempat_payment_parse_timestamp(mixed $value): string
{
    if (is_numeric($value)) {
        $ts = (int) $value;
        if ($ts > 1_000_000_000_000) {
            $ts = (int) floor($ts / 1000);
        }
        return gmdate('Y-m-d H:i:s.u', $ts);
    }
    if (is_string($value) && trim($value) !== '') {
        try {
            $dt = new DateTimeImmutable($value);
            return $dt->format('Y-m-d H:i:s.u');
        } catch (Throwable) {
        }
    }
    return gmdate('Y-m-d H:i:s.u');
}

function kakiempat_payment_insert_inbound_log(
    PDO $pdo,
    int $nominal,
    ?string $bank,
    ?string $nama,
    string $receivedAt,
    ?int $matchedBookingId,
    array $rawPayload,
    ?string $rawTimestamp = null,
): int {
    $stmt = $pdo->prepare(
        'INSERT INTO kakiempa_v2_payment_inbound_log
            (nominal, bank_pengirim, nama_pengirim, received_at, raw_timestamp, matched_booking_id, raw_payload)
         VALUES (?, ?, ?, ?, ?, ?, ?)',
    );
    $stmt->execute([
        $nominal,
        $bank,
        $nama,
        $receivedAt,
        $rawTimestamp,
        $matchedBookingId,
        json_encode($rawPayload, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES),
    ]);
    return (int) $pdo->lastInsertId();
}

/**
 * Normalisasi asal dana ke SEABANK_WISE | SEABANK_REVOLUT | SEABANK_TRANSFER.
 *
 * @param array<string, mixed> $body
 */
function kakiempat_payment_detect_sender_bank(array $body): string
{
    $explicit = trim((string) ($body['detected_bank'] ?? $body['sender_bank'] ?? ''));
    if ($explicit !== '') {
        $upper = strtoupper($explicit);
        if (str_contains($upper, 'REVOLUT')) {
            return 'SEABANK_REVOLUT';
        }
        if (str_contains($upper, 'WISE')) {
            return 'SEABANK_WISE';
        }
        if (str_contains($upper, 'TRANSFER')) {
            return 'SEABANK_TRANSFER';
        }
    }

    $bankHint = trim((string) ($body['bank_pengirim'] ?? $body['bank'] ?? ''));
    if ($bankHint !== '') {
        $upperBank = strtoupper($bankHint);
        if (str_contains($upperBank, 'REVOLUT')) {
            return 'SEABANK_REVOLUT';
        }
        if (str_contains($upperBank, 'WISE')) {
            return 'SEABANK_WISE';
        }
    }

    $text = trim((string) (
        $body['raw_notification']
        ?? $body['text']
        ?? $body['notification_text']
        ?? ''
    ));
    if ($text !== '') {
        if (stripos($text, 'REVOLUT') !== false) {
            return 'SEABANK_REVOLUT';
        }
        if (stripos($text, 'WISE') !== false) {
            return 'SEABANK_WISE';
        }
    }

    return 'SEABANK_TRANSFER';
}

function kakiempat_payment_insert_transaction_log(
    PDO $pdo,
    ?int $bookingId,
    int $nominal,
    string $senderBank,
    string $nama,
    ?string $rawTimestamp,
    ?string $rawNotification = null,
): void {
    $amount = number_format($nominal, 2, '.', '');
    $namaVal = $nama !== '' ? $nama : 'Tidak diketahui';
    $stmt = $pdo->prepare(
        'INSERT INTO kakiempa_v2_transaction_logs
            (booking_id, amount_received, sender_bank, sender_name, raw_notification, raw_timestamp)
         VALUES (?, ?, ?, ?, ?, ?)',
    );
    $stmt->execute([
        $bookingId,
        $amount,
        $senderBank,
        $namaVal,
        $rawNotification,
        $rawTimestamp,
    ]);
}

function kakiempat_payment_notify_users(PDO $pdo, int $bookingId, int $ownerId, int $sitterId, int $nominal): void
{
    kakiempat_event_notifications_payment_paid($pdo, $ownerId, $sitterId, $bookingId, $nominal);
}

/** Status booking yang webhook boleh cocokkan & langsung tandai PAID. */
function kakiempat_payment_webhook_matchable_statuses(): array
{
    return ['awaitingPayment', 'AWAITING_PAYMENT', 'PENDING_VERIFICATION'];
}

function kakiempat_payment_webhook_status_in_sql(): string
{
    $statuses = kakiempat_payment_webhook_matchable_statuses();

    return implode(',', array_fill(0, count($statuses), '?'));
}

/**
 * Tandai booking PAID atomik: update status, platform fee, bukti pending, log, notifikasi.
 *
 * @param array<string, mixed> $row
 * @return array<string, mixed> platform_fee_breakdown
 */
function kakiempat_payment_confirm_booking_paid(
    PDO $pdo,
    int $bookingId,
    array $row,
    int $nominal,
    string $receivedAt,
    ?string $namaVal,
    string $bankVal,
    string $senderBank,
    ?string $rawTimestamp,
    ?string $rawNotification,
    array $body,
): array {
    $ownerId = (int) ($row['owner_user_id'] ?? 0);
    $sitterId = (int) ($row['sitter_user_id'] ?? 0);
    $priorStatus = (string) ($row['status'] ?? '');

    $totalPrice = kakiempat_platform_fee_v2_resolve_total_price(
        (int) ($row['total_price'] ?? 0),
        (int) ($row['payment_amount'] ?? 0),
    );
    $platformFeeBreakdown = kakiempat_platform_fee_v2_payment_breakdown($totalPrice);
    $amountReceived = (int) ($platformFeeBreakdown['owner_pays'] ?? $nominal);

    $statusPlaceholders = kakiempat_payment_webhook_status_in_sql();
    $update = $pdo->prepare(
        "UPDATE kakiempa_v2_bookings
         SET status = 'PAID',
             payment_verification = 'matched',
             payment_matched_at = ?,
             payment_sender_name = ?,
             payment_sender_bank = ?,
             total_price = CASE WHEN total_price > 0 THEN total_price ELSE ? END,
             updated_at = CURRENT_TIMESTAMP(6)
         WHERE id = ? AND status IN ($statusPlaceholders)",
    );
    $update->execute(array_merge(
        [$receivedAt, $namaVal, $bankVal, $totalPrice, $bookingId],
        kakiempat_payment_webhook_matchable_statuses(),
    ));
    if ($update->rowCount() < 1) {
        throw new RuntimeException('Booking status changed before payment confirmation');
    }

    if ($priorStatus === 'PENDING_VERIFICATION') {
        $pdo->prepare(
            "UPDATE kakiempa_payment_proofs SET status = 'approved'
             WHERE booking_id = ? AND status = 'pending'",
        )->execute([$bookingId]);
    }

    kakiempat_platform_fee_v2_apply_for_booking($pdo, $bookingId);

    kakiempat_payment_insert_inbound_log(
        $pdo,
        $nominal,
        $bankVal,
        $namaVal,
        $receivedAt,
        $bookingId,
        $body,
        $rawTimestamp,
    );
    kakiempat_payment_insert_transaction_log(
        $pdo,
        $bookingId,
        $amountReceived,
        $senderBank,
        $namaVal ?? 'Tidak diketahui',
        $rawTimestamp,
        $rawNotification,
    );

    if ($ownerId > 0 && $sitterId > 0) {
        kakiempat_payment_notify_users($pdo, $bookingId, $ownerId, $sitterId, $amountReceived);
    }

    return $platformFeeBreakdown;
}

/**
 * Cocokkan nominal booking awaitingPayment, tandai paid, catat transaction_logs.
 *
 * @param array<string, mixed> $body
 * @return array{matched: bool, booking_id: ?int, mismatch_booking_id: ?int, sender_bank: string}
 */
function matchAndConfirmPayment(PDO $pdo, array $body): array
{
    return kakiempat_payment_process_webhook($pdo, $body);
}

/**
 * @param array<string, mixed> $body
 * @return array{matched: bool, booking_id: ?int, mismatch_booking_id: ?int, sender_bank: string}
 */
function kakiempat_payment_process_webhook(PDO $pdo, array $body): array
{
    $nominal = kakiempat_payment_parse_nominal($body['nominal'] ?? $body['amount'] ?? null);
    if ($nominal === null) {
        kakiempat_payment_webhook_deny(400, 'Nominal pembayaran tidak valid.');
    }

    $senderBank = kakiempat_payment_detect_sender_bank($body);
    $bank = trim((string) ($body['bank_pengirim'] ?? $body['bank'] ?? ''));
    $nama = trim((string) ($body['nama_pengirim'] ?? $body['sender_name'] ?? ''));
    $receivedAt = kakiempat_payment_parse_timestamp($body['timestamp'] ?? $body['received_at'] ?? null);

    $bankVal = $bank !== '' ? $bank : $senderBank;
    $namaVal = $nama !== '' ? $nama : null;
    $rawTimestamp = isset($body['timestamp']) ? trim((string) $body['timestamp']) : null;
    if ($rawTimestamp === '') {
        $rawTimestamp = null;
    }
    $rawNotification = trim((string) (
        $body['raw_notification']
        ?? $body['text']
        ?? $body['notification_text']
        ?? ''
    ));
    if ($rawNotification === '') {
        $rawNotification = null;
    }

    $bookingIdHint = null;
    $hintRaw = trim((string) ($body['booking_id'] ?? ''));
    if ($hintRaw !== '' && ctype_digit($hintRaw)) {
        $hintId = (int) $hintRaw;
        if ($hintId > 0) {
            $bookingIdHint = $hintId;
        }
    }

    // Idempotensi: webhook ulang untuk booking yang sudah PAID (nominal sama).
    $idempotentStmt = $pdo->prepare(
        "SELECT id FROM kakiempa_v2_bookings
         WHERE payment_amount = ?
           AND UPPER(status) = 'PAID'
           AND payment_verification = 'matched'
         ORDER BY payment_matched_at DESC
         LIMIT 1",
    );
    $idempotentStmt->execute([$nominal]);
    $alreadyPaidId = $idempotentStmt->fetchColumn();
    if ($alreadyPaidId !== false) {
        return [
            'matched' => true,
            'booking_id' => (int) $alreadyPaidId,
            'mismatch_booking_id' => null,
            'sender_bank' => $senderBank,
            'status' => 'PAID',
            'idempotent' => true,
        ];
    }

    $statusPlaceholders = kakiempat_payment_webhook_status_in_sql();
    $matchSql = "SELECT id, owner_user_id, sitter_user_id, total_price, payment_amount, status
         FROM kakiempa_v2_bookings
         WHERE status IN ($statusPlaceholders) AND payment_amount = ?";
    $matchParams = array_merge(kakiempat_payment_webhook_matchable_statuses(), [$nominal]);
    if ($bookingIdHint !== null) {
        $matchSql .= ' AND id = ?';
        $matchParams[] = $bookingIdHint;
    }
    $matchSql .= ' ORDER BY created_at ASC LIMIT 1 FOR UPDATE';
    $matchStmt = $pdo->prepare($matchSql);

    $pdo->beginTransaction();
    try {
        $matchStmt->execute($matchParams);
        $row = $matchStmt->fetch(PDO::FETCH_ASSOC);

        if (is_array($row)) {
            $bookingId = (int) $row['id'];
            $platformFeeBreakdown = kakiempat_payment_confirm_booking_paid(
                $pdo,
                $bookingId,
                $row,
                $nominal,
                $receivedAt,
                $namaVal,
                $bankVal,
                $senderBank,
                $rawTimestamp,
                $rawNotification,
                $body,
            );

            $pdo->commit();

            return [
                'matched' => true,
                'booking_id' => $bookingId,
                'mismatch_booking_id' => null,
                'sender_bank' => $senderBank,
                'status' => 'PAID',
                'platform_fee_breakdown' => $platformFeeBreakdown,
            ];
        }

        $mismatchBookingId = null;
        $awaitingSql = 'SELECT id, payment_amount FROM kakiempa_v2_bookings
            WHERE status IN (' . $statusPlaceholders . ') ORDER BY created_at ASC';
        $awaitingStmt = $pdo->prepare($awaitingSql);
        $awaitingStmt->execute(kakiempat_payment_webhook_matchable_statuses());
        $awaitingRows = $awaitingStmt->fetchAll(PDO::FETCH_ASSOC);
        if (count($awaitingRows) === 1) {
            $only = $awaitingRows[0];
            if ((int) $only['payment_amount'] !== $nominal) {
                $mismatchBookingId = (int) $only['id'];
                $mark = $pdo->prepare(
                    "UPDATE kakiempa_v2_bookings
                     SET payment_verification = 'mismatch'
                     WHERE id = ? AND status IN ($statusPlaceholders)",
                );
                $mark->execute(array_merge([$mismatchBookingId], kakiempat_payment_webhook_matchable_statuses()));
            }
        }

        kakiempat_payment_insert_inbound_log(
            $pdo,
            $nominal,
            $bankVal,
            $namaVal,
            $receivedAt,
            null,
            $body,
            $rawTimestamp,
        );
        kakiempat_payment_insert_transaction_log(
            $pdo,
            null,
            $nominal,
            $senderBank,
            $namaVal ?? 'Tidak diketahui',
            $rawTimestamp,
            $rawNotification,
        );

        $pdo->commit();

        return [
            'matched' => false,
            'booking_id' => null,
            'mismatch_booking_id' => $mismatchBookingId,
            'sender_bank' => $senderBank,
        ];
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        throw $e;
    }
}

/**
 * @return array<string, mixed>
 */
function kakiempat_payment_status_for_booking(PDO $pdo, int $bookingId): array
{
    $stmt = $pdo->prepare(
        'SELECT id, status, total_price, payment_amount, payment_verification, payment_matched_at
         FROM kakiempa_v2_bookings WHERE id = ? LIMIT 1',
    );
    $stmt->execute([$bookingId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!is_array($row)) {
        v2ApiFail('booking_not_found', 'Booking tidak ditemukan.', 404);
    }

    $status = (string) $row['status'];
    $verification = $row['payment_verification'] !== null
        ? (string) $row['payment_verification']
        : null;

    $paymentState = 'waiting';
    $displayLabel = 'Menunggu Pembayaran';

    if (strtoupper($status) === 'PAID' || $verification === 'matched') {
        $paymentState = 'received';
        $displayLabel = 'Pembayaran Diterima';
    } elseif ($verification === 'mismatch') {
        $paymentState = 'mismatch';
        $displayLabel = 'Pembayaran Tidak Cocok';
    }

    $totalPrice = kakiempat_platform_fee_v2_resolve_total_price(
        (int) ($row['total_price'] ?? 0),
        (int) ($row['payment_amount'] ?? 0),
    );
    $breakdown = kakiempat_platform_fee_v2_payment_breakdown($totalPrice);

    return [
        'ok' => true,
        'booking_id' => (string) $row['id'],
        'status' => $status,
        'payment_state' => $paymentState,
        'display_label' => $displayLabel,
        'total_price' => $totalPrice,
        'payment_amount' => (int) $row['payment_amount'],
        'platform_fee_owner' => (int) ($breakdown['platform_fee_owner'] ?? 0),
        'owner_pays' => (int) ($breakdown['owner_pays'] ?? 0),
        'payment_matched_at' => $row['payment_matched_at'],
    ];
}
