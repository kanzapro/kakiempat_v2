<?php
declare(strict_types=1);

require_once __DIR__ . '/../v2_api_common.php';

const KAKIEMPAT_REFERRAL_BONUS_REFERRER = 20000;
const KAKIEMPAT_REFERRAL_DISCOUNT_REFEREE_PCT = 10;

function kakiempat_referral_v2_table_exists(PDO $pdo): bool
{
    return v2ApiTableExists($pdo, 'kakiempa_v2_referral_codes');
}

function kakiempat_referral_v2_generate_code(int $userId): string
{
    return 'KE' . strtoupper(substr(hash('sha256', (string) $userId . microtime(true)), 0, 8));
}

function kakiempat_referral_v2_ensure_code(PDO $pdo, int $userId): string
{
    if (!kakiempat_referral_v2_table_exists($pdo)) {
        return kakiempat_referral_v2_generate_code($userId);
    }

    $stmt = $pdo->prepare(
        'SELECT code FROM kakiempa_v2_referral_codes WHERE user_id = ? LIMIT 1',
    );
    $stmt->execute([$userId]);
    $existing = $stmt->fetchColumn();
    if ($existing !== false) {
        return (string) $existing;
    }

    for ($i = 0; $i < 5; $i++) {
        $code = kakiempat_referral_v2_generate_code($userId + $i);
        try {
            $pdo->prepare(
                'INSERT INTO kakiempa_v2_referral_codes (user_id, code) VALUES (?, ?)',
            )->execute([$userId, $code]);

            return $code;
        } catch (Throwable) {
            continue;
        }
    }

    return kakiempat_referral_v2_generate_code($userId);
}

function kakiempat_referral_v2_get_code(PDO $pdo, int $userId): void
{
    $code = kakiempat_referral_v2_ensure_code($pdo, $userId);
    v2ApiRespondData([
        'referral_code' => $code,
        'bonus_referrer' => KAKIEMPAT_REFERRAL_BONUS_REFERRER,
        'discount_referee_percent' => KAKIEMPAT_REFERRAL_DISCOUNT_REFEREE_PCT,
    ]);
}

function kakiempat_referral_v2_apply_on_register(PDO $pdo, int $newUserId, string $referralCode): void
{
    if (!kakiempat_referral_v2_table_exists($pdo)) {
        return;
    }

    $code = strtoupper(trim($referralCode));
    if ($code === '') {
        return;
    }

    $stmt = $pdo->prepare(
        'SELECT user_id FROM kakiempa_v2_referral_codes WHERE code = ? LIMIT 1',
    );
    $stmt->execute([$code]);
    $referrerId = (int) ($stmt->fetchColumn() ?: 0);
    if ($referrerId < 1 || $referrerId === $newUserId) {
        return;
    }

    if (!v2ApiTableExists($pdo, 'kakiempa_v2_referral_redemptions')) {
        return;
    }

    try {
        $pdo->prepare(
            'INSERT INTO kakiempa_v2_referral_redemptions
                (referrer_user_id, referee_user_id, bonus_referrer, discount_referee_pct)
             VALUES (?, ?, ?, ?)',
        )->execute([
            $referrerId,
            $newUserId,
            KAKIEMPAT_REFERRAL_BONUS_REFERRER,
            KAKIEMPAT_REFERRAL_DISCOUNT_REFEREE_PCT,
        ]);
    } catch (Throwable) {
        return;
    }

    require_once __DIR__ . '/kakiempat_event_notifications.php';
    kakiempat_event_notifications_push(
        $pdo,
        $referrerId,
        'Bonus Referral',
        'Pengguna baru mendaftar dengan kode Anda. Bonus Rp '
        . number_format(KAKIEMPAT_REFERRAL_BONUS_REFERRER, 0, ',', '.') . ' menanti!',
        null,
        'referral_bonus',
    );
    kakiempat_event_notifications_push(
        $pdo,
        $newUserId,
        'Selamat Datang!',
        'Diskon ' . KAKIEMPAT_REFERRAL_DISCOUNT_REFEREE_PCT . '% untuk booking pertama Anda.',
        null,
        'referral_welcome',
    );
}

function kakiempat_referral_v2_get_referee_discount(PDO $pdo, int $userId): int
{
    if (!v2ApiTableExists($pdo, 'kakiempa_v2_referral_redemptions')) {
        return 0;
    }
    $stmt = $pdo->prepare(
        'SELECT discount_referee_pct FROM kakiempa_v2_referral_redemptions
         WHERE referee_user_id = ? LIMIT 1',
    );
    $stmt->execute([$userId]);
    $val = $stmt->fetchColumn();

    return $val === false ? 0 : (int) $val;
}
