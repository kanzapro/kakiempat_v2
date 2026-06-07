<?php
declare(strict_types=1);

require_once __DIR__ . '/../v2_api_common.php';
require_once __DIR__ . '/kakiempat_event_notifications.php';

function kakiempat_notification_v2_check_new(): void
{
    $auth = v2ApiRequireAuth();
    $pdo = v2ApiPdo();

    $count = kakiempat_notification_v2_count_unread($pdo, $auth['user_id']);
    v2ApiRespondData([
        'unread_count' => $count,
        'has_new' => $count > 0,
    ]);
}

/** @param array<string, mixed> $body */
function kakiempat_notification_v2_mark_read(array $body): void
{
    $auth = v2ApiRequireAuth();
    $pdo = v2ApiPdo();

    $markAll = filter_var($body['mark_all'] ?? false, FILTER_VALIDATE_BOOLEAN);
    $notificationId = (int) ($body['notification_id'] ?? 0);

    if ($markAll) {
        kakiempat_notification_v2_mark_all_read($pdo, $auth['user_id']);
        v2ApiRespondData(['marked' => 'all', 'message' => 'Semua notifikasi ditandai dibaca.']);
        return;
    }

    if ($notificationId < 1) {
        v2ApiFail('invalid_notification_id', 'notification_id wajib atau gunakan mark_all: true.', 400);
    }

    $updated = kakiempat_notification_v2_mark_one_read($pdo, $auth['user_id'], $notificationId);
    if (!$updated) {
        v2ApiFail('notification_not_found', 'Notifikasi tidak ditemukan.', 404);
    }

    v2ApiRespondData([
        'notification_id' => (string) $notificationId,
        'marked' => true,
    ]);
}

function kakiempat_notification_v2_get_notifications(): void
{
    $auth = v2ApiRequireAuth();
    $pdo = v2ApiPdo();

    $page = max(1, (int) ($_GET['page'] ?? 1));
    $limit = (int) ($_GET['limit'] ?? 20);
    if ($limit < 1) {
        $limit = 20;
    }
    if ($limit > 100) {
        $limit = 100;
    }
    $offset = ($page - 1) * $limit;

    $items = kakiempat_notification_v2_fetch_page($pdo, $auth['user_id'], $limit, $offset);
    $total = kakiempat_notification_v2_count_all($pdo, $auth['user_id']);
    $unread = kakiempat_notification_v2_count_unread($pdo, $auth['user_id']);

    v2ApiRespondData([
        'notifications' => $items,
        'page' => $page,
        'limit' => $limit,
        'total' => $total,
        'unread_count' => $unread,
        'has_more' => ($offset + count($items)) < $total,
    ]);
}

function kakiempat_notification_v2_count_unread(PDO $pdo, int $userId): int
{
    if (kakiempat_in_app_notifications_table_exists($pdo)) {
        $stmt = $pdo->prepare(
            'SELECT COUNT(*) FROM kakiempa_v2_in_app_notifications
             WHERE user_id = ? AND is_read = 0',
        );
        $stmt->execute([$userId]);

        return (int) $stmt->fetchColumn();
    }

    if (v2ApiTableExists($pdo, 'kakiempa_v2_notifications')) {
        $stmt = $pdo->prepare(
            'SELECT COUNT(*) FROM kakiempa_v2_notifications
             WHERE user_id = ? AND is_read = 0',
        );
        $stmt->execute([$userId]);

        return (int) $stmt->fetchColumn();
    }

    return 0;
}

function kakiempat_notification_v2_count_all(PDO $pdo, int $userId): int
{
    if (kakiempat_in_app_notifications_table_exists($pdo)) {
        $stmt = $pdo->prepare(
            'SELECT COUNT(*) FROM kakiempa_v2_in_app_notifications WHERE user_id = ?',
        );
        $stmt->execute([$userId]);

        return (int) $stmt->fetchColumn();
    }

    if (v2ApiTableExists($pdo, 'kakiempa_v2_notifications')) {
        $stmt = $pdo->prepare(
            'SELECT COUNT(*) FROM kakiempa_v2_notifications WHERE user_id = ?',
        );
        $stmt->execute([$userId]);

        return (int) $stmt->fetchColumn();
    }

    return 0;
}

