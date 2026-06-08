<?php
declare(strict_types=1);

require_once __DIR__ . '/../v2_api_common.php';
require_once __DIR__ . '/kakiempat_service_v2.php';
require_once __DIR__ . '/kakiempat_sitter_v2.php';
require_once __DIR__ . '/kakiempat_platform_fee_v2.php';
require_once __DIR__ . '/kakiempat_event_notifications.php';

function kakiempat_booking_v2_normalize_status(string $status): string
{
    $compact = strtolower(str_replace(['_', '-'], '', trim($status)));

    return match ($compact) {
        'awaitingpayment' => 'awaiting_payment',
        'pendingverification' => 'pending_verification',
        'paymentrejected' => 'payment_rejected',
        'paid' => 'paid',
        default => strtolower(trim($status)),
    };
}

function kakiempat_booking_v2_status_is(string $actual, string $expected): bool
{
    return kakiempat_booking_v2_normalize_status($actual)
        === kakiempat_booking_v2_normalize_status($expected);
}

/** @param array<string, mixed> $formatted
 * @return array<string, mixed>
 */
function kakiempat_booking_v2_enrich_pets(PDO $pdo, array $formatted): array
{
    $petIds = $formatted['pet_ids'] ?? [];
    if (!is_array($petIds) || $petIds === []) {
        $formatted['pet_names'] = [];
        $formatted['pet_species'] = [];

        return $formatted;
    }

    $placeholders = implode(',', array_fill(0, count($petIds), '?'));
    $stmt = $pdo->prepare(
        "SELECT id, name, species FROM kakiempa_v2_pets WHERE id IN ({$placeholders})",
    );
    $stmt->execute(array_values($petIds));
    $namesById = [];
    $speciesById = [];
    while ($petRow = $stmt->fetch(PDO::FETCH_ASSOC)) {
        if (!is_array($petRow)) {
            continue;
        }
        $key = (string) ($petRow['id'] ?? '');
        $namesById[$key] = (string) ($petRow['name'] ?? '');
        $speciesById[$key] = (string) ($petRow['species'] ?? '');
    }

    $petNames = [];
    $petSpecies = [];
    foreach ($petIds as $petId) {
        $key = (string) $petId;
        if ($key === '') {
            continue;
        }
        if (isset($namesById[$key]) && $namesById[$key] !== '') {
            $petNames[] = $namesById[$key];
        }
        if (isset($speciesById[$key]) && $speciesById[$key] !== '') {
            $petSpecies[] = $speciesById[$key];
        }
    }
    $formatted['pet_names'] = $petNames;
    $formatted['pet_species'] = $petSpecies;

    return $formatted;
}

/** @return list<string> */
function kakiempat_booking_v2_cancellable_statuses(): array
{
    return [
        'pending',
        'awaiting_payment',
        'pending_verification',
        'paid',
        'confirmed',
        'en_route',
        'in_progress',
    ];
}

