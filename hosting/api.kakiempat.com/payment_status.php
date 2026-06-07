<?php
declare(strict_types=1);

/**
 * Status pembayaran booking — GET ?booking_id=
 */
require_once __DIR__ . '/lib/kakiempat_payment.php';

$method = strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? 'GET'));
if ($method !== 'GET') {
    v2ApiFail('method_not_allowed', 'Gunakan GET.', 405);
}

$bookingIdRaw = trim((string) ($_GET['booking_id'] ?? ''));
if ($bookingIdRaw === '' || !ctype_digit($bookingIdRaw)) {
    v2ApiFail('invalid_booking_id', 'Parameter booking_id wajib (angka).', 400);
}
$bookingId = (int) $bookingIdRaw;
if ($bookingId < 1) {
    v2ApiFail('invalid_booking_id', 'booking_id tidak valid.', 400);
}

try {
    $pdo = v2ApiPdo();
} catch (Throwable) {
    v2ApiFail('db_unavailable', 'Database tidak tersedia.', 503);
}

v2ApiRespond(kakiempat_payment_status_for_booking($pdo, $bookingId));
