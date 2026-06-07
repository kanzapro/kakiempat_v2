<?php
declare(strict_types=1);

require_once __DIR__ . '/../v2_api_common.php';

/** @param array<string, mixed> $body */
function kakiempat_review_v2_submit(array $body): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['owner', 'founder']);
    $pdo = v2ApiPdo();

    $bookingId = (int) ($body['booking_id'] ?? 0);
    $rating = (int) ($body['rating'] ?? 0);
    $comment = trim((string) ($body['comment'] ?? ''));

    if ($bookingId < 1) {
        v2ApiFail('invalid_booking_id', 'booking_id wajib.', 400);
    }
    if ($rating < 1 || $rating > 5) {
        v2ApiFail('invalid_rating', 'Rating harus antara 1 dan 5.', 400);
    }

    $stmt = $pdo->prepare(
        'SELECT id, owner_user_id, sitter_user_id, status
         FROM kakiempa_v2_bookings WHERE id = ? LIMIT 1',
    );
    $stmt->execute([$bookingId]);
    $booking = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!is_array($booking)) {
        v2ApiFail('booking_not_found', 'Booking tidak ditemukan.', 404);
    }
    if ((int) ($booking['owner_user_id'] ?? 0) !== $auth['user_id']) {
        v2ApiFail('forbidden', 'Hanya pemilik booking yang dapat memberi ulasan.', 403);
    }
    if ((string) ($booking['status'] ?? '') !== 'completed') {
        v2ApiFail('booking_not_completed', 'Ulasan hanya untuk booking yang sudah selesai.', 409);
    }

    $sitterId = (int) ($booking['sitter_user_id'] ?? 0);
    if ($sitterId < 1) {
        v2ApiFail('sitter_missing', 'Booking tidak memiliki pengasuh.', 409);
    }

    $dup = $pdo->prepare('SELECT id FROM kakiempa_v2_reviews WHERE booking_id = ? LIMIT 1');
    $dup->execute([$bookingId]);
    if ($dup->fetchColumn()) {
        v2ApiFail('review_exists', 'Ulasan untuk booking ini sudah ada.', 409);
    }

    $pdo->prepare(
        'INSERT INTO kakiempa_v2_reviews
            (booking_id, owner_user_id, sitter_user_id, rating, comment)
         VALUES (?, ?, ?, ?, ?)',
    )->execute([
        $bookingId,
        $auth['user_id'],
        $sitterId,
        $rating,
        $comment !== '' ? $comment : null,
    ]);

    $reviewId = (int) $pdo->lastInsertId();
    v2ApiRespondData([
        'review' => kakiempat_review_v2_format_row([
            'id' => $reviewId,
            'booking_id' => $bookingId,
            'owner_user_id' => $auth['user_id'],
            'sitter_user_id' => $sitterId,
            'rating' => $rating,
            'comment' => $comment,
            'created_at' => date('Y-m-d H:i:s.u'),
        ]),
        'message' => 'Ulasan berhasil dikirim.',
    ], 201);
}

function kakiempat_review_v2_get_sitter_reviews(): void
{
    v2ApiRequireAuth();
    $pdo = v2ApiPdo();

    $sitterId = (int) ($_GET['sitter_id'] ?? $_GET['user_id'] ?? 0);
    if ($sitterId < 1) {
        v2ApiFail('invalid_sitter_id', 'sitter_id wajib.', 400);
    }

    $limit = (int) ($_GET['limit'] ?? 50);
    if ($limit < 1) {
        $limit = 50;
    }
    if ($limit > 100) {
        $limit = 100;
    }

    $stmt = $pdo->prepare(
        'SELECT r.id, r.booking_id, r.owner_user_id, r.sitter_user_id,
                r.rating, r.comment, r.created_at, u.name AS owner_name
         FROM kakiempa_v2_reviews r
         LEFT JOIN kakiempa_v2_users u ON u.id = r.owner_user_id
         WHERE r.sitter_user_id = ?
         ORDER BY r.created_at DESC, r.id DESC
         LIMIT ?',
    );
    $stmt->bindValue(1, $sitterId, PDO::PARAM_INT);
    $stmt->bindValue(2, $limit, PDO::PARAM_INT);
    $stmt->execute();

    $reviews = [];
    $sum = 0;
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        if (!is_array($row)) {
            continue;
        }
        $reviews[] = kakiempat_review_v2_format_row($row, (string) ($row['owner_name'] ?? ''));
        $sum += (int) ($row['rating'] ?? 0);
    }

    $count = count($reviews);
    v2ApiRespondData([
        'sitter_id' => (string) $sitterId,
        'reviews' => $reviews,
        'total' => $count,
        'average_rating' => $count > 0 ? round($sum / $count, 2) : null,
    ]);
}

function kakiempat_review_v2_list_booking_review(): void
{
    $auth = v2ApiRequireAuth();
    $pdo = v2ApiPdo();

    $bookingId = (int) ($_GET['booking_id'] ?? 0);
    if ($bookingId < 1) {
        v2ApiFail('invalid_booking_id', 'booking_id wajib.', 400);
    }

    $stmt = $pdo->prepare(
        'SELECT b.owner_user_id, b.sitter_user_id FROM kakiempa_v2_bookings b WHERE b.id = ? LIMIT 1',
    );
    $stmt->execute([$bookingId]);
    $booking = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!is_array($booking)) {
        v2ApiFail('booking_not_found', 'Booking tidak ditemukan.', 404);
    }

    $ownerId = (int) ($booking['owner_user_id'] ?? 0);
    $sitterId = (int) ($booking['sitter_user_id'] ?? 0);
    if ($auth['user_id'] !== $ownerId && $auth['user_id'] !== $sitterId && !v2ApiIsAdmin($auth)) {
        v2ApiFail('forbidden', 'Anda tidak memiliki akses ke ulasan booking ini.', 403);
    }

    $rev = $pdo->prepare(
        'SELECT id, booking_id, owner_user_id, sitter_user_id, rating, comment, created_at
         FROM kakiempa_v2_reviews WHERE booking_id = ? LIMIT 1',
    );
    $rev->execute([$bookingId]);
    $row = $rev->fetch(PDO::FETCH_ASSOC);

    v2ApiRespondData([
        'booking_id' => (string) $bookingId,
        'review' => is_array($row) ? kakiempat_review_v2_format_row($row) : null,
    ]);
}

/** @param array<string, mixed> $row */
function kakiempat_review_v2_format_row(array $row, string $ownerName = ''): array
{
    return [
        'id' => (string) ($row['id'] ?? ''),
        'booking_id' => (string) ($row['booking_id'] ?? ''),
        'owner_user_id' => isset($row['owner_user_id']) ? (string) $row['owner_user_id'] : null,
        'sitter_user_id' => isset($row['sitter_user_id']) ? (string) $row['sitter_user_id'] : null,
        'owner_name' => $ownerName !== '' ? $ownerName : null,
        'rating' => (int) ($row['rating'] ?? 0),
        'comment' => (string) ($row['comment'] ?? ''),
        'created_at' => (string) ($row['created_at'] ?? ''),
    ];
}