/** @param array<string, mixed> $body */
function kakiempat_booking_v2_create_request(array $body): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['owner', 'founder']);
    $pdo = v2ApiPdo();

    $serviceCode = trim((string) ($body['service_code'] ?? ''));
    if ($serviceCode === '' || !kakiempat_service_v2_is_valid_code($pdo, $serviceCode)) {
        v2ApiFail('invalid_service', 'Kode layanan tidak valid.', 400);
    }

    $scheduledRaw = trim((string) ($body['scheduled_at'] ?? ''));
    if ($scheduledRaw === '') {
        v2ApiFail('invalid_schedule', 'Jadwal layanan wajib diisi.', 400);
    }
    try {
        $scheduled = new DateTimeImmutable($scheduledRaw, new DateTimeZone('UTC'));
    } catch (Throwable) {
        v2ApiFail('invalid_schedule', 'Format jadwal tidak valid (ISO 8601).', 400);
    }

    $notes = trim((string) ($body['notes'] ?? ''));
    $totalPrice = (int) ($body['total_price'] ?? $body['payment_amount'] ?? 0);
    if ($totalPrice < 0) {
        v2ApiFail('invalid_amount', 'Tarif layanan tidak valid.', 400);
    }
    $paymentAmount = kakiempat_platform_fee_v2_owner_payment_amount($totalPrice);

    $petIds = kakiempat_booking_v2_parse_pet_ids($body);
    if ($petIds === []) {
        v2ApiFail('pets_required', 'Minimal satu hewan wajib dipilih.', 400);
    }
    kakiempat_booking_v2_assert_owner_pets($pdo, $auth['user_id'], $petIds);

    $petIdsJson = json_encode($petIds, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    $pdo->prepare(
        'INSERT INTO kakiempa_v2_requests
            (owner_user_id, status, service_code, scheduled_at, notes, pet_ids,
             total_price, payment_amount)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
    )->execute([
        $auth['user_id'],
        'open',
        $serviceCode,
        $scheduled->format('Y-m-d H:i:s'),
        $notes !== '' ? $notes : null,
        $petIdsJson,
        $totalPrice,
        $paymentAmount,
    ]);

    $requestId = (int) $pdo->lastInsertId();
    v2ApiRespondData([
        'request_id' => (string) $requestId,
        'status' => 'open',
        'message' => 'Permintaan berhasil dibuat.',
    ], 201);
}

function kakiempat_booking_v2_list_incoming_requests(): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['sitter']);
    $pdo = v2ApiPdo();
    kakiempat_sitter_v2_require_approved($pdo, $auth['user_id']);

    $serviceCodes = kakiempat_sitter_v2_service_codes($pdo, $auth['user_id']);
    if ($serviceCodes === []) {
        v2ApiRespondData(['requests' => [], 'total' => 0]);
        return;
    }

    $placeholders = implode(',', array_fill(0, count($serviceCodes), '?'));
    $stmt = $pdo->prepare(
        "SELECT r.id, r.owner_user_id, r.service_code, r.scheduled_at, r.notes,
                r.pet_ids, r.total_price, r.payment_amount, r.status, r.created_at,
                u.name AS owner_name
         FROM kakiempa_v2_requests r
         INNER JOIN kakiempa_v2_users u ON u.id = r.owner_user_id
         WHERE r.status = 'open' AND r.service_code IN ({$placeholders})
         ORDER BY r.created_at ASC",
    );
    $stmt->execute($serviceCodes);

    $requests = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $requests[] = kakiempat_booking_v2_format_request($row);
    }

    v2ApiRespondData(['requests' => $requests, 'total' => count($requests)]);
}

/** @param array<string, mixed> $body */
function kakiempat_booking_v2_accept_request(array $body): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['sitter']);
    $pdo = v2ApiPdo();
    kakiempat_sitter_v2_require_approved($pdo, $auth['user_id']);

    $requestId = (int) ($body['request_id'] ?? 0);
    if ($requestId < 1) {
        v2ApiFail('invalid_request_id', 'request_id wajib.', 400);
    }

    $pdo->beginTransaction();
    try {
        $stmt = $pdo->prepare(
            "SELECT id, owner_user_id, service_code, total_price, payment_amount, status
             FROM kakiempa_v2_requests WHERE id = ? FOR UPDATE",
        );
        $stmt->execute([$requestId]);
        $request = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!is_array($request)) {
            v2ApiFail('request_not_found', 'Permintaan tidak ditemukan.', 404);
        }
        if ((string) $request['status'] !== 'open') {
            v2ApiFail('request_not_open', 'Permintaan sudah tidak tersedia.', 409);
        }

        $serviceCodes = kakiempat_sitter_v2_service_codes($pdo, $auth['user_id']);
        $serviceCode = (string) ($request['service_code'] ?? '');
        if (!in_array($serviceCode, $serviceCodes, true)) {
            v2ApiFail('service_mismatch', 'Layanan tidak sesuai profil pengasuh.', 403);
        }

        $pdo->prepare(
            "UPDATE kakiempa_v2_requests SET status = 'matched' WHERE id = ?",
        )->execute([$requestId]);

        $pdo->prepare(
            'INSERT INTO kakiempa_v2_offers (request_id, sitter_user_id, status)
             VALUES (?, ?, ?)',
        )->execute([$requestId, $auth['user_id'], 'accepted']);
        $offerId = (int) $pdo->lastInsertId();

        $totalPrice = (int) ($request['total_price'] ?? 0);
        $paymentAmount = (int) ($request['payment_amount'] ?? 0);
        if ($totalPrice <= 0 && $paymentAmount > 0) {
            $totalPrice = kakiempat_platform_fee_v2_resolve_total_price(0, $paymentAmount);
        }
        if ($paymentAmount <= 0 && $totalPrice > 0) {
            $paymentAmount = kakiempat_platform_fee_v2_owner_payment_amount($totalPrice);
        }
        $bookingStatus = $paymentAmount > 0 ? 'awaiting_payment' : 'pending';

        $pdo->prepare(
            'INSERT INTO kakiempa_v2_bookings
                (offer_id, request_id, owner_user_id, sitter_user_id, status,
                 total_price, payment_amount)
             VALUES (?, ?, ?, ?, ?, ?, ?)',
        )->execute([
            $offerId,
            $requestId,
            (int) $request['owner_user_id'],
            $auth['user_id'],
            $bookingStatus,
            $totalPrice,
            $paymentAmount,
        ]);
        $bookingId = (int) $pdo->lastInsertId();

        $pdo->commit();
        v2ApiRespondData([
            'booking_id' => (string) $bookingId,
            'offer_id' => (string) $offerId,
            'status' => $bookingStatus,
            'message' => 'Permintaan diterima.',
        ]);
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        throw $e;
    }
}

