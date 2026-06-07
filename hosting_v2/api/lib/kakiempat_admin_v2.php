<?php
declare(strict_types=1);

require_once __DIR__ . '/../v2_api_common.php';
require_once __DIR__ . '/kakiempat_wallet_v2.php';

function kakiempat_admin_v2_require_founder(): array
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireFounder($auth);

    return $auth;
}

function kakiempat_admin_v2_list_pending_sitters(): void
{
    kakiempat_admin_v2_require_founder();
    $pdo = v2ApiPdo();

    $stmt = $pdo->query(
        "SELECT sp.user_id, sp.display_name, sp.whatsapp, sp.address, sp.status,
                sp.submitted_at, sp.profile_json, u.name AS user_name
         FROM kakiempa_v2_sitter_profiles sp
         INNER JOIN kakiempa_v2_users u ON u.id = sp.user_id
         WHERE sp.status = 'pending_verification'
         ORDER BY sp.submitted_at ASC",
    );

    $sitters = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $sitters[] = kakiempat_admin_v2_format_sitter($row);
    }

    v2ApiRespondData(['sitters' => $sitters, 'total' => count($sitters)]);
}

function kakiempat_admin_v2_list_sitters(): void
{
    kakiempat_admin_v2_require_founder();
    $pdo = v2ApiPdo();

    $statusFilter = trim((string) ($_GET['status'] ?? ''));
    $sql = "SELECT sp.user_id, sp.display_name, sp.whatsapp, sp.address, sp.status,
                   sp.submitted_at, sp.profile_json, u.name AS user_name
            FROM kakiempa_v2_sitter_profiles sp
            INNER JOIN kakiempa_v2_users u ON u.id = sp.user_id";
    $params = [];
    if ($statusFilter !== '') {
        $sql .= ' WHERE sp.status = ?';
        $params[] = $statusFilter;
    }
    $sql .= ' ORDER BY sp.submitted_at DESC, sp.user_id DESC';

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);

    $sitters = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $sitters[] = kakiempat_admin_v2_format_sitter($row);
    }

    v2ApiRespondData(['sitters' => $sitters, 'total' => count($sitters)]);
}

function kakiempat_admin_v2_list_owners(): void
{
    kakiempat_admin_v2_require_founder();
    $pdo = v2ApiPdo();

    $stmt = $pdo->query(
        "SELECT u.id, u.name, u.whatsapp, u.is_active, u.created_at,
                op.home_address, op.latitude, op.longitude
         FROM kakiempa_v2_users u
         LEFT JOIN kakiempa_v2_owner_profiles op ON op.user_id = u.id
         WHERE u.role IN ('owner', 'founder')
         ORDER BY u.created_at DESC",
    );

    $owners = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        if (!is_array($row)) {
            continue;
        }
        $owners[] = [
            'user_id' => (string) ($row['id'] ?? ''),
            'name' => (string) ($row['name'] ?? ''),
            'phone' => (string) ($row['whatsapp'] ?? ''),
            'is_active' => (int) ($row['is_active'] ?? 1) === 1,
            'address' => (string) ($row['home_address'] ?? ''),
            'latitude' => $row['latitude'] ?? null,
            'longitude' => $row['longitude'] ?? null,
            'created_at' => (string) ($row['created_at'] ?? ''),
        ];
    }

    v2ApiRespondData(['owners' => $owners, 'total' => count($owners)]);
}

