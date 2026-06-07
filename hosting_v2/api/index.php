<?php
declare(strict_types=1);

header('Content-Type: application/json; charset=utf-8');
echo json_encode([
    'ok' => true,
    'service' => 'kakiempat-api-v2',
    'base_url' => 'https://www.api.kakiempat.com',
    'modules' => [
        'auth_v2.php' => [
            'POST' => ['register', 'login', 'logout', 'change_password'],
            'GET' => ['validate_token'],
        ],
        'owner_v2.php' => [
            'POST' => ['save_profile', 'add_pet', 'update_pet', 'delete_pet'],
            'GET' => ['get_profile'],
        ],
        'sitter_v2.php' => [
            'POST' => ['save_profile', 'submit_verification', 'request_withdraw'],
            'GET' => ['get_profile', 'get_wallet', 'list_my_withdrawals'],
        ],
        'service_v2.php' => [
            'GET' => ['get_catalog'],
        ],
        'booking_v2.php' => [
            'POST' => [
                'create_request', 'accept_request', 'reject_request',
                'sitter_confirm', 'sitter_en_route', 'start_booking',
                'complete_booking', 'cancel_booking',
            ],
            'GET' => ['list_incoming_requests', 'get_booking', 'list_my_bookings'],
        ],
        'marketplace_v2.php' => [
            'POST' => ['create_request', 'create_offer', 'accept_offer'],
            'GET' => ['list_requests'],
        ],
        'chat_v2.php' => [
            'POST' => ['send_message'],
            'GET' => ['get_messages', 'check_new_messages'],
        ],
        'notification_v2.php' => [
            'POST' => ['mark_read'],
            'GET' => ['check_new', 'get_notifications'],
        ],
        'review_v2.php' => [
            'POST' => ['submit_review'],
            'GET' => ['get_sitter_reviews', 'list_booking_review'],
        ],
        'admin_v2.php' => [
            'GET' => [
                'list_pending_sitters', 'list_sitters', 'list_owners',
                'list_bookings', 'list_pending_withdrawals',
            ],
            'POST' => [
                'approve_sitter', 'reject_sitter',
                'approve_withdrawal', 'reject_withdrawal',
            ],
        ],
        'payment_v2.php' => [
            'GET' => ['get_payment_config', 'list_pending_verification'],
            'POST' => ['submit_payment_proof', 'admin_approve_payment', 'admin_reject_payment'],
        ],
        'payment_status.php' => ['GET booking payment status'],
        'payment_webhook.php' => ['POST SeaBank forwarder webhook'],
    ],
    'legacy_deprecated' => [
        'get_notifications.php',
        'get_unread_notifications.php',
    ],
    'migrations' => 'apply_v2_migration.php?secret=...&file=001_core_tables.sql (001–016)',
], JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