/** @param array<string, mixed> $body */
function kakiempat_booking_v2_reject_request(array $body): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['sitter']);
    $pdo = v2ApiPdo();

    $requestId = (int) ($body['request_id'] ?? 0);
    if ($requestId < 1) {
        v2ApiFail('invalid_request_id', 'request_id wajib.', 400);
    }

    $pdo->prepare(
        'INSERT INTO kakiempa_v2_offers (request_id, sitter_user_id, status)
         VALUES (?, ?, ?)',
    )->execute([$requestId, $auth['user_id'], 'rejected']);

    v2ApiRespondData([
        'request_id' => (string) $requestId,
        'message' => 'Permintaan ditolak.',
    ]);
}

function kakiempat_booking_v2_get_booking(): void
{
    $auth = v2ApiRequireAuth();
    $pdo = v2ApiPdo();

    $bookingId = (int) ($_GET['booking_id'] ?? 0);
    if ($bookingId < 1) {
        v2ApiFail('invalid_booking_id', 'Parameter booking_id wajib.', 400);
    }

    $booking = kakiempat_booking_v2_fetch_booking($pdo, $bookingId);
    kakiempat_booking_v2_assert_can_view($auth, $booking);

    v2ApiRespondData(['booking' => kakiempat_booking_v2_format_booking($booking, $pdo)]);
}

/** @return list<array<string, mixed>> */
function kakiempat_booking_v2_fetch_owner_bookings(PDO $pdo, int $ownerUserId): array
{
    $stmt = $pdo->prepare(
        'SELECT b.*, r.service_code, r.scheduled_at, r.notes, r.pet_ids
         FROM kakiempa_v2_bookings b
         LEFT JOIN kakiempa_v2_requests r ON r.id = b.request_id
         WHERE b.owner_user_id = ?
         ORDER BY b.created_at DESC',
    );
    $stmt->execute([$ownerUserId]);

    $bookings = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        if (is_array($row)) {
            $bookings[] = kakiempat_booking_v2_format_booking($row, $pdo);
        }
    }

    return $bookings;
}

