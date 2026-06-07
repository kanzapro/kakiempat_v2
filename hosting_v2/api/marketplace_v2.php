<?php
declare(strict_types=1);

/**
 * Batch 2 — Marketplace v2 (kakiempa_v2).
 *
 * POST ?action=create_request | create_offer | accept_offer
 * GET  ?action=list_requests | list_my_requests | list_offers | estimate_broadcast
 */
require_once __DIR__ . '/lib/kakiempat_marketplace_v2.php';

$action = strtolower(trim((string) ($_GET['action'] ?? '')));
$method = strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? 'GET'));

try {
    switch ($action) {
        case 'create_request':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            kakiempat_marketplace_v2_create_request(v2ApiBody());
            break;
        case 'list_requests':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_marketplace_v2_list_requests();
            break;
        case 'list_my_requests':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_marketplace_v2_list_my_requests();
            break;
        case 'list_offers':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_marketplace_v2_list_offers();
            break;
        case 'estimate_broadcast':
            if ($method !== 'GET') {
                v2ApiFail('method_not_allowed', 'Gunakan metode GET.', 405);
            }
            kakiempat_marketplace_v2_estimate_broadcast();
            break;
        case 'create_offer':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            kakiempat_marketplace_v2_create_offer(v2ApiBody());
            break;
        case 'accept_offer':
            if ($method !== 'POST') {
                v2ApiFail('method_not_allowed', 'Gunakan metode POST.', 405);
            }
            kakiempat_marketplace_v2_accept_offer(v2ApiBody());
            break;
        default:
            v2ApiFail(
                'action_required',
                'Gunakan create_request, list_requests, list_my_requests, list_offers, estimate_broadcast, create_offer, atau accept_offer.',
                400,
            );
    }
} catch (Throwable $e) {
    error_log('marketplace_v2: ' . $e->getMessage());
    v2ApiFail('server_error', 'Terjadi kesalahan server. Coba lagi sebentar.', 500);
}
