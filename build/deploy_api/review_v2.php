<?php
declare(strict_types=1);

/**
 * Ulasan v2 — owner memberi rating setelah booking selesai.
 *
 * POST ?action=submit_review
 * GET  ?action=get_sitter_reviews&sitter_id=
 * GET  ?action=list_booking_review&booking_id=
 */
require_once __DIR__ . '/lib/kakiempat_review_v2.php';

$action = strtolower(trim((string) ($_GET['action'] ?? '')));
$method = strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? 'GET'));

try {
    switch ($action) {
        case 'submit_review':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            kakiempat_review_v2_submit(v2ApiBody());
            break;
        case 'get_sitter_reviews':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_review_v2_get_sitter_reviews();
            break;
        case 'list_booking_review':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_review_v2_list_booking_review();
            break;
        default:
            v2ApiFail(
                'action_required',
                'Gunakan submit_review, get_sitter_reviews, atau list_booking_review.',
                400,
            );
    }
} catch (Throwable $e) {
    error_log('review_v2: ' . $e->getMessage());
    v2ApiFail('server_error', 'Terjadi kesalahan server. Coba lagi sebentar.', 500);
}