function kakiempat_booking_v2_list_my_bookings(): void
{
    $auth = v2ApiRequireAuth();
    $pdo = v2ApiPdo();

    if ($auth['role'] === 'owner' || $auth['role'] === 'founder') {
        $bookings = kakiempat_booking_v2_fetch_owner_bookings($pdo, $auth['user_id']);
    } elseif ($auth['role'] === 'sitter') {
        $stmt = $pdo->prepare(
            'SELECT b.*, r.service_code, r.scheduled_at, r.notes, r.pet_ids
             FROM kakiempa_v2_bookings b
             LEFT JOIN kakiempa_v2_requests r ON r.id = b.request_id
             WHERE b.sitter_user_id = ?
             ORDER BY b.created_at DESC',
        );
        $stmt->execute([$auth['user_id']]);
    } elseif (v2ApiIsAdmin($auth)) {
        $stmt = $pdo->query(
            'SELECT b.*, r.service_code, r.scheduled_at, r.notes, r.pet_ids
             FROM kakiempa_v2_bookings b
             LEFT JOIN kakiempa_v2_requests r ON r.id = b.request_id
             ORDER BY b.created_at DESC
             LIMIT 100',
        );
    } else {
        v2ApiFail('forbidden', 'Akses ditolak.', 403);
    }

    if (!isset($bookings)) {
        $bookings = [];
        while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
            $bookings[] = kakiempat_booking_v2_format_booking($row, $pdo);
        }
    }

    v2ApiRespondData(['bookings' => $bookings, 'total' => count($bookings)]);
}

function kakiempat_booking_v2_list_by_owner(): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['owner', 'founder']);
    $pdo = v2ApiPdo();

    $stmt = $pdo->prepare(
        'SELECT b.*, r.service_code, r.scheduled_at, r.notes, r.pet_ids
         FROM kakiempa_v2_bookings b
         LEFT JOIN kakiempa_v2_requests r ON r.id = b.request_id
         WHERE b.owner_user_id = ?
         ORDER BY b.created_at DESC',
    );
    $stmt->execute([$auth['user_id']]);

    $bookings = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $bookings[] = kakiempat_booking_v2_format_booking($row, $pdo);
    }

    v2ApiRespondData(['bookings' => $bookings, 'total' => count($bookings)]);
}

function kakiempat_booking_v2_list_by_sitter(): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['sitter']);
    $pdo = v2ApiPdo();

    $stmt = $pdo->prepare(
        'SELECT b.*, r.service_code, r.scheduled_at, r.notes, r.pet_ids
         FROM kakiempa_v2_bookings b
         LEFT JOIN kakiempa_v2_requests r ON r.id = b.request_id
         WHERE b.sitter_user_id = ?
         ORDER BY b.created_at DESC',
    );
    $stmt->execute([$auth['user_id']]);

    $bookings = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        $bookings[] = kakiempat_booking_v2_format_booking($row, $pdo);
    }

    v2ApiRespondData(['bookings' => $bookings, 'total' => count($bookings)]);
}

/** @param array<string, mixed> $body */
function kakiempat_booking_v2_parse_pet_ids(array $body): array
{
    $ids = [];
    $raw = $body['pet_ids'] ?? null;
    if (is_array($raw)) {
        foreach ($raw as $item) {
            $id = is_array($item)
                ? trim((string) ($item['id'] ?? $item['pet_id'] ?? ''))
                : trim((string) $item);
            if ($id !== '' && ctype_digit($id)) {
                $ids[] = (int) $id;
            }
        }
    }
    $single = trim((string) ($body['pet_id'] ?? ''));
    if ($single !== '' && ctype_digit($single)) {
        $ids[] = (int) $single;
    }
    return array_values(array_unique($ids));
}

/** @param list<int> $petIds */
function kakiempat_booking_v2_assert_owner_pets(PDO $pdo, int $ownerId, array $petIds): void
{
    $placeholders = implode(',', array_fill(0, count($petIds), '?'));
    $stmt = $pdo->prepare(
        "SELECT COUNT(*) FROM kakiempa_v2_pets
         WHERE owner_user_id = ? AND id IN ({$placeholders})",
    );
    $stmt->execute(array_merge([$ownerId], $petIds));
    if ((int) $stmt->fetchColumn() !== count($petIds)) {
        v2ApiFail('invalid_pets', 'Satu atau lebih hewan tidak valid.', 400);
    }
}

