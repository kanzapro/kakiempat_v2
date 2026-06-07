<?php
declare(strict_types=1);

require_once __DIR__ . '/../v2_api_common.php';
require_once __DIR__ . '/kakiempat_booking_v2.php';
require_once __DIR__ . '/kakiempat_event_notifications.php';

/** @param array<string, mixed> $body */
function kakiempat_chat_v2_send_message(array $body): void
{
    $auth = v2ApiRequireAuth();
    $pdo = v2ApiPdo();

    $bookingId = (int) ($body['booking_id'] ?? 0);
    $text = trim((string) ($body['text'] ?? $body['body'] ?? ''));
    if ($bookingId < 1) {
        v2ApiFail('invalid_booking_id', 'booking_id wajib.', 400);
    }
    if ($text === '') {
        v2ApiFail('invalid_text', 'Pesan tidak boleh kosong.', 400);
    }
    if (strlen($text) > 4000) {
        v2ApiFail('text_too_long', 'Pesan maksimal 4000 karakter.', 400);
    }

    $booking = kakiempat_booking_v2_fetch_booking($pdo, $bookingId);
    kakiempat_booking_v2_assert_can_view($auth, $booking);

    $hasSender = v2ApiColumnExists($pdo, 'kakiempa_v2_messages', 'sender_user_id');
    if ($hasSender) {
        $pdo->prepare(
            'INSERT INTO kakiempa_v2_messages (booking_id, sender_user_id, body) VALUES (?, ?, ?)',
        )->execute([$bookingId, $auth['user_id'], $text]);
    } else {
        $pdo->prepare(
            'INSERT INTO kakiempa_v2_messages (booking_id, body) VALUES (?, ?)',
        )->execute([$bookingId, $text]);
    }

    $messageId = (int) $pdo->lastInsertId();
    kakiempat_event_notifications_chat_new(
        $pdo,
        $booking,
        $auth['user_id'],
        $bookingId,
        $text,
    );

    v2ApiRespondData([
        'message_id' => (string) $messageId,
        'booking_id' => (string) $bookingId,
        'text' => $text,
        'sender_user_id' => (string) $auth['user_id'],
    ], 201);
}

function kakiempat_chat_v2_get_messages(): void
{
    $auth = v2ApiRequireAuth();
    $pdo = v2ApiPdo();

    $bookingId = (int) ($_GET['booking_id'] ?? 0);
    if ($bookingId < 1) {
        v2ApiFail('invalid_booking_id', 'Parameter booking_id wajib.', 400);
    }

    $limit = (int) ($_GET['limit'] ?? 50);
    if ($limit < 1) {
        $limit = 50;
    }
    if ($limit > 200) {
        $limit = 200;
    }

    $booking = kakiempat_booking_v2_fetch_booking($pdo, $bookingId);
    kakiempat_booking_v2_assert_can_view($auth, $booking);

    $since = kakiempat_chat_v2_parse_since($_GET['since'] ?? null);
    $hasSender = v2ApiColumnExists($pdo, 'kakiempa_v2_messages', 'sender_user_id');
    $senderCol = $hasSender ? ', sender_user_id' : '';

    if ($since !== null) {
        $stmt = $pdo->prepare(
            "SELECT id, booking_id{$senderCol}, body, created_at
             FROM kakiempa_v2_messages
             WHERE booking_id = ? AND created_at > ?
             ORDER BY created_at ASC
             LIMIT {$limit}",
        );
        $stmt->execute([$bookingId, $since->format('Y-m-d H:i:s.u')]);
    } else {
        $stmt = $pdo->prepare(
            "SELECT id, booking_id{$senderCol}, body, created_at
             FROM kakiempa_v2_messages
             WHERE booking_id = ?
             ORDER BY created_at ASC
             LIMIT {$limit}",
        );
        $stmt->execute([$bookingId]);
    }

    $messages = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        if (!is_array($row)) {
            continue;
        }
        $messages[] = kakiempat_chat_v2_format_message($row);
    }

    v2ApiRespondData([
        'booking_id' => (string) $bookingId,
        'booking' => kakiempat_chat_v2_format_booking_header($booking),
        'messages' => $messages,
        'total' => count($messages),
    ]);
}

