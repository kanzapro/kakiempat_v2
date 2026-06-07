<?php
declare(strict_types=1);

/**
 * Batch 1 — Katalog layanan v2 (kakiempa_v2_service_catalog).
 *
 * GET ?action=get_catalog  (auth wajib)
 */
require_once __DIR__ . '/lib/kakiempat_service_v2.php';

$action = strtolower(trim((string) ($_GET['action'] ?? '')));
$method = strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? 'GET'));

if ($action === 'get_service_catalog') {
    $action = 'get_catalog';
}

try {
    if ($action !== 'get_catalog' || $method !== 'GET') {
        v2ApiFail('action_required', 'Gunakan GET ?action=get_catalog', 400);
    }
    kakiempat_service_v2_get_catalog();
} catch (Throwable $e) {
    error_log('service_v2: ' . $e->getMessage());
    v2ApiFail('server_error', 'Terjadi kesalahan server. Coba lagi sebentar.', 500);
}