/** @return array<string, mixed> */
function kakiempat_booking_v2_fetch_booking(PDO $pdo, int $bookingId): array
{
    $stmt = $pdo->prepare(
        'SELECT b.*, r.service_code, r.scheduled_at, r.notes, r.pet_ids
         FROM kakiempa_v2_bookings b
         LEFT JOIN kakiempa_v2_requests r ON r.id = b.request_id
         WHERE b.id = ? LIMIT 1',
    );
    $stmt->execute([$bookingId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!is_array($row)) {
        v2ApiFail('booking_not_found', 'Booking tidak ditemukan.', 404);
    }
    return $row;
}

/** @param array<string, mixed> $auth */
function kakiempat_booking_v2_assert_can_view(array $auth, array $booking): void
{
    if (v2ApiIsAdmin($auth)) {
        return;
    }
    $userId = $auth['user_id'];
    $ownerId = (int) ($booking['owner_user_id'] ?? 0);
    $sitterId = (int) ($booking['sitter_user_id'] ?? 0);
    if ($userId !== $ownerId && $userId !== $sitterId) {
        v2ApiFail('forbidden', 'Anda tidak memiliki akses ke booking ini.', 403);
    }
}

/** @param array<string, mixed> $row */
function kakiempat_booking_v2_format_request(array $row): array
{
    $petIds = [];
    if (isset($row['pet_ids']) && $row['pet_ids'] !== null && $row['pet_ids'] !== '') {
        $decoded = json_decode((string) $row['pet_ids'], true);
        if (is_array($decoded)) {
            $petIds = array_values(array_map('strval', $decoded));
        }
    }

    return [
        'id' => (string) ($row['id'] ?? ''),
        'owner_user_id' => (string) ($row['owner_user_id'] ?? ''),
        'owner_name' => (string) ($row['owner_name'] ?? ''),
        'service_code' => (string) ($row['service_code'] ?? ''),
        'scheduled_at' => (string) ($row['scheduled_at'] ?? ''),
        'notes' => (string) ($row['notes'] ?? ''),
        'pet_ids' => $petIds,
        'total_price' => (int) ($row['total_price'] ?? 0),
        'payment_amount' => (int) ($row['payment_amount'] ?? 0),
        'status' => kakiempat_booking_v2_normalize_status((string) ($row['status'] ?? '')),
        'created_at' => (string) ($row['created_at'] ?? ''),
    ];
}

/** @param array<string, mixed> $row */
function kakiempat_booking_v2_format_booking(array $row, ?PDO $pdo = null): array
{
    $petIds = [];
    if (isset($row['pet_ids']) && $row['pet_ids'] !== null && $row['pet_ids'] !== '') {
        $decoded = json_decode((string) $row['pet_ids'], true);
        if (is_array($decoded)) {
            $petIds = array_values(array_map('strval', $decoded));
        }
    }

    $formatted = [
        'id' => (string) ($row['id'] ?? ''),
        'offer_id' => isset($row['offer_id']) ? (string) $row['offer_id'] : null,
        'request_id' => isset($row['request_id']) ? (string) $row['request_id'] : null,
        'owner_user_id' => isset($row['owner_user_id']) ? (string) $row['owner_user_id'] : null,
        'sitter_user_id' => isset($row['sitter_user_id']) ? (string) $row['sitter_user_id'] : null,
        'status' => kakiempat_booking_v2_normalize_status((string) ($row['status'] ?? '')),
        'total_price' => (int) ($row['total_price'] ?? 0),
        'payment_amount' => (int) ($row['payment_amount'] ?? 0),
        'service_code' => (string) ($row['service_code'] ?? ''),
        'scheduled_at' => (string) ($row['scheduled_at'] ?? ''),
        'notes' => (string) ($row['notes'] ?? ''),
        'pet_ids' => $petIds,
        'created_at' => (string) ($row['created_at'] ?? ''),
    ];

    if ($pdo !== null && $petIds !== []) {
        return kakiempat_booking_v2_enrich_pets($pdo, $formatted);
    }

    $formatted['pet_names'] = [];
    $formatted['pet_species'] = [];

    return $formatted;
}

/** @param array<string, mixed> $body */
function kakiempat_booking_v2_sitter_confirm(array $body): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['sitter', 'founder']);
    $pdo = v2ApiPdo();

    $bookingId = (int) ($body['booking_id'] ?? 0);
    if ($bookingId < 1) {
        v2ApiFail('invalid_booking_id', 'booking_id wajib.', 400);
    }

    $pdo->beginTransaction();
    try {
        $booking = kakiempat_booking_v2_fetch_booking_for_update($pdo, $bookingId);
        kakiempat_booking_v2_assert_sitter($auth, $booking);

        $status = kakiempat_booking_v2_normalize_status((string) ($booking['status'] ?? ''));
        $allowed = ['paid', 'pending'];
        if (!in_array($status, $allowed, true)) {
            v2ApiFail(
                'invalid_booking_status',
                'Booking hanya dapat dikonfirmasi setelah pembayaran (PAID) atau tanpa biaya (pending).',
                409,
            );
        }
        if ($status === 'pending' && (int) ($booking['payment_amount'] ?? 0) > 0) {
            v2ApiFail(
                'payment_required',
                'Pembayaran belum selesai. Booking belum dapat dikonfirmasi.',
                409,
            );
        }

        $pdo->prepare("UPDATE kakiempa_v2_bookings SET status = 'confirmed' WHERE id = ?")
            ->execute([$bookingId]);
        $pdo->commit();

        v2ApiRespondData([
            'booking_id' => (string) $bookingId,
            'status' => 'confirmed',
            'message' => 'Booking dikonfirmasi.',
        ]);
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        throw $e;
    }
}

