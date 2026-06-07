<?php
declare(strict_types=1);

require_once __DIR__ . '/kakiempat_auth_v2.php';

const KAKIEMPAT_V2_SSO_TTL_SECONDS = 120;

/** @var list<string> */
const KAKIEMPAT_V2_SSO_TARGETS = ['owner', 'sitter', 'admin', 'staging'];

function kakiempat_v2_sso_target_url(string $target, string $code): string
{
    return 'https://' . $target . '.kakiempat.com/?sso=' . rawurlencode($code);
}

function kakiempat_v2_sso_create(PDO $pdo, array $body): void
{
    v2ApiRateLimit($pdo, 'auth:sso_create');
    $auth = v2ApiRequireAuth($pdo);

    $target = strtolower(trim((string) ($body['target'] ?? '')));
    if ($target === '' || !in_array($target, KAKIEMPAT_V2_SSO_TARGETS, true)) {
        v2ApiFail(
            'invalid_target',
            'Target SSO tidak valid. Gunakan owner, sitter, admin, atau staging.',
            400,
        );
    }

    if (!v2ApiTableExists($pdo, 'kakiempa_v2_sso_codes')) {
        v2ApiFail('sso_unavailable', 'SSO belum tersedia. Hubungi admin.', 503);
    }

    $code = 'sso_' . bin2hex(random_bytes(16));
    $expires = (new DateTimeImmutable('now', new DateTimeZone('UTC')))
        ->modify('+' . KAKIEMPAT_V2_SSO_TTL_SECONDS . ' seconds')
        ->format('Y-m-d H:i:s.u');

    $pdo->prepare(
        'INSERT INTO kakiempa_v2_sso_codes (code_hash, user_id, target_host, expires_at)
         VALUES (:hash, :uid, :target, :exp)',
    )->execute([
        'hash' => hash('sha256', $code),
        'uid' => (int) $auth['user_id'],
        'target' => $target,
        'exp' => $expires,
    ]);

    v2ApiRespond([
        'ok' => true,
        'code' => $code,
        'expires_in' => KAKIEMPAT_V2_SSO_TTL_SECONDS,
        'target' => $target,
        'target_url' => kakiempat_v2_sso_target_url($target, $code),
    ]);
}

function kakiempat_v2_sso_exchange(PDO $pdo, array $body): void
{
    v2ApiRateLimit($pdo, 'auth:sso_exchange');

    if (!v2ApiTableExists($pdo, 'kakiempa_v2_sso_codes')) {
        v2ApiFail('sso_unavailable', 'SSO belum tersedia. Silakan login ulang.', 503);
    }

    $code = trim((string) ($body['code'] ?? ''));
    if ($code === '' || !preg_match('/^sso_[a-f0-9]{32}$/', $code)) {
        v2ApiSecurityLog($pdo, 'invalid_sso_code');
        v2ApiFail('invalid_sso_code', 'Kode SSO tidak valid atau sudah kedaluwarsa.', 401);
    }

    $pdo->beginTransaction();
    try {
        $stmt = $pdo->prepare(
            'SELECT c.user_id, c.target_host, c.expires_at, c.used_at,
                    u.name, u.role, u.whatsapp, u.is_active
             FROM kakiempa_v2_sso_codes c
             INNER JOIN kakiempa_v2_users u ON u.id = c.user_id
             WHERE c.code_hash = :hash
             LIMIT 1
             FOR UPDATE',
        );
        $stmt->execute(['hash' => hash('sha256', $code)]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!is_array($row) || !(int) $row['is_active']) {
            $pdo->rollBack();
            v2ApiSecurityLog($pdo, 'invalid_sso_code');
            v2ApiFail('invalid_sso_code', 'Kode SSO tidak ditemukan.', 401);
        }
        if ($row['used_at'] !== null) {
            $pdo->rollBack();
            v2ApiSecurityLog($pdo, 'sso_code_reused', (int) $row['user_id']);
            v2ApiFail('sso_code_used', 'Kode SSO sudah digunakan. Silakan login ulang.', 401);
        }

        $expires = new DateTimeImmutable((string) $row['expires_at'], new DateTimeZone('UTC'));
        if ($expires < new DateTimeImmutable('now', new DateTimeZone('UTC'))) {
            $pdo->rollBack();
            v2ApiSecurityLog($pdo, 'sso_code_expired', (int) $row['user_id']);
            v2ApiFail('sso_code_expired', 'Kode SSO kedaluwarsa. Silakan login ulang.', 401);
        }

        $pdo->prepare(
            'UPDATE kakiempa_v2_sso_codes SET used_at = CURRENT_TIMESTAMP(6) WHERE code_hash = ?',
        )->execute([hash('sha256', $code)]);

        $phone = (string) ($row['whatsapp'] ?? '');
        $payload = kakiempat_v2_auth_success(
            (int) $row['user_id'],
            $phone,
            (string) $row['role'],
            (string) $row['name'],
            $pdo,
        );
        $payload['target'] = (string) ($row['target_host'] ?? '');

        $pdo->commit();
        v2ApiRespond($payload);
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        error_log('sso_v2 exchange: ' . $e->getMessage());
        v2ApiFail('sso_failed', 'Gagal menukar kode SSO. Coba lagi.', 500);
    }
}