function kakiempat_admin_v2_list_bookings(): void
{
    kakiempat_admin_v2_require_founder();
    $pdo = v2ApiPdo();

    $status = trim((string) ($_GET['status'] ?? ''));
    $limit = (int) ($_GET['limit'] ?? 100);
    if ($limit < 1) {
        $limit = 100;
    }
    if ($limit > 500) {
        $limit = 500;
    }

    if ($status !== '') {
        $stmt = $pdo->prepare(
            'SELECT b.id, b.offer_id, b.request_id, b.owner_user_id, b.sitter_user_id,
                    b.status, b.total_price, b.payment_amount, b.created_at,
                    ou.name AS owner_name, su.name AS sitter_name
             FROM kakiempa_v2_bookings b
             LEFT JOIN kakiempa_v2_users ou ON ou.id = b.owner_user_id
             LEFT JOIN kakiempa_v2_users su ON su.id = b.sitter_user_id
             WHERE b.status = ?
             ORDER BY b.created_at DESC
             LIMIT ?',
        );
        $stmt->bindValue(1, $status);
        $stmt->bindValue(2, $limit, PDO::PARAM_INT);
        $stmt->execute();
    } else {
        $stmt = $pdo->prepare(
            'SELECT b.id, b.offer_id, b.request_id, b.owner_user_id, b.sitter_user_id,
                    b.status, b.total_price, b.payment_amount, b.created_at,
                    ou.name AS owner_name, su.name AS sitter_name
             FROM kakiempa_v2_bookings b
             LEFT JOIN kakiempa_v2_users ou ON ou.id = b.owner_user_id
             LEFT JOIN kakiempa_v2_users su ON su.id = b.sitter_user_id
             ORDER BY b.created_at DESC
             LIMIT ?',
        );
        $stmt->bindValue(1, $limit, PDO::PARAM_INT);
        $stmt->execute();
    }

    $bookings = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        if (!is_array($row)) {
            continue;
        }
        $bookings[] = [
            'id' => (string) ($row['id'] ?? ''),
            'offer_id' => $row['offer_id'] !== null ? (string) $row['offer_id'] : null,
            'request_id' => $row['request_id'] !== null ? (string) $row['request_id'] : null,
            'owner_user_id' => $row['owner_user_id'] !== null ? (string) $row['owner_user_id'] : null,
            'owner_name' => (string) ($row['owner_name'] ?? ''),
            'sitter_user_id' => $row['sitter_user_id'] !== null ? (string) $row['sitter_user_id'] : null,
            'sitter_name' => (string) ($row['sitter_name'] ?? ''),
            'status' => (string) ($row['status'] ?? ''),
            'total_price' => (int) ($row['total_price'] ?? 0),
            'payment_amount' => (int) ($row['payment_amount'] ?? 0),
            'created_at' => (string) ($row['created_at'] ?? ''),
        ];
    }

    v2ApiRespondData([
        'bookings' => $bookings,
        'total' => count($bookings),
        'status_filter' => $status !== '' ? $status : null,
    ]);
}

/** @param array<string, mixed> $body */
function kakiempat_admin_v2_approve_sitter(array $body): void
{
    kakiempat_admin_v2_require_founder();
    $pdo = v2ApiPdo();

    $userId = (int) ($body['sitter_id'] ?? $body['user_id'] ?? 0);
    if ($userId < 1) {
        v2ApiFail('invalid_sitter_id', 'sitter_id wajib.', 400);
    }

    $stmt = $pdo->prepare(
        "SELECT status FROM kakiempa_v2_sitter_profiles WHERE user_id = ? LIMIT 1",
    );
    $stmt->execute([$userId]);
    $status = (string) ($stmt->fetchColumn() ?: '');
    if ($status === '') {
        v2ApiFail('sitter_not_found', 'Profil pengasuh tidak ditemukan.', 404);
    }
    if ($status === 'approved') {
        v2ApiRespondData([
            'sitter_id' => (string) $userId,
            'status' => 'approved',
            'message' => 'Pengasuh sudah disetujui sebelumnya.',
        ]);
        return;
    }

    $pdo->prepare(
        "UPDATE kakiempa_v2_sitter_profiles SET status = 'approved' WHERE user_id = ?",
    )->execute([$userId]);

    v2ApiRespondData([
        'sitter_id' => (string) $userId,
        'status' => 'approved',
        'message' => 'Pengasuh disetujui.',
    ]);
}

