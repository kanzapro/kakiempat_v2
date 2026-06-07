<?php
declare(strict_types=1);

/**
 * Pembayaran Wise/SeaBank v2 — verifikasi manual admin.
 *
 * POST ?action=submit_payment_proof     (owner, Bearer token)
 * POST ?action=admin_approve_payment  (admin/founder)
 * POST ?action=admin_reject_payment   (admin/founder)
 * GET  ?action=list_pending_verification (admin/founder)
 * GET  ?action=get_payment_config     (publik)
 */
require_once __DIR__ . '/lib/kakiempat_payment_v2.php';

$method = strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? 'GET'));
$action = strtolower(trim((string) ($_GET['action'] ?? $_POST['action'] ?? '')));

try {
    $pdo = v2ApiPdo();
} catch (Throwable) {
    v2ApiFail('db_unavailable', 'Database tidak tersedia.', 503);
}

if ($action === 'get_payment_config') {
    if ($method !== 'GET') {
        v2ApiFail('method_not_allowed', 'Gunakan GET.', 405);
    }
    kakiempat_payment_v2_public_config();
}

$user = null;
$adminActions = [
    'admin_approve_payment',
    'admin_reject_payment',
    'list_pending_verification',
];
$ownerActions = ['submit_payment_proof'];

if (in_array($action, array_merge($adminActions, $ownerActions), true)) {
    $user = kakiempat_payment_v2_require_user($pdo);
}

switch ($action) {
    case 'submit_payment_proof':
        if ($method !== 'POST') {
            v2ApiFail('method_not_allowed', 'Gunakan POST.', 405);
        }
        $body = kakiempat_v2_auth_read_json_body();
        if ($body === [] && !empty($_POST)) {
            $body = $_POST;
        }
        kakiempat_payment_v2_submit_proof($pdo, $user, $body);
        break;

    case 'admin_approve_payment':
        if ($method !== 'POST') {
            v2ApiFail('method_not_allowed', 'Gunakan POST.', 405);
        }
        if (!kakiempat_payment_v2_is_admin($user)) {
            v2ApiFail('forbidden', 'Hanya admin yang dapat menyetujui pembayaran.', 403);
        }
        kakiempat_payment_v2_admin_approve($pdo, kakiempat_v2_auth_read_json_body());
        break;

    case 'admin_reject_payment':
        if ($method !== 'POST') {
            v2ApiFail('method_not_allowed', 'Gunakan POST.', 405);
        }
        if (!kakiempat_payment_v2_is_admin($user)) {
            v2ApiFail('forbidden', 'Hanya admin yang dapat menolak pembayaran.', 403);
        }
        kakiempat_payment_v2_admin_reject($pdo, kakiempat_v2_auth_read_json_body());
        break;

    case 'list_pending_verification':
        if ($method !== 'GET') {
            v2ApiFail('method_not_allowed', 'Gunakan GET.', 405);
        }
        if (!kakiempat_payment_v2_is_admin($user)) {
            v2ApiFail('forbidden', 'Hanya admin.', 403);
        }
        v2ApiRespond([
            'ok' => true,
            'items' => kakiempat_payment_v2_list_pending($pdo),
        ]);
        break;

    default:
        v2ApiFail(
            'unknown_action',
            'Aksi tidak dikenali. Gunakan submit_payment_proof, admin_approve_payment, admin_reject_payment, list_pending_verification, get_payment_config.',
            400,
        );
}
