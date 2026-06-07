<?php
declare(strict_types=1);

/**
 * Webhook notifikasi transfer masuk (Android SeaBank forwarder).
 * POST JSON: nominal, bank_pengirim, nama_pengirim, timestamp
 *
 * Keamanan: header wajib X-Payment-Webhook-Secret (hash_equals vs .payment_webhook_secret).
 */
define('KAKIEMPAT_SKIP_STRICT_CORS', true);

require_once __DIR__ . '/lib/kakiempat_payment.php';

kakiempat_payment_webhook_apply_cors();

$method = strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? 'GET'));
if ($method !== 'POST') {
    kakiempat_payment_webhook_deny(405, 'Method not allowed');
}

kakiempat_payment_assert_webhook_auth();

try {
    $pdo = v2ApiPdo();
} catch (Throwable) {
    kakiempat_payment_webhook_deny(500, 'Database failure');
}

$body = kakiempat_payment_read_json_body();
if ($body === [] && !empty($_POST)) {
    $body = $_POST;
}

try {
    $result = kakiempat_payment_process_webhook($pdo, $body);
} catch (Throwable) {
    kakiempat_payment_webhook_deny(500, 'Database failure');
}

$response = [
    'ok' => true,
    'matched' => $result['matched'],
    'sender_bank' => (string) ($result['sender_bank'] ?? 'SEABANK_TRANSFER'),
];
if ($result['booking_id'] !== null) {
    $response['booking_id'] = (string) $result['booking_id'];
} else {
    $response['booking_id'] = null;
}
if (!$result['matched'] && $result['mismatch_booking_id'] !== null) {
    $response['mismatch_booking_id'] = (string) $result['mismatch_booking_id'];
}
if (isset($result['platform_fee_breakdown']) && is_array($result['platform_fee_breakdown'])) {
    $response['platform_fee_breakdown'] = $result['platform_fee_breakdown'];
}

http_response_code(200);
header('Content-Type: application/json; charset=utf-8');
echo json_encode($response, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
exit;