/** @param array<string, mixed> $body */
function kakiempat_admin_v2_reject_sitter(array $body): void
{
    kakiempat_admin_v2_require_founder();
    $pdo = v2ApiPdo();

    $userId = (int) ($body['sitter_id'] ?? $body['user_id'] ?? 0);
    if ($userId < 1) {
        v2ApiFail('invalid_sitter_id', 'sitter_id wajib.', 400);
    }

    $stmt = $pdo->prepare(
        "SELECT status FROM kakiempa_v2_sitter_profiles WHERE user_id = ? LIMIT 1",
    );
    $stmt->execute([$userId]);
    $status = (string) ($stmt->fetchColumn() ?: '');
    if ($status !== 'pending_verification') {
        v2ApiFail('invalid_status', 'Sitter tidak menunggu verifikasi.', 409);
    }

    $pdo->prepare(
        "UPDATE kakiempa_v2_sitter_profiles SET status = 'rejected' WHERE user_id = ?",
    )->execute([$userId]);

    v2ApiRespondData([
        'sitter_id' => (string) $userId,
        'status' => 'rejected',
        'message' => 'Pengasuh ditolak.',
    ]);
}

/** @param array<string, mixed> $body */
function kakiempat_admin_v2_approve_withdrawal(array $body): void
{
    kakiempat_admin_v2_require_founder();
    $pdo = v2ApiPdo();

    if (!v2ApiTableExists($pdo, 'kakiempa_v2_withdrawals')) {
        v2ApiFail('schema_missing', 'Tabel penarikan belum tersedia. Jalankan migrasi 015.', 503);
    }

    $withdrawalId = (int) ($body['withdrawal_id'] ?? 0);
    if ($withdrawalId < 1) {
        v2ApiFail('invalid_withdrawal_id', 'withdrawal_id wajib.', 400);
    }

    $pdo->beginTransaction();
    try {
        $stmt = $pdo->prepare(
            'SELECT id, user_id, amount, status FROM kakiempa_v2_withdrawals
             WHERE id = ? LIMIT 1 FOR UPDATE',
        );
        $stmt->execute([$withdrawalId]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!is_array($row)) {
            v2ApiFail('withdrawal_not_found', 'Permintaan penarikan tidak ditemukan.', 404);
        }
        if ((string) $row['status'] === 'completed') {
            $pdo->commit();
            v2ApiRespondData([
                'withdrawal_id' => (string) $withdrawalId,
                'status' => 'completed',
                'message' => 'Penarikan sudah diselesaikan sebelumnya.',
            ]);
            return;
        }
        if ((string) $row['status'] !== 'pending') {
            v2ApiFail('invalid_withdrawal_status', 'Penarikan tidak dalam status pending.', 409);
        }

        kakiempat_wallet_v2_deduct_for_withdrawal(
            $pdo,
            (int) ($row['user_id'] ?? 0),
            $withdrawalId,
            (int) ($row['amount'] ?? 0),
        );

        $pdo->prepare(
            "UPDATE kakiempa_v2_withdrawals
             SET status = 'completed', completed_at = NOW(6)
             WHERE id = ?",
        )->execute([$withdrawalId]);
        $pdo->commit();

        v2ApiRespondData([
            'withdrawal_id' => (string) $withdrawalId,
            'user_id' => (string) ($row['user_id'] ?? ''),
            'amount' => (int) ($row['amount'] ?? 0),
            'status' => 'completed',
            'message' => 'Penarikan disetujui.',
        ]);
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        throw $e;
    }
}

