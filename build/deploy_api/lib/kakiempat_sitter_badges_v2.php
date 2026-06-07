<?php
declare(strict_types=1);

require_once __DIR__ . '/../v2_api_common.php';

/** @return array{average_rating: ?float, review_count: int, positive_reviews: int, completed_bookings: int} */
function kakiempat_sitter_badges_v2_stats(PDO $pdo, int $sitterUserId): array
{
    $revStmt = $pdo->prepare(
        'SELECT COUNT(*) AS cnt, AVG(rating) AS avg_rating,
                SUM(CASE WHEN rating >= 4 THEN 1 ELSE 0 END) AS positive_cnt
         FROM kakiempa_v2_reviews WHERE sitter_user_id = ?',
    );
    $revStmt->execute([$sitterUserId]);
    $rev = $revStmt->fetch(PDO::FETCH_ASSOC) ?: [];

    $bookStmt = $pdo->prepare(
        "SELECT COUNT(*) FROM kakiempa_v2_bookings
         WHERE sitter_user_id = ? AND status = 'completed'",
    );
    $bookStmt->execute([$sitterUserId]);
    $bookings = (int) ($bookStmt->fetchColumn() ?: 0);

    $avg = $rev['avg_rating'] ?? null;
    $avgFloat = $avg !== null ? round((float) $avg, 2) : null;

    return [
        'average_rating' => $avgFloat,
        'review_count' => (int) ($rev['cnt'] ?? 0),
        'positive_reviews' => (int) ($rev['positive_cnt'] ?? 0),
        'completed_bookings' => $bookings,
    ];
}

/** @return list<array{code: string, label: string, icon: string}> */
function kakiempat_sitter_badges_v2_compute(PDO $pdo, int $sitterUserId): array
{
    $stats = kakiempat_sitter_badges_v2_stats($pdo, $sitterUserId);
    $badges = [];

    if ($stats['average_rating'] !== null && $stats['average_rating'] >= 4.5) {
        $badges[] = ['code' => 'on_time', 'label' => 'Tepat Waktu', 'icon' => 'schedule'];
    }
    if ($stats['positive_reviews'] >= 10) {
        $badges[] = ['code' => 'friendly', 'label' => 'Ramah', 'icon' => 'favorite'];
    }
    if ($stats['completed_bookings'] >= 50) {
        $badges[] = ['code' => 'favorite', 'label' => 'Favorit', 'icon' => 'star'];
    }

    $stmt = $pdo->prepare(
        "SELECT status FROM kakiempa_v2_sitter_profiles WHERE user_id = ? LIMIT 1",
    );
    $stmt->execute([$sitterUserId]);
    if ((string) ($stmt->fetchColumn() ?: '') === 'approved') {
        $badges[] = ['code' => 'verified', 'label' => 'Terverifikasi', 'icon' => 'verified'];
    }

    if (v2ApiTableExists($pdo, 'kakiempa_v2_sitter_promotions')) {
        $promoStmt = $pdo->prepare(
            'SELECT id FROM kakiempa_v2_sitter_promotions
             WHERE sitter_user_id = ? AND is_active = 1 AND used_count < max_uses LIMIT 1',
        );
        $promoStmt->execute([$sitterUserId]);
        if ($promoStmt->fetchColumn()) {
            $badges[] = ['code' => 'promo', 'label' => 'Promo', 'icon' => 'local_offer'];
        }
    }

    return $badges;
}

function kakiempat_sitter_badges_v2_is_verified(PDO $pdo, int $sitterUserId): bool
{
    $stmt = $pdo->prepare(
        "SELECT status FROM kakiempa_v2_sitter_profiles WHERE user_id = ? LIMIT 1",
    );
    $stmt->execute([$sitterUserId]);

    return (string) ($stmt->fetchColumn() ?: '') === 'approved';
}

function kakiempat_sitter_badges_v2_get_for_sitter(): void
{
    $auth = v2ApiRequireAuth();
    $pdo = v2ApiPdo();

    $sitterId = (int) ($_GET['sitter_id'] ?? $_GET['user_id'] ?? $auth['user_id']);
    if ($sitterId < 1) {
        v2ApiFail('invalid_sitter_id', 'sitter_id wajib.', 400);
    }

    $stats = kakiempat_sitter_badges_v2_stats($pdo, $sitterId);
    v2ApiRespondData([
        'sitter_id' => (string) $sitterId,
        'is_verified' => kakiempat_sitter_badges_v2_is_verified($pdo, $sitterId),
        'badges' => kakiempat_sitter_badges_v2_compute($pdo, $sitterId),
        'stats' => $stats,
    ]);
}
