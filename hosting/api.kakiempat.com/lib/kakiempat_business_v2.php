<?php
declare(strict_types=1);

require_once __DIR__ . '/../v2_api_common.php';
require_once __DIR__ . '/kakiempat_sitter_badges_v2.php';
require_once __DIR__ . '/kakiempat_event_notifications.php';

function kakiempat_business_v2_earnings_report(PDO $pdo, int $sitterUserId): void
{
    $stats = kakiempat_sitter_badges_v2_stats($pdo, $sitterUserId);

    $weekly = [];
    $monthly = [];
    if (v2ApiTableExists($pdo, 'kakiempa_v2_wallet_ledger')) {
        $stmt = $pdo->prepare(
            "SELECT DATE_FORMAT(created_at, '%x-W%v') AS period,
                    SUM(CASE WHEN kind = 'income' THEN amount ELSE 0 END) AS gross,
                    SUM(CASE WHEN kind = 'platform_fee' THEN amount ELSE 0 END) AS fees
             FROM kakiempa_v2_wallet_ledger
             WHERE user_id = ? AND kind IN ('income', 'platform_fee')
             GROUP BY period
             ORDER BY period DESC
             LIMIT 12",
        );
        $stmt->execute([$sitterUserId]);
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            if (!is_array($row)) {
                continue;
            }
            $gross = (int) ($row['gross'] ?? 0);
            $fees = abs((int) ($row['fees'] ?? 0));
            $weekly[] = [
                'period' => (string) ($row['period'] ?? ''),
                'gross' => $gross,
                'fees' => $fees,
                'net' => $gross - $fees,
            ];
        }

        $mStmt = $pdo->prepare(
            "SELECT DATE_FORMAT(created_at, '%Y-%m') AS period,
                    SUM(CASE WHEN kind = 'income' THEN amount ELSE 0 END) AS gross,
                    SUM(CASE WHEN kind = 'platform_fee' THEN amount ELSE 0 END) AS fees
             FROM kakiempa_v2_wallet_ledger
             WHERE user_id = ? AND kind IN ('income', 'platform_fee')
             GROUP BY period
             ORDER BY period DESC
             LIMIT 12",
        );
        $mStmt->execute([$sitterUserId]);
        while ($row = $mStmt->fetch(PDO::FETCH_ASSOC)) {
            if (!is_array($row)) {
                continue;
            }
            $gross = (int) ($row['gross'] ?? 0);
            $fees = abs((int) ($row['fees'] ?? 0));
            $monthly[] = [
                'period' => (string) ($row['period'] ?? ''),
                'gross' => $gross,
                'fees' => $fees,
                'net' => $gross - $fees,
            ];
        }
    }

    $totalNet = 0;
    foreach ($monthly as $m) {
        $totalNet += (int) ($m['net'] ?? 0);
    }

    v2ApiRespondData([
        'total_bookings' => $stats['completed_bookings'],
        'average_rating' => $stats['average_rating'],
        'total_net_income' => $totalNet,
        'weekly' => array_reverse($weekly),
        'monthly' => array_reverse($monthly),
    ]);
}

/** @return list<array{code: string, label: string, earned_at: string}> */
function kakiempat_business_v2_list_achievements(PDO $pdo, int $sitterUserId): array
{
    if (!v2ApiTableExists($pdo, 'kakiempa_v2_sitter_achievements')) {
        return [];
    }
    $stmt = $pdo->prepare(
        'SELECT badge_code, earned_at FROM kakiempa_v2_sitter_achievements
         WHERE sitter_user_id = ? ORDER BY earned_at DESC',
    );
    $stmt->execute([$sitterUserId]);
    $labels = [
        'first_10_bookings' => '10 Booking Pertama!',
        'first_50_bookings' => '50 Booking!',
        'rating_5_0' => 'Rating 5.0!',
    ];
    $items = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        if (!is_array($row)) {
            continue;
        }
        $code = (string) ($row['badge_code'] ?? '');
        $items[] = [
            'code' => $code,
            'label' => $labels[$code] ?? $code,
            'earned_at' => (string) ($row['earned_at'] ?? ''),
        ];
    }

    return $items;
}