/** @param array<string, mixed> $body */
function kakiempat_booking_v2_sitter_en_route(array $body): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['sitter', 'founder']);
    $pdo = v2ApiPdo();

    $bookingId = (int) ($body['booking_id'] ?? 0);
    if ($bookingId < 1) {
        v2ApiFail('invalid_booking_id', 'booking_id wajib.', 400);
    }

    $pdo->beginTransaction();
    try {
        $booking = kakiempat_booking_v2_fetch_booking_for_update($pdo, $bookingId);
        kakiempat_booking_v2_assert_sitter($auth, $booking);

        if ((string) ($booking['status'] ?? '') !== 'confirmed') {
            v2ApiFail(
                'invalid_booking_status',
                'Booking harus berstatus confirmed sebelum berangkat.',
                409,
            );
        }

        $pdo->prepare("UPDATE kakiempa_v2_bookings SET status = 'en_route' WHERE id = ?")
            ->execute([$bookingId]);
        $pdo->commit();

        v2ApiRespondData([
            'booking_id' => (string) $bookingId,
            'status' => 'en_route',
            'message' => 'Status diperbarui: dalam perjalanan.',
        ]);
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        throw $e;
    }
}

/** @param array<string, mixed> $body */
function kakiempat_booking_v2_start_booking(array $body): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['sitter', 'founder']);
    $pdo = v2ApiPdo();

    $bookingId = (int) ($body['booking_id'] ?? 0);
    if ($bookingId < 1) {
        v2ApiFail('invalid_booking_id', 'booking_id wajib.', 400);
    }

    $pdo->beginTransaction();
    try {
        $booking = kakiempat_booking_v2_fetch_booking_for_update($pdo, $bookingId);
        kakiempat_booking_v2_assert_sitter($auth, $booking);

        if ((string) ($booking['status'] ?? '') !== 'en_route') {
            v2ApiFail(
                'invalid_booking_status',
                'Booking harus berstatus en_route sebelum dimulai.',
                409,
            );
        }

        $pdo->prepare("UPDATE kakiempa_v2_bookings SET status = 'in_progress' WHERE id = ?")
            ->execute([$bookingId]);
        $pdo->commit();

        v2ApiRespondData([
            'booking_id' => (string) $bookingId,
            'status' => 'in_progress',
            'message' => 'Layanan dimulai.',
        ]);
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        throw $e;
    }
}

