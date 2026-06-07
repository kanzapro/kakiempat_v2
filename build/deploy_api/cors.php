<?php
declare(strict_types=1);

function kakiempat_v2_cors_allowed_origins(): array
{
    return [
        'https://www.kakiempat.com',
        'https://kakiempat.com',
        'https://owner.kakiempat.com',
        'https://sitter.kakiempat.com',
        'https://admin.kakiempat.com',
        'https://staging.kakiempat.com',
        'http://localhost',
        'http://127.0.0.1',
    ];
}

function kakiempat_v2_cors_origin_is_allowed(string $origin): bool
{
    if ($origin === '') {
        return false;
    }
    if (in_array($origin, kakiempat_v2_cors_allowed_origins(), true)) {
        return true;
    }
    return (bool) preg_match('#^https?://localhost(:\d+)?$#', $origin);
}

function kakiempat_v2_apply_strict_cors(): void
{
    $origin = trim((string) ($_SERVER['HTTP_ORIGIN'] ?? ''));
    if ($origin !== '') {
        if (!kakiempat_v2_cors_origin_is_allowed($origin)) {
            http_response_code(403);
            header('Content-Type: application/json; charset=utf-8');
            echo json_encode(['ok' => false, 'error' => 'cors_denied', 'message' => 'Asal permintaan tidak diizinkan.']);
            exit;
        }
        header('Access-Control-Allow-Origin: ' . $origin);
        header('Access-Control-Allow-Credentials: true');
        header('Vary: Origin');
    }
    header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
    header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Native-Session, X-Payment-Webhook-Secret');
    header('Access-Control-Max-Age: 86400');

    if (strtoupper((string) ($_SERVER['REQUEST_METHOD'] ?? '')) === 'OPTIONS') {
        http_response_code(204);
        exit;
    }

    if (function_exists('v2ApiApplySecurityHeaders')) {
        v2ApiApplySecurityHeaders();
    }
}

if (!defined('KAKIEMPAT_SKIP_STRICT_CORS')) {
    kakiempat_v2_apply_strict_cors();
}
