<?php
declare(strict_types=1);

/**
 * Auth v2 — pusat autentikasi (kakiempa_v2)
 * POST ?action=register | login | logout | change_password | refresh_token
 *      | forgot_password | reset_password | sso_bootstrap | sso_create | sso_exchange
 *      | sso_handoff | sso_consume
 * GET  ?action=validate_token  (Authorization: Bearer …)
 */
require_once __DIR__ . '/lib/kakiempat_auth_v2.php';
require_once __DIR__ . '/lib/kakiempat_sso_v2.php';

$method = strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? 'GET'));
$action = strtolower(trim((string) ($_GET['action'] ?? $_POST['action'] ?? '')));
if ($action === '' && $method === 'GET') {
    $action = 'validate_token';
}

try {
    $pdo = v2ApiPdo();
} catch (Throwable) {
    v2ApiFail('db_unavailable', 'Database tidak tersedia. Coba lagi nanti.', 503);
}

switch ($action) {
    case 'register':
        if ($method !== 'POST') {
            v2ApiFail('method_not_allowed', 'Gunakan POST untuk daftar.', 405);
        }
        kakiempat_v2_auth_register($pdo, kakiempat_v2_auth_read_json_body());
        break;
    case 'login':
        if ($method !== 'POST') {
            v2ApiFail('method_not_allowed', 'Gunakan POST untuk masuk.', 405);
        }
        kakiempat_v2_auth_login($pdo, kakiempat_v2_auth_read_json_body());
        break;
    case 'validate_token':
        if ($method !== 'GET') {
            v2ApiFail('method_not_allowed', 'Gunakan GET untuk validasi token.', 405);
        }
        kakiempat_v2_auth_validate_token($pdo);
        break;
    case 'logout':
        if ($method !== 'POST') {
            v2ApiFail('method_not_allowed', 'Gunakan POST untuk keluar.', 405);
        }
        kakiempat_v2_auth_logout($pdo);
        break;
    case 'change_password':
        if ($method !== 'POST') {
            v2ApiFail('method_not_allowed', 'Gunakan POST untuk ganti kata sandi.', 405);
        }
        kakiempat_v2_auth_change_password($pdo, kakiempat_v2_auth_read_json_body());
        break;
    case 'refresh_token':
        if ($method !== 'POST') {
            v2ApiFail('method_not_allowed', 'Gunakan POST untuk refresh token.', 405);
        }
        kakiempat_v2_auth_refresh_token($pdo, kakiempat_v2_auth_read_json_body());
        break;
    case 'forgot_password':
        if ($method !== 'POST') {
            v2ApiFail('method_not_allowed', 'Gunakan POST untuk lupa kata sandi.', 405);
        }
        kakiempat_v2_auth_forgot_password($pdo, kakiempat_v2_auth_read_json_body());
        break;
    case 'reset_password':
        if ($method !== 'POST') {
            v2ApiFail('method_not_allowed', 'Gunakan POST untuk reset kata sandi.', 405);
        }
        kakiempat_v2_auth_reset_password($pdo, kakiempat_v2_auth_read_json_body());
        break;
    case 'sso_bootstrap':
        if ($method !== 'POST') {
            v2ApiFail('method_not_allowed', 'Gunakan POST untuk SSO bootstrap.', 405);
        }
        kakiempat_v2_auth_sso_bootstrap($pdo);
        break;
    case 'sso_create':
        if ($method !== 'POST') {
            v2ApiFail('method_not_allowed', 'Gunakan POST untuk SSO create.', 405);
        }
        kakiempat_v2_sso_create($pdo, kakiempat_v2_auth_read_json_body());
        break;
    case 'sso_exchange':
        if ($method !== 'POST') {
            v2ApiFail('method_not_allowed', 'Gunakan POST untuk SSO exchange.', 405);
        }
        kakiempat_v2_sso_exchange($pdo, kakiempat_v2_auth_read_json_body());
        break;
    case 'sso_handoff':
        if ($method !== 'POST') {
            v2ApiFail('method_not_allowed', 'Gunakan POST untuk SSO handoff.', 405);
        }
        kakiempat_v2_auth_sso_handoff_create($pdo);
        break;
    case 'sso_consume':
        if ($method !== 'POST') {
            v2ApiFail('method_not_allowed', 'Gunakan POST untuk SSO consume.', 405);
        }
        kakiempat_v2_auth_sso_handoff_consume($pdo, kakiempat_v2_auth_read_json_body());
        break;
    default:
        v2ApiFail(
            'unknown_action',
            'Aksi tidak dikenali. Gunakan register, login, logout, change_password, refresh_token, forgot_password, reset_password, sso_bootstrap, sso_create, sso_exchange, sso_handoff, sso_consume, atau validate_token.',
            400,
        );
}