/** @param array<string, mixed> $body */
function kakiempat_booking_v2_complete_booking(array $body): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['sitter', 'founder']);
    $pdo = v2ApiPdo();

    $bookingId = (int) ($body['booking_id'] ?? 0);
    if ($bookingId < 1) {
        v2ApiFail('invalid_booking_id', 'booking_id wajib.', 400);
    }

    $pdo->beginTransaction();
    try {
        $booking = kakiempat_booking_v2_fetch_booking_for_update($pdo, $bookingId);
        kakiempat_booking_v2_assert_sitter($auth, $booking);

        if ((string) ($booking['status'] ?? '') !== 'in_progress') {
            v2ApiFail(
                'invalid_booking_status',
                'Booking harus berstatus in_progress sebelum diselesaikan.',
                409,
            );
        }

        $walletBreakdown = kakiempat_booking_v2_credit_sitter_wallet($pdo, $bookingId, $booking);

        $pdo->prepare("UPDATE kakiempa_v2_bookings SET status = 'completed' WHERE id = ?")
            ->execute([$bookingId]);

        kakiempat_event_notifications_booking_completed(
            $pdo,
            (int) ($booking['owner_user_id'] ?? 0),
            (int) ($booking['sitter_user_id'] ?? 0),
            $bookingId,
        );

        require_once __DIR__ . '/kakiempat_loyalty_v2.php';
        kakiempat_loyalty_v2_award_booking_complete(
            $pdo,
            (int) ($booking['owner_user_id'] ?? 0),
            $bookingId,
        );

        require_once __DIR__ . '/kakiempat_business_v2.php';
        kakiempat_business_v2_check_achievements(
            $pdo,
            (int) ($booking['sitter_user_id'] ?? 0),
        );

        $pdo->commit();

        if (v2ApiTableExists($pdo, 'kakiempa_v2_platform_events')) {
            require_once __DIR__ . '/kakiempat_platform_v2.php';
            kakiempat_platform_v2_emit_event($pdo, 'booking.completed', [
                'booking_id' => (string) $bookingId,
                'owner_user_id' => (string) ($booking['owner_user_id'] ?? ''),
                'sitter_user_id' => (string) ($booking['sitter_user_id'] ?? ''),
                'service_code' => (string) ($booking['service_code'] ?? ''),
                'payment_amount' => (int) ($booking['payment_amount'] ?? 0),
            ]);
        }

        v2ApiRespondData([
            'booking_id' => (string) $bookingId,
            'status' => 'completed',
            'wallet' => $walletBreakdown,
            'message' => 'Layanan selesai. Pendapatan dicatat di wallet.',
        ]);
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        throw $e;
    }
}

/** @param array<string, mixed> $body */
function kakiempat_booking_v2_cancel_booking(array $body): void
{
    $auth = v2ApiRequireAuth();
    $pdo = v2ApiPdo();

    $bookingId = (int) ($body['booking_id'] ?? 0);
    if ($bookingId < 1) {
        v2ApiFail('invalid_booking_id', 'booking_id wajib.', 400);
    }

    $pdo->beginTransaction();
    try {
        $booking = kakiempat_booking_v2_fetch_booking_for_update($pdo, $bookingId);
        kakiempat_booking_v2_assert_can_cancel($auth, $booking);

        $status = kakiempat_booking_v2_normalize_status((string) ($booking['status'] ?? ''));
        if (!in_array($status, kakiempat_booking_v2_cancellable_statuses(), true)) {
            v2ApiFail(
                'invalid_booking_status',
                'Booking tidak dapat dibatalkan pada status saat ini.',
                409,
            );
        }

        $pdo->prepare("UPDATE kakiempa_v2_bookings SET status = 'cancelled' WHERE id = ?")
            ->execute([$bookingId]);

        $requestId = (int) ($booking['request_id'] ?? 0);
        if ($requestId > 0) {
            $pdo->prepare(
                "UPDATE kakiempa_v2_requests SET status = 'cancelled' WHERE id = ? AND status <> 'closed'",
            )->execute([$requestId]);
        }

        kakiempat_event_notifications_booking_cancelled(
            $pdo,
            $booking,
            $bookingId,
            $auth['user_id'],
        );

        $pdo->commit();
        v2ApiRespondData([
            'booking_id' => (string) $bookingId,
            'status' => 'cancelled',
            'message' => 'Booking dibatalkan.',
        ]);
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        throw $e;
    }
}

