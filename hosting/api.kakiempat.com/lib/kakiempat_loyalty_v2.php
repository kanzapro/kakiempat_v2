<?php
declare(strict_types=1);

require_once __DIR__ . '/../v2_api_common.php';

const KAKIEMPAT_LOYALTY_POINTS_PER_BOOKING = 10;
const KAKIEMPAT_LOYALTY_REDEEM_RATE = 100; // 100 poin = Rp 10.000
const KAKIEMPAT_LOYALTY_REDEEM_VALUE = 10000;

function kakiempat_loyalty_v2_table_exists(PDO $pdo): bool
{
    return v2ApiTableExists($pdo, 'kakiempa_v2_loyalty_points');
}

function kakiempat_loyalty_v2_get_points(PDO $pdo, int $userId): int
{
    if (!kakiempat_loyalty_v2_table_exists($pdo)) {
        return 0;
    }
    $stmt = $pdo->prepare(
        'SELECT points FROM kakiempa_v2_loyalty_points WHERE user_id = ? LIMIT 1',
    );
    $stmt->execute([$userId]);
    $val = $stmt->fetchColumn();

    return $val === false ? 0 : (int) $val;
}

function kakiempat_loyalty_v2_add_points(
    PDO $pdo,
    int $userId,
    int $points,
    string $kind,
    ?int $bookingId = null,
    ?string $description = null,
): void {
    if (!kakiempat_loyalty_v2_table_exists($pdo) || $points === 0) {
        return;
    }

    $stmt = $pdo->prepare(
        'SELECT points FROM kakiempa_v2_loyalty_points WHERE user_id = ? LIMIT 1',
    );
    $stmt->execute([$userId]);
    if ($stmt->fetchColumn() === false) {
        $pdo->prepare(
            'INSERT INTO kakiempa_v2_loyalty_points (user_id, points) VALUES (?, ?)',
        )->execute([$userId, max(0, $points)]);
    } else {
        $pdo->prepare(
            'UPDATE kakiempa_v2_loyalty_points SET points = points + ? WHERE user_id = ?',
        )->execute([$points, $userId]);
    }

    if (v2ApiTableExists($pdo, 'kakiempa_v2_loyalty_transactions')) {
        $pdo->prepare(
            'INSERT INTO kakiempa_v2_loyalty_transactions
                (user_id, points, kind, booking_id, description)
             VALUES (?, ?, ?, ?, ?)',
        )->execute([$userId, $points, $kind, $bookingId, $description]);
    }
}

function kakiempat_loyalty_v2_award_booking_complete(PDO $pdo, int $ownerUserId, int $bookingId): void
{
    kakiempat_loyalty_v2_add_points(
        $pdo,
        $ownerUserId,
        KAKIEMPAT_LOYALTY_POINTS_PER_BOOKING,
        'booking_complete',
        $bookingId,
        'Poin dari booking selesai',
    );
}

function kakiempat_loyalty_v2_get_profile(PDO $pdo, int $userId): void
{
    $points = kakiempat_loyalty_v2_get_points($pdo, $userId);
    v2ApiRespondData([
        'points' => $points,
        'redeem_rate' => KAKIEMPAT_LOYALTY_REDEEM_RATE,
        'redeem_value' => KAKIEMPAT_LOYALTY_REDEEM_VALUE,
        'redeemable_discount' => intdiv($points, KAKIEMPAT_LOYALTY_REDEEM_RATE) * KAKIEMPAT_LOYALTY_REDEEM_VALUE,
    ]);
}

/** @param array<string, mixed> $body */
function kakiempat_loyalty_v2_redeem(PDO $pdo, int $userId, array $body): void
{
    if (!kakiempat_loyalty_v2_table_exists($pdo)) {
        v2ApiFail('schema_missing', 'Program loyalitas belum tersedia.', 503);
    }

    $pointsToRedeem = (int) ($body['points'] ?? 0);
    if ($pointsToRedeem < KAKIEMPAT_LOYALTY_REDEEM_RATE) {
        v2ApiFail(
            'invalid_points',
            'Minimal ' . KAKIEMPAT_LOYALTY_REDEEM_RATE . ' poin untuk ditukar.',
            400,
        );
    }
    if ($pointsToRedeem % KAKIEMPAT_LOYALTY_REDEEM_RATE !== 0) {
        v2ApiFail(
            'invalid_points',
            'Poin harus kelipatan ' . KAKIEMPAT_LOYALTY_REDEEM_RATE . '.',
            400,
        );
    }

    $current = kakiempat_loyalty_v2_get_points($pdo, $userId);
    if ($current < $pointsToRedeem) {
        v2ApiFail('insufficient_points', 'Poin tidak cukup.', 409);
    }

    $discount = ($pointsToRedeem / KAKIEMPAT_LOYALTY_REDEEM_RATE) * KAKIEMPAT_LOYALTY_REDEEM_VALUE;
    $pdo->prepare(
        'UPDATE kakiempa_v2_loyalty_points SET points = points - ? WHERE user_id = ?',
    )->execute([$pointsToRedeem, $userId]);

    if (v2ApiTableExists($pdo, 'kakiempa_v2_loyalty_transactions')) {
        $pdo->prepare(
            'INSERT INTO kakiempa_v2_loyalty_transactions
                (user_id, points, kind, description)
             VALUES (?, ?, ?, ?)',
        )->execute([
            $userId,
            -$pointsToRedeem,
            'redeem',
            'Tukar diskon Rp ' . number_format((int) $discount, 0, ',', '.'),
        ]);
    }

    v2ApiRespondData([
        'points_redeemed' => $pointsToRedeem,
        'discount_amount' => (int) $discount,
        'remaining_points' => $current - $pointsToRedeem,
        'message' => 'Poin ditukar. Diskon Rp ' . number_format((int) $discount, 0, ',', '.') . ' siap dipakai.',
    ]);
}
