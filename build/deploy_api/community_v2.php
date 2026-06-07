<?php
declare(strict_types=1);

/**
 * Komunitas v2 — galeri hewan publik.
 *
 * GET  ?action=list_gallery
 * POST ?action=upload_gallery
 * POST ?action=like_gallery
 */
require_once __DIR__ . '/lib/kakiempat_community_v2.php';

$action = strtolower(trim((string) ($_GET['action'] ?? '')));
$method = strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? 'GET'));

try {
    switch ($action) {
        case 'list_gallery':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_community_v2_list_gallery();
            break;
        case 'upload_gallery':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            kakiempat_community_v2_upload_gallery(v2ApiBody());
            break;
        case 'like_gallery':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            kakiempat_community_v2_like_gallery(v2ApiBody());
            break;
        default:
            v2ApiFail(
                'action_required',
                'Gunakan list_gallery, upload_gallery, atau like_gallery.',
                400,
            );
    }
} catch (Throwable $e) {
    error_log('community_v2: ' . $e->getMessage());
    v2ApiFail('server_error', 'Terjadi kesalahan server. Coba lagi sebentar.', 500);
}