function kakiempat_chat_v2_check_new_messages(): void
{
    $auth = v2ApiRequireAuth();
    $pdo = v2ApiPdo();

    $bookingId = (int) ($_GET['booking_id'] ?? 0);
    if ($bookingId < 1) {
        v2ApiFail('invalid_booking_id', 'Parameter booking_id wajib.', 400);
    }

    $sinceRaw = $_GET['since'] ?? null;
    if ($sinceRaw === null || trim((string) $sinceRaw) === '') {
        v2ApiFail('invalid_since', 'Parameter since wajib.', 400);
    }
    $since = kakiempat_chat_v2_parse_since($sinceRaw);
    if ($since === null) {
        v2ApiFail('invalid_since', 'Format since tidak valid.', 400);
    }

    $booking = kakiempat_booking_v2_fetch_booking($pdo, $bookingId);
    kakiempat_booking_v2_assert_can_view($auth, $booking);

    $stmt = $pdo->prepare(
        'SELECT COUNT(*) FROM kakiempa_v2_messages
         WHERE booking_id = ? AND created_at > ?',
    );
    $stmt->execute([$bookingId, $since->format('Y-m-d H:i:s.u')]);
    $count = (int) $stmt->fetchColumn();

    $latest = null;
    if ($count > 0) {
        $latestStmt = $pdo->prepare(
            'SELECT created_at FROM kakiempa_v2_messages
             WHERE booking_id = ? AND created_at > ?
             ORDER BY created_at DESC LIMIT 1',
        );
        $latestStmt->execute([$bookingId, $since->format('Y-m-d H:i:s.u')]);
        $latest = $latestStmt->fetchColumn();
    }

    v2ApiRespondData([
        'booking_id' => (string) $bookingId,
        'count' => $count,
        'has_new' => $count > 0,
        'latest_at' => $latest !== false ? (string) $latest : null,
    ]);
}

/** @param mixed $raw */
function kakiempat_chat_v2_parse_since(mixed $raw): ?DateTimeImmutable
{
    if ($raw === null) {
        return null;
    }
    $value = trim((string) $raw);
    if ($value === '') {
        return null;
    }
    if (ctype_digit($value)) {
        $ts = (int) $value;
        if (strlen($value) > 10) {
            $ts = (int) floor($ts / 1000);
        }

        return (new DateTimeImmutable('@' . $ts))->setTimezone(new DateTimeZone('UTC'));
    }
    try {
        return new DateTimeImmutable($value, new DateTimeZone('UTC'));
    } catch (Throwable) {
        return null;
    }
}

/** @param array<string, mixed> $booking
 * @return array<string, mixed>
 */
function kakiempat_chat_v2_format_booking_header(array $booking): array
{
    return [
        'status' => (string) ($booking['status'] ?? ''),
        'total_price' => (int) ($booking['total_price'] ?? 0),
        'payment_amount' => (int) ($booking['payment_amount'] ?? 0),
        'service_code' => isset($booking['service_code'])
            ? (string) $booking['service_code']
            : null,
    ];
}

/** @param array<string, mixed> $row
 * @return array<string, mixed>
 */
function kakiempat_chat_v2_format_message(array $row): array
{
    return [
        'id' => (string) ($row['id'] ?? ''),
        'booking_id' => isset($row['booking_id']) ? (string) $row['booking_id'] : null,
        'sender_user_id' => isset($row['sender_user_id']) ? (string) $row['sender_user_id'] : null,
        'text' => (string) ($row['body'] ?? ''),
        'created_at' => (string) ($row['created_at'] ?? ''),
    ];
}