function kakiempat_admin_v2_list_pending_withdrawals(): void
{
    kakiempat_admin_v2_require_founder();
    $pdo = v2ApiPdo();

    if (!v2ApiTableExists($pdo, 'kakiempa_v2_withdrawals')) {
        v2ApiFail('schema_missing', 'Tabel penarikan belum tersedia. Jalankan migrasi 015.', 503);
    }

    $stmt = $pdo->query(
        "SELECT w.id, w.user_id, w.amount, w.status, w.created_at, w.completed_at,
                u.name AS user_name, u.whatsapp
         FROM kakiempa_v2_withdrawals w
         INNER JOIN kakiempa_v2_users u ON u.id = w.user_id
         WHERE w.status = 'pending'
         ORDER BY w.created_at ASC",
    );

    $items = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        if (!is_array($row)) {
            continue;
        }
        $items[] = kakiempat_admin_v2_format_withdrawal($row);
    }

    v2ApiRespondData(['withdrawals' => $items, 'total' => count($items)]);
}

/** @param array<string, mixed> $body */
function kakiempat_admin_v2_reject_withdrawal(array $body): void
{
    kakiempat_admin_v2_require_founder();
    $pdo = v2ApiPdo();

    if (!v2ApiTableExists($pdo, 'kakiempa_v2_withdrawals')) {
        v2ApiFail('schema_missing', 'Tabel penarikan belum tersedia. Jalankan migrasi 015.', 503);
    }

    $withdrawalId = (int) ($body['withdrawal_id'] ?? 0);
    if ($withdrawalId < 1) {
        v2ApiFail('invalid_withdrawal_id', 'withdrawal_id wajib.', 400);
    }

    $stmt = $pdo->prepare(
        'SELECT id, user_id, amount, status FROM kakiempa_v2_withdrawals WHERE id = ? LIMIT 1',
    );
    $stmt->execute([$withdrawalId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!is_array($row)) {
        v2ApiFail('withdrawal_not_found', 'Permintaan penarikan tidak ditemukan.', 404);
    }
    if ((string) ($row['status'] ?? '') !== 'pending') {
        v2ApiFail('invalid_withdrawal_status', 'Penarikan tidak dalam status pending.', 409);
    }

    $pdo->prepare(
        "UPDATE kakiempa_v2_withdrawals SET status = 'rejected', completed_at = NOW(6) WHERE id = ?",
    )->execute([$withdrawalId]);

    v2ApiRespondData([
        'withdrawal_id' => (string) $withdrawalId,
        'status' => 'rejected',
        'message' => 'Penarikan ditolak.',
    ]);
}

/** @param array<string, mixed> $row */
function kakiempat_admin_v2_format_withdrawal(array $row): array
{
    return [
        'id' => (string) ($row['id'] ?? ''),
        'user_id' => (string) ($row['user_id'] ?? ''),
        'user_name' => (string) ($row['user_name'] ?? ''),
        'phone' => (string) ($row['whatsapp'] ?? ''),
        'amount' => (int) ($row['amount'] ?? 0),
        'status' => (string) ($row['status'] ?? ''),
        'created_at' => (string) ($row['created_at'] ?? ''),
        'completed_at' => $row['completed_at'] !== null ? (string) $row['completed_at'] : null,
    ];
}

/** @param array<string, mixed> $row
 * @return array<string, mixed>
 */
function kakiempat_admin_v2_format_sitter(array $row): array
{
    $meta = [];
    if (!empty($row['profile_json'])) {
        $decoded = json_decode((string) $row['profile_json'], true);
        $meta = is_array($decoded) ? $decoded : [];
    }

    return [
        'sitter_id' => (string) ($row['user_id'] ?? ''),
        'user_id' => (string) ($row['user_id'] ?? ''),
        'name' => (string) ($row['display_name'] ?? $row['user_name'] ?? ''),
        'phone' => (string) ($row['whatsapp'] ?? ''),
        'address' => (string) ($row['address'] ?? ''),
        'bio' => (string) ($meta['bio'] ?? ''),
        'services' => $meta['services'] ?? [],
        'status' => (string) ($row['status'] ?? ''),
        'submitted_at' => (string) ($row['submitted_at'] ?? ''),
    ];
}