/** @return list<array<string, mixed>> */
function kakiempat_notification_v2_fetch_page(PDO $pdo, int $userId, int $limit, int $offset): array
{
    if (kakiempat_in_app_notifications_table_exists($pdo)) {
        $stmt = $pdo->prepare(
            'SELECT id, title, message, booking_id, notification_type, is_read, created_at
             FROM kakiempa_v2_in_app_notifications
             WHERE user_id = ?
             ORDER BY created_at DESC, id DESC
             LIMIT ? OFFSET ?',
        );
        $stmt->bindValue(1, $userId, PDO::PARAM_INT);
        $stmt->bindValue(2, $limit, PDO::PARAM_INT);
        $stmt->bindValue(3, $offset, PDO::PARAM_INT);
        $stmt->execute();
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC) ?: [];

        return array_map(
            static fn(array $row): array => kakiempat_notification_v2_format_row($row, true),
            $rows,
        );
    }

    if (v2ApiTableExists($pdo, 'kakiempa_v2_notifications')) {
        $stmt = $pdo->prepare(
            'SELECT id, title, is_read, created_at
             FROM kakiempa_v2_notifications
             WHERE user_id = ?
             ORDER BY created_at DESC, id DESC
             LIMIT ? OFFSET ?',
        );
        $stmt->bindValue(1, $userId, PDO::PARAM_INT);
        $stmt->bindValue(2, $limit, PDO::PARAM_INT);
        $stmt->bindValue(3, $offset, PDO::PARAM_INT);
        $stmt->execute();
        $rows = $stmt->fetchAll(PDO::FETCH_ASSOC) ?: [];

        return array_map(
            static fn(array $row): array => kakiempat_notification_v2_format_row($row, false),
            $rows,
        );
    }

    return [];
}

function kakiempat_notification_v2_mark_one_read(PDO $pdo, int $userId, int $notificationId): bool
{
    if (kakiempat_in_app_notifications_table_exists($pdo)) {
        $stmt = $pdo->prepare(
            'UPDATE kakiempa_v2_in_app_notifications SET is_read = 1
             WHERE id = ? AND user_id = ?',
        );
        $stmt->execute([$notificationId, $userId]);

        return $stmt->rowCount() > 0;
    }

    if (v2ApiTableExists($pdo, 'kakiempa_v2_notifications')) {
        $stmt = $pdo->prepare(
            'UPDATE kakiempa_v2_notifications SET is_read = 1
             WHERE id = ? AND user_id = ?',
        );
        $stmt->execute([$notificationId, $userId]);

        return $stmt->rowCount() > 0;
    }

    return false;
}

function kakiempat_notification_v2_mark_all_read(PDO $pdo, int $userId): void
{
    if (kakiempat_in_app_notifications_table_exists($pdo)) {
        $pdo->prepare(
            'UPDATE kakiempa_v2_in_app_notifications SET is_read = 1 WHERE user_id = ?',
        )->execute([$userId]);
    }
    if (v2ApiTableExists($pdo, 'kakiempa_v2_notifications')) {
        $pdo->prepare(
            'UPDATE kakiempa_v2_notifications SET is_read = 1 WHERE user_id = ?',
        )->execute([$userId]);
    }
    kakiempat_event_notifications_mark_read_file($userId);
}

/** @param array<string, mixed> $row
 * @return array<string, mixed>
 */
function kakiempat_notification_v2_format_row(array $row, bool $rich): array
{
    $item = [
        'id' => (string) ($row['id'] ?? ''),
        'title' => (string) ($row['title'] ?? ''),
        'is_read' => (int) ($row['is_read'] ?? 0) === 1,
        'created_at' => (string) ($row['created_at'] ?? ''),
    ];
    if ($rich) {
        $item['message'] = (string) ($row['message'] ?? '');
        $item['booking_id'] = $row['booking_id'] !== null ? (string) $row['booking_id'] : null;
        $item['type'] = (string) ($row['notification_type'] ?? 'general');
    } else {
        $item['message'] = (string) ($row['title'] ?? '');
        $item['booking_id'] = null;
        $item['type'] = 'general';
    }

    return $item;
}