function kakiempat_business_v2_check_achievements(PDO $pdo, int $sitterUserId): void
{
    if (!v2ApiTableExists($pdo, 'kakiempa_v2_sitter_achievements')) {
        return;
    }

    $stats = kakiempat_sitter_badges_v2_stats($pdo, $sitterUserId);
    $toAward = [];

    if ($stats['completed_bookings'] >= 10) {
        $toAward['first_10_bookings'] = '10 Booking Pertama!';
    }
    if ($stats['completed_bookings'] >= 50) {
        $toAward['first_50_bookings'] = '50 Booking!';
    }
    if ($stats['average_rating'] !== null && $stats['average_rating'] >= 5.0 && $stats['review_count'] >= 1) {
        $toAward['rating_5_0'] = 'Rating 5.0!';
    }

    foreach ($toAward as $code => $label) {
        $check = $pdo->prepare(
            'SELECT id FROM kakiempa_v2_sitter_achievements
             WHERE sitter_user_id = ? AND badge_code = ? LIMIT 1',
        );
        $check->execute([$sitterUserId, $code]);
        if ($check->fetchColumn()) {
            continue;
        }
        $pdo->prepare(
            'INSERT INTO kakiempa_v2_sitter_achievements (sitter_user_id, badge_code) VALUES (?, ?)',
        )->execute([$sitterUserId, $code]);
        kakiempat_event_notifications_push(
            $pdo,
            $sitterUserId,
            'Target Tercapai!',
            'Selamat! Anda mendapat lencana: ' . $label,
            null,
            'achievement',
        );
    }
}

function kakiempat_business_v2_get_achievements(PDO $pdo, int $sitterUserId): void
{
    kakiempat_business_v2_check_achievements($pdo, $sitterUserId);
    v2ApiRespondData([
        'achievements' => kakiempat_business_v2_list_achievements($pdo, $sitterUserId),
    ]);
}

/** @param array<string, mixed> $body */
function kakiempat_business_v2_create_promotion(PDO $pdo, int $sitterUserId, array $body): void
{
    if (!v2ApiTableExists($pdo, 'kakiempa_v2_sitter_promotions')) {
        v2ApiFail('schema_missing', 'Promosi belum tersedia. Jalankan migrasi 019.', 503);
    }

    $discount = (int) ($body['discount_percent'] ?? 10);
    if ($discount < 5 || $discount > 50) {
        v2ApiFail('invalid_discount', 'Diskon harus antara 5% dan 50%.', 400);
    }

    $code = strtoupper(trim((string) ($body['code'] ?? '')));
    if ($code === '') {
        $code = 'SIT' . strtoupper(substr(hash('sha256', (string) $sitterUserId . microtime(true)), 0, 6));
    }
    if (strlen($code) > 16) {
        v2ApiFail('invalid_code', 'Kode kupon maksimal 16 karakter.', 400);
    }

    $pdo->prepare(
        'INSERT INTO kakiempa_v2_sitter_promotions
            (sitter_user_id, code, discount_percent, max_uses)
         VALUES (?, ?, ?, 1)',
    )->execute([$sitterUserId, $code, $discount]);

    v2ApiRespondData([
        'promotion' => [
            'id' => (string) $pdo->lastInsertId(),
            'code' => $code,
            'discount_percent' => $discount,
            'max_uses' => 1,
            'used_count' => 0,
            'is_active' => true,
        ],
        'message' => 'Kupon promo berhasil dibuat.',
    ], 201);
}

function kakiempat_business_v2_list_my_promotions(PDO $pdo, int $sitterUserId): void
{
    if (!v2ApiTableExists($pdo, 'kakiempa_v2_sitter_promotions')) {
        v2ApiRespondData(['promotions' => [], 'total' => 0]);
        return;
    }

    $stmt = $pdo->prepare(
        'SELECT id, code, discount_percent, max_uses, used_count, is_active, created_at
         FROM kakiempa_v2_sitter_promotions
         WHERE sitter_user_id = ?
         ORDER BY created_at DESC',
    );
    $stmt->execute([$sitterUserId]);

    $items = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        if (!is_array($row)) {
            continue;
        }
        $items[] = [
            'id' => (string) ($row['id'] ?? ''),
            'code' => (string) ($row['code'] ?? ''),
            'discount_percent' => (int) ($row['discount_percent'] ?? 0),
            'max_uses' => (int) ($row['max_uses'] ?? 0),
            'used_count' => (int) ($row['used_count'] ?? 0),
            'is_active' => (int) ($row['is_active'] ?? 0) === 1,
            'created_at' => (string) ($row['created_at'] ?? ''),
        ];
    }

    v2ApiRespondData(['promotions' => $items, 'total' => count($items)]);
}

function kakiempat_business_v2_has_active_promo(PDO $pdo, int $sitterUserId): bool
{
    if (!v2ApiTableExists($pdo, 'kakiempa_v2_sitter_promotions')) {
        return false;
    }
    $stmt = $pdo->prepare(
        'SELECT id FROM kakiempa_v2_sitter_promotions
         WHERE sitter_user_id = ? AND is_active = 1 AND used_count < max_uses LIMIT 1',
    );
    $stmt->execute([$sitterUserId]);

    return (bool) $stmt->fetchColumn();
}