/** @return array<string, mixed> */
function kakiempat_booking_v2_fetch_booking_for_update(PDO $pdo, int $bookingId): array
{
    $stmt = $pdo->prepare(
        'SELECT b.*, r.service_code, r.scheduled_at, r.notes, r.pet_ids
         FROM kakiempa_v2_bookings b
         LEFT JOIN kakiempa_v2_requests r ON r.id = b.request_id
         WHERE b.id = ? LIMIT 1 FOR UPDATE',
    );
    $stmt->execute([$bookingId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!is_array($row)) {
        v2ApiFail('booking_not_found', 'Booking tidak ditemukan.', 404);
    }

    return $row;
}

/** @param array<string, mixed> $auth
 * @param array<string, mixed> $booking
 */
function kakiempat_booking_v2_assert_sitter(array $auth, array $booking): void
{
    $sitterId = (int) ($booking['sitter_user_id'] ?? 0);
    if ($auth['role'] !== 'founder' && $auth['user_id'] !== $sitterId) {
        v2ApiFail('forbidden', 'Hanya pengasuh terkait yang dapat melakukan aksi ini.', 403);
    }
}

/** @param array<string, mixed> $auth
 * @param array<string, mixed> $booking
 */
function kakiempat_booking_v2_assert_can_cancel(array $auth, array $booking): void
{
    if (v2ApiIsAdmin($auth)) {
        return;
    }
    $userId = $auth['user_id'];
    $ownerId = (int) ($booking['owner_user_id'] ?? 0);
    $sitterId = (int) ($booking['sitter_user_id'] ?? 0);
    if ($userId !== $ownerId && $userId !== $sitterId) {
        v2ApiFail('forbidden', 'Hanya pemilik atau pengasuh yang dapat membatalkan booking.', 403);
    }
}

/**
 * Catat pendapatan sitter & potongan platform ke wallet_ledger — idempoten.
 *
 * @param array<string, mixed> $booking
 * @return array<string, mixed>
 */
function kakiempat_booking_v2_credit_sitter_wallet(
    PDO $pdo,
    int $bookingId,
    array $booking,
): array {
    $rates = kakiempat_platform_fee_v2_rates();
    $sitterId = (int) ($booking['sitter_user_id'] ?? 0);
    $paymentAmount = (int) ($booking['payment_amount'] ?? 0);
    $totalPrice = kakiempat_platform_fee_v2_resolve_total_price(
        (int) ($booking['total_price'] ?? 0),
        $paymentAmount,
    );
    $platformFeeSitter = kakiempat_platform_fee_v2_sitter_fee($totalPrice);
    $sitterNet = kakiempat_platform_fee_v2_sitter_net($totalPrice);

    if ($sitterId > 0 && $totalPrice > 0) {
        if (!kakiempat_platform_fee_v2_ledger_exists($pdo, $bookingId, 'income')) {
            kakiempat_platform_fee_v2_insert_ledger(
                $pdo,
                $sitterId,
                $bookingId,
                $totalPrice,
                'income',
                sprintf('Pendapatan dari booking #%d', $bookingId),
            );
        }
        if (!kakiempat_platform_fee_v2_ledger_exists($pdo, $bookingId, 'platform_fee')) {
            kakiempat_platform_fee_v2_insert_ledger(
                $pdo,
                $sitterId,
                $bookingId,
                -$platformFeeSitter,
                'platform_fee',
                sprintf(
                    'Biaya platform %d%%',
                    (int) round($rates['sitter'] * 100),
                ),
            );
        }
    }

    if ($totalPrice > 0 && (int) ($booking['total_price'] ?? 0) === 0) {
        $pdo->prepare('UPDATE kakiempa_v2_bookings SET total_price = ? WHERE id = ?')
            ->execute([$totalPrice, $bookingId]);
    }

    return [
        'total_price' => $totalPrice,
        'platform_fee_sitter' => $platformFeeSitter,
        'platform_fee_sitter_percent' => $rates['sitter'],
        'sitter_net' => $sitterNet,
    ];
}
