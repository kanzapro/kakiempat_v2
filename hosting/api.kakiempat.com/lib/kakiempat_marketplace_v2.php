<?php
declare(strict_types=1);

require_once __DIR__ . '/../v2_api_common.php';
require_once __DIR__ . '/kakiempat_booking_v2.php';
require_once __DIR__ . '/kakiempat_service_v2.php';
require_once __DIR__ . '/kakiempat_sitter_v2.php';
require_once __DIR__ . '/kakiempat_platform_fee_v2.php';
require_once __DIR__ . '/kakiempat_event_notifications.php';
require_once __DIR__ . '/kakiempat_geo_v2.php';

/** @param array<string, mixed> $body */
function kakiempat_marketplace_v2_create_request(array $body): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['owner', 'founder']);
    $pdo = v2ApiPdo();

    $serviceType = trim((string) ($body['service_type'] ?? $body['service_code'] ?? ''));
    if ($serviceType === '' || !kakiempat_service_v2_is_valid_code($pdo, $serviceType)) {
        v2ApiFail('invalid_service', 'Jenis layanan tidak valid.', 400);
    }

    $dateLabel = trim((string) ($body['date_label'] ?? ''));
    $timeRange = trim((string) ($body['time_range'] ?? ''));
    if ($dateLabel === '') {
        v2ApiFail('invalid_date', 'Tanggal layanan wajib diisi.', 400);
    }
    if ($timeRange === '') {
        v2ApiFail('invalid_time', 'Rentang waktu wajib diisi.', 400);
    }

    $location = kakiempat_marketplace_v2_parse_location($body);
    if ($location['address'] === '') {
        v2ApiFail('invalid_location', 'Lokasi wajib diisi.', 400);
    }

    $notes = trim((string) ($body['notes'] ?? ''));
    $totalPrice = (int) ($body['price'] ?? $body['total_price'] ?? 0);
    if ($totalPrice < 0) {
        v2ApiFail('invalid_price', 'Harga tidak valid.', 400);
    }
    $paymentAmount = kakiempat_platform_fee_v2_owner_payment_amount($totalPrice);

    $petIds = kakiempat_marketplace_v2_parse_pets($body);
    if ($petIds === []) {
        v2ApiFail('pets_required', 'Minimal satu hewan wajib dipilih.', 400);
    }
    kakiempat_booking_v2_assert_owner_pets($pdo, $auth['user_id'], $petIds);

    $petIdsJson = json_encode($petIds, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    $locationJson = json_encode($location, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);

    $hasDateLabel = v2ApiColumnExists($pdo, 'kakiempa_v2_requests', 'date_label');
    $hasLocation = v2ApiColumnExists($pdo, 'kakiempa_v2_requests', 'location_json');

    $hasGeoCols = kakiempat_geo_v2_has_indexed_coords($pdo, 'kakiempa_v2_requests');

    if ($hasDateLabel && $hasLocation) {
        if ($hasGeoCols) {
            $pdo->prepare(
                'INSERT INTO kakiempa_v2_requests
                    (owner_user_id, status, service_code, date_label, time_range, location_json,
                     latitude, longitude, notes, pet_ids, total_price, payment_amount)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            )->execute([
                $auth['user_id'],
                'open',
                $serviceType,
                $dateLabel,
                $timeRange,
                $locationJson,
                $location['latitude'],
                $location['longitude'],
                $notes !== '' ? $notes : null,
                $petIdsJson,
                $totalPrice,
                $paymentAmount,
            ]);
        } else {
            $pdo->prepare(
                'INSERT INTO kakiempa_v2_requests
                    (owner_user_id, status, service_code, date_label, time_range, location_json,
                     notes, pet_ids, total_price, payment_amount)
                 VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)',
            )->execute([
                $auth['user_id'],
                'open',
                $serviceType,
                $dateLabel,
                $timeRange,
                $locationJson,
                $notes !== '' ? $notes : null,
                $petIdsJson,
                $totalPrice,
                $paymentAmount,
            ]);
        }
    } else {
        $pdo->prepare(
            'INSERT INTO kakiempa_v2_requests
                (owner_user_id, status, service_code, notes, pet_ids, total_price, payment_amount)
             VALUES (?, ?, ?, ?, ?, ?, ?)',
        )->execute([
            $auth['user_id'],
            'open',
            $serviceType,
            $notes !== '' ? $notes : null,
            $petIdsJson,
            $totalPrice,
            $paymentAmount,
        ]);
    }

    $requestId = (int) $pdo->lastInsertId();

    $response = [
        'request_id' => (string) $requestId,
        'status' => 'open',
        'message' => 'Permintaan marketplace berhasil dibuat.',
        'radius_km' => kakiempat_marketplace_v2_broadcast_radius_km(),
    ];
    if ($location['latitude'] !== null && $location['longitude'] !== null) {
        $response['sitter_count_in_radius'] = kakiempat_marketplace_v2_count_sitters_in_radius(
            $pdo,
            (float) $location['latitude'],
            (float) $location['longitude'],
            $serviceType,
        );
    }

    v2ApiRespondData($response, 201);
}

function kakiempat_marketplace_v2_list_requests(): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['sitter', 'founder']);
    $pdo = v2ApiPdo();
    kakiempat_sitter_v2_require_approved($pdo, $auth['user_id']);

    $pool = strtolower(trim((string) ($_GET['pool'] ?? 'open')));
    $serviceType = trim((string) ($_GET['service_type'] ?? ''));
    $radiusKm = $_GET['radius_km'] ?? null;
    $radius = is_numeric($radiusKm) ? (float) $radiusKm : null;

    $serviceCodes = kakiempat_sitter_v2_service_codes($pdo, $auth['user_id']);
    if ($serviceCodes === []) {
        v2ApiRespondData([
            'requests' => [],
            'total' => 0,
            'radius_km' => kakiempat_marketplace_v2_broadcast_radius_km(),
        ]);
        return;
    }

    if (!kakiempat_sitter_v2_is_available($pdo, $auth['user_id'])) {
        v2ApiRespondData([
            'requests' => [],
            'total' => 0,
            'radius_km' => kakiempat_marketplace_v2_broadcast_radius_km(),
            'availability_off' => true,
        ]);
        return;
    }

    if ($serviceType !== '') {
        if (!in_array($serviceType, $serviceCodes, true)) {
            v2ApiRespondData([
                'requests' => [],
                'total' => 0,
                'radius_km' => kakiempat_marketplace_v2_broadcast_radius_km(),
            ]);
            return;
        }
        $serviceCodes = [$serviceType];
    }

    $sitterCoords = kakiempat_marketplace_v2_resolve_sitter_coordinates($pdo, $auth['user_id']);
    $useSpatial = $sitterCoords !== null;
    if ($useSpatial && ($radius === null || $radius <= 0)) {
        $radius = kakiempat_marketplace_v2_broadcast_radius_km();
    }

    $statusFilter = $pool === 'open' ? 'open' : $pool;
    $placeholders = implode(',', array_fill(0, count($serviceCodes), '?'));
    $params = array_merge([$statusFilter], $serviceCodes);

    $extraCols = '';
    if (v2ApiColumnExists($pdo, 'kakiempa_v2_requests', 'date_label')) {
        $extraCols .= ', r.date_label, r.time_range';
    }
    if (v2ApiColumnExists($pdo, 'kakiempa_v2_requests', 'location_json')) {
        $extraCols .= ', r.location_json';
    }

    $reqCoords = kakiempat_geo_v2_resolve_coord_sql(
        $pdo,
        'kakiempa_v2_requests',
        'r',
        'location_json',
    );
    $reqLatSql = $reqCoords['lat_sql'];
    $reqLngSql = $reqCoords['lng_sql'];

    if ($useSpatial && $radius !== null && $radius > 0) {
        $bbox = kakiempat_geo_v2_bounding_box(
            $sitterCoords['latitude'],
            $sitterCoords['longitude'],
            $radius,
        );
        $distanceSql = kakiempat_geo_v2_sql_haversine_km(
            $reqLatSql,
            $reqLngSql,
            '?',
            '?',
            '?',
        );
        $bboxSql = $reqCoords['use_bbox']
            ? ' AND r.latitude BETWEEN ? AND ? AND r.longitude BETWEEN ? AND ?'
            : '';
        $sql = "SELECT r.id, r.owner_user_id, r.service_code, r.scheduled_at, r.notes,
                       r.pet_ids, r.total_price, r.payment_amount, r.status, r.created_at,
                       u.name AS owner_name{$extraCols},
                       {$distanceSql} AS distance_km
                FROM kakiempa_v2_requests r
                INNER JOIN kakiempa_v2_users u ON u.id = r.owner_user_id
                WHERE r.status = ? AND r.service_code IN ({$placeholders})
                  AND {$reqLatSql} IS NOT NULL AND {$reqLngSql} IS NOT NULL{$bboxSql}
                HAVING distance_km <= ?
                ORDER BY distance_km ASC";
        $bboxParams = $reqCoords['use_bbox']
            ? [$bbox['min_lat'], $bbox['max_lat'], $bbox['min_lng'], $bbox['max_lng']]
            : [];
        $params = array_merge(
            [
                $sitterCoords['latitude'],
                $sitterCoords['longitude'],
                $sitterCoords['latitude'],
            ],
            $params,
            $bboxParams,
            [$radius],
        );
    } else {
        $sql = "SELECT r.id, r.owner_user_id, r.service_code, r.scheduled_at, r.notes,
                       r.pet_ids, r.total_price, r.payment_amount, r.status, r.created_at,
                       u.name AS owner_name{$extraCols}
                FROM kakiempa_v2_requests r
                INNER JOIN kakiempa_v2_users u ON u.id = r.owner_user_id
                WHERE r.status = ? AND r.service_code IN ({$placeholders})
                ORDER BY r.created_at DESC";
    }

    $stmt = $pdo->prepare($sql);
    $stmt->execute($params);

    $requests = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        if (!is_array($row)) {
            continue;
        }
        if (isset($row['distance_km'])) {
            $row['distance_km'] = round((float) $row['distance_km'], 2);
        }
        $requests[] = kakiempat_marketplace_v2_format_request($row);
    }

    v2ApiRespondData([
        'requests' => $requests,
        'total' => count($requests),
        'radius_km' => $useSpatial ? $radius : null,
        'spatial_filter' => $useSpatial,
    ]);
}

function kakiempat_marketplace_v2_estimate_broadcast(): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['owner', 'founder']);
    $pdo = v2ApiPdo();

    $serviceType = trim((string) ($_GET['service_type'] ?? $_GET['service_code'] ?? ''));
    if ($serviceType === '' || !kakiempat_service_v2_is_valid_code($pdo, $serviceType)) {
        v2ApiFail('invalid_service', 'Jenis layanan tidak valid.', 400);
    }

    $coords = kakiempat_marketplace_v2_parse_query_coordinates();
    if ($coords === null) {
        v2ApiFail('coordinates_required', 'Latitude dan longitude wajib untuk estimasi broadcast.', 400);
    }

    $radiusKm = $_GET['radius_km'] ?? null;
    $radius = is_numeric($radiusKm) && (float) $radiusKm > 0
        ? (float) $radiusKm
        : kakiempat_marketplace_v2_broadcast_radius_km();

    v2ApiRespondData([
        'sitter_count_in_radius' => kakiempat_marketplace_v2_count_sitters_in_radius(
            $pdo,
            $coords['latitude'],
            $coords['longitude'],
            $serviceType,
            $radius,
        ),
        'radius_km' => $radius,
    ]);
}

/** @param array<string, mixed> $body */
function kakiempat_marketplace_v2_create_offer(array $body): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['sitter', 'founder']);
    $pdo = v2ApiPdo();
    kakiempat_sitter_v2_require_approved($pdo, $auth['user_id']);

    $requestId = (int) ($body['request_id'] ?? 0);
    if ($requestId < 1) {
        v2ApiFail('invalid_request_id', 'request_id wajib.', 400);
    }

    $price = (int) ($body['price'] ?? 0);
    if ($price < 0) {
        v2ApiFail('invalid_price', 'Harga penawaran tidak valid.', 400);
    }
    $message = trim((string) ($body['message'] ?? ''));

    $stmt = $pdo->prepare(
        "SELECT id, owner_user_id, service_code, status
         FROM kakiempa_v2_requests WHERE id = ? LIMIT 1",
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

    $dupStmt = $pdo->prepare(
        "SELECT id FROM kakiempa_v2_offers
         WHERE request_id = ? AND sitter_user_id = ? AND status = 'pending' LIMIT 1",
    );
    $dupStmt->execute([$requestId, $auth['user_id']]);
    if ($dupStmt->fetchColumn()) {
        v2ApiFail('offer_exists', 'Anda sudah mengirim penawaran untuk permintaan ini.', 409);
    }

    $hasOfferPrice = v2ApiColumnExists($pdo, 'kakiempa_v2_offers', 'price');
    if ($hasOfferPrice) {
        $pdo->prepare(
            'INSERT INTO kakiempa_v2_offers (request_id, sitter_user_id, price, message, status)
             VALUES (?, ?, ?, ?, ?)',
        )->execute([
            $requestId,
            $auth['user_id'],
            $price,
            $message !== '' ? $message : null,
            'pending',
        ]);
    } else {
        $pdo->prepare(
            'INSERT INTO kakiempa_v2_offers (request_id, sitter_user_id, status)
             VALUES (?, ?, ?)',
        )->execute([$requestId, $auth['user_id'], 'pending']);
    }

    $offerId = (int) $pdo->lastInsertId();
    kakiempat_event_notifications_offer_received(
        $pdo,
        (int) $request['owner_user_id'],
        $requestId,
        $offerId,
        $auth['user_id'],
    );
    v2ApiRespondData([
        'offer_id' => (string) $offerId,
        'request_id' => (string) $requestId,
        'status' => 'pending',
        'message' => 'Penawaran berhasil dikirim.',
    ], 201);
}

/** @param array<string, mixed> $body */
function kakiempat_marketplace_v2_accept_offer(array $body): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['owner', 'founder']);
    $pdo = v2ApiPdo();

    $offerId = (int) ($body['offer_id'] ?? 0);
    if ($offerId < 1) {
        v2ApiFail('invalid_offer_id', 'offer_id wajib.', 400);
    }

    $pdo->beginTransaction();
    try {
        $offerStmt = $pdo->prepare(
            'SELECT o.id, o.request_id, o.sitter_user_id, o.status, o.price,
                    r.owner_user_id, r.service_code, r.status AS request_status,
                    r.total_price, r.payment_amount
             FROM kakiempa_v2_offers o
             INNER JOIN kakiempa_v2_requests r ON r.id = o.request_id
             WHERE o.id = ? LIMIT 1 FOR UPDATE',
        );
        $offerStmt->execute([$offerId]);
        $offer = $offerStmt->fetch(PDO::FETCH_ASSOC);
        if (!is_array($offer)) {
            v2ApiFail('offer_not_found', 'Penawaran tidak ditemukan.', 404);
        }

        if ((int) $offer['owner_user_id'] !== $auth['user_id']) {
            v2ApiFail('forbidden', 'Hanya pemilik permintaan yang dapat menerima penawaran.', 403);
        }
        if ((string) $offer['status'] !== 'pending') {
            v2ApiFail('offer_not_pending', 'Penawaran sudah tidak dapat diterima.', 409);
        }
        if ((string) $offer['request_status'] !== 'open') {
            v2ApiFail('request_not_open', 'Permintaan sudah tidak tersedia.', 409);
        }

        $totalPrice = (int) ($offer['price'] ?? 0);
        if ($totalPrice <= 0) {
            $totalPrice = (int) ($offer['total_price'] ?? 0);
        }
        $paymentAmount = kakiempat_platform_fee_v2_owner_payment_amount($totalPrice);
        if ($totalPrice <= 0 && (int) ($offer['payment_amount'] ?? 0) > 0) {
            $paymentAmount = (int) $offer['payment_amount'];
            $totalPrice = kakiempat_platform_fee_v2_resolve_total_price(0, $paymentAmount);
        }

        $pdo->prepare("UPDATE kakiempa_v2_offers SET status = 'accepted' WHERE id = ?")
            ->execute([$offerId]);
        $pdo->prepare(
            "UPDATE kakiempa_v2_offers SET status = 'rejected'
             WHERE request_id = ? AND id <> ? AND status = 'pending'",
        )->execute([(int) $offer['request_id'], $offerId]);
        $pdo->prepare("UPDATE kakiempa_v2_requests SET status = 'matched' WHERE id = ?")
            ->execute([(int) $offer['request_id']]);

        $bookingStatus = $paymentAmount > 0 ? 'awaitingPayment' : 'pending';
        $pdo->prepare(
            'INSERT INTO kakiempa_v2_bookings
                (offer_id, request_id, owner_user_id, sitter_user_id, status,
                 total_price, payment_amount)
             VALUES (?, ?, ?, ?, ?, ?, ?)',
        )->execute([
            $offerId,
            (int) $offer['request_id'],
            $auth['user_id'],
            (int) $offer['sitter_user_id'],
            $bookingStatus,
            $totalPrice,
            $paymentAmount,
        ]);
        $bookingId = (int) $pdo->lastInsertId();

        kakiempat_event_notifications_offer_accepted(
            $pdo,
            $auth['user_id'],
            (int) $offer['sitter_user_id'],
            $bookingId,
        );

        $pdo->commit();
        v2ApiRespondData([
            'booking_id' => (string) $bookingId,
            'offer_id' => (string) $offerId,
            'request_id' => (string) $offer['request_id'],
            'status' => $bookingStatus,
            'total_price' => $totalPrice,
            'payment_amount' => $paymentAmount,
            'chat_ready' => true,
            'message' => 'Penawaran diterima. Booking dibuat — chat langsung tersedia.',
        ]);
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        throw $e;
    }
}

/** @return list<array<string, mixed>> */
function kakiempat_marketplace_v2_fetch_owner_requests(
    PDO $pdo,
    int $ownerUserId,
    string $pool = 'active',
): array {
    $pool = strtolower(trim($pool));
    $statuses = $pool === 'all'
        ? ['open', 'matched', 'cancelled']
        : ['open', 'matched'];

    $extraCols = '';
    if (v2ApiColumnExists($pdo, 'kakiempa_v2_requests', 'date_label')) {
        $extraCols .= ', r.date_label, r.time_range';
    }
    if (v2ApiColumnExists($pdo, 'kakiempa_v2_requests', 'location_json')) {
        $extraCols .= ', r.location_json';
    }

    $placeholders = implode(',', array_fill(0, count($statuses), '?'));
    $params = array_merge([$ownerUserId], $statuses);

    $stmt = $pdo->prepare(
        "SELECT r.id, r.owner_user_id, r.service_code, r.scheduled_at, r.notes,
                r.pet_ids, r.total_price, r.payment_amount, r.status, r.created_at,
                u.name AS owner_name{$extraCols}
         FROM kakiempa_v2_requests r
         INNER JOIN kakiempa_v2_users u ON u.id = r.owner_user_id
         WHERE r.owner_user_id = ? AND r.status IN ({$placeholders})
         ORDER BY r.created_at DESC",
    );
    $stmt->execute($params);

    $requests = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        if (!is_array($row)) {
            continue;
        }
        $formatted = kakiempat_marketplace_v2_format_request($row);
        $offerCountStmt = $pdo->prepare(
            "SELECT COUNT(*) FROM kakiempa_v2_offers
             WHERE request_id = ? AND status = 'pending'",
        );
        $offerCountStmt->execute([(int) $row['id']]);
        $formatted['pending_offer_count'] = (int) $offerCountStmt->fetchColumn();
        $requests[] = $formatted;
    }

    return $requests;
}

function kakiempat_marketplace_v2_list_my_requests(): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['owner', 'founder']);
    $pdo = v2ApiPdo();

    $pool = strtolower(trim((string) ($_GET['pool'] ?? 'active')));
    $requests = kakiempat_marketplace_v2_fetch_owner_requests($pdo, $auth['user_id'], $pool);

    v2ApiRespondData(['requests' => $requests, 'total' => count($requests)]);
}

function kakiempat_marketplace_v2_list_offers(): void
{
    $auth = v2ApiRequireAuth();
    v2ApiRequireRole($auth, ['owner', 'founder']);
    $pdo = v2ApiPdo();

    $requestId = (int) ($_GET['request_id'] ?? 0);
    if ($requestId < 1) {
        v2ApiFail('invalid_request_id', 'request_id wajib.', 400);
    }

    $reqStmt = $pdo->prepare(
        'SELECT id, owner_user_id, status FROM kakiempa_v2_requests WHERE id = ? LIMIT 1',
    );
    $reqStmt->execute([$requestId]);
    $request = $reqStmt->fetch(PDO::FETCH_ASSOC);
    if (!is_array($request)) {
        v2ApiFail('request_not_found', 'Permintaan tidak ditemukan.', 404);
    }
    if ((int) $request['owner_user_id'] !== $auth['user_id'] && !v2ApiIsAdmin($auth)) {
        v2ApiFail('forbidden', 'Hanya pemilik permintaan yang dapat melihat penawaran.', 403);
    }

    $hasPrice = v2ApiColumnExists($pdo, 'kakiempa_v2_offers', 'price');
    $hasMessage = v2ApiColumnExists($pdo, 'kakiempa_v2_offers', 'message');
    $hasCreatedAt = v2ApiColumnExists($pdo, 'kakiempa_v2_offers', 'created_at');
    $phoneCol = v2ApiColumnExists($pdo, 'kakiempa_v2_users', 'phone')
        ? 'u.phone'
        : (v2ApiColumnExists($pdo, 'kakiempa_v2_users', 'whatsapp') ? 'u.whatsapp' : "''");
    $priceCol = $hasPrice ? 'o.price' : '0 AS price';
    $messageCol = $hasMessage ? 'o.message' : "'' AS message";
    $createdCol = $hasCreatedAt ? 'o.created_at' : 'NULL AS created_at';
    $orderBy = $hasCreatedAt ? 'o.created_at DESC' : 'o.id DESC';

    $stmt = $pdo->prepare(
        "SELECT o.id, o.request_id, o.sitter_user_id, o.status, {$priceCol}, {$messageCol},
                {$createdCol}, u.name AS sitter_name, {$phoneCol} AS sitter_phone
         FROM kakiempa_v2_offers o
         INNER JOIN kakiempa_v2_users u ON u.id = o.sitter_user_id
         WHERE o.request_id = ?
         ORDER BY {$orderBy}",
    );
    $stmt->execute([$requestId]);

    require_once __DIR__ . '/kakiempat_sitter_badges_v2.php';
    require_once __DIR__ . '/kakiempat_business_v2.php';

    $offers = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        if (!is_array($row)) {
            continue;
        }
        $sitterId = (int) ($row['sitter_user_id'] ?? 0);
        $stats = kakiempat_sitter_badges_v2_stats($pdo, $sitterId);
        $offers[] = [
            'id' => (string) $row['id'],
            'offer_id' => (string) $row['id'],
            'request_id' => (string) $row['request_id'],
            'sitter_user_id' => (string) $sitterId,
            'sitter_name' => (string) ($row['sitter_name'] ?? ''),
            'sitter_phone' => (string) ($row['sitter_phone'] ?? ''),
            'price' => (int) ($row['price'] ?? 0),
            'message' => (string) ($row['message'] ?? ''),
            'status' => (string) ($row['status'] ?? ''),
            'created_at' => (string) ($row['created_at'] ?? ''),
            'is_verified' => kakiempat_sitter_badges_v2_is_verified($pdo, $sitterId),
            'average_rating' => $stats['average_rating'],
            'badges' => kakiempat_sitter_badges_v2_compute($pdo, $sitterId),
            'has_promo' => kakiempat_business_v2_has_active_promo($pdo, $sitterId),
        ];
    }

    v2ApiRespondData([
        'request_id' => (string) $requestId,
        'request_status' => (string) ($request['status'] ?? ''),
        'offers' => $offers,
        'total' => count($offers),
    ]);
}

/** @param array<string, mixed> $body */
function kakiempat_marketplace_v2_parse_location(array $body): array
{
    $topAddress = trim((string) ($body['address'] ?? ''));
    if ($topAddress !== '') {
        $lat = $body['latitude'] ?? $body['lat'] ?? null;
        $lng = $body['longitude'] ?? $body['lng'] ?? $body['lon'] ?? null;
        return [
            'address' => $topAddress,
            'latitude' => is_numeric($lat) ? (float) $lat : null,
            'longitude' => is_numeric($lng) ? (float) $lng : null,
        ];
    }

    $loc = $body['location'] ?? null;
    if (is_string($loc)) {
        return ['address' => trim($loc), 'latitude' => null, 'longitude' => null];
    }
    if (!is_array($loc)) {
        return ['address' => '', 'latitude' => null, 'longitude' => null];
    }

    $lat = $loc['latitude'] ?? $loc['lat'] ?? null;
    $lng = $loc['longitude'] ?? $loc['lng'] ?? $loc['lon'] ?? null;

    return [
        'address' => trim((string) ($loc['address'] ?? '')),
        'latitude' => is_numeric($lat) ? (float) $lat : null,
        'longitude' => is_numeric($lng) ? (float) $lng : null,
    ];
}

/** @param array<string, mixed> $body
 * @return list<int>
 */
function kakiempat_marketplace_v2_parse_pets(array $body): array
{
    if (isset($body['pets']) && is_array($body['pets'])) {
        $ids = [];
        foreach ($body['pets'] as $item) {
            if (is_array($item)) {
                $id = trim((string) ($item['id'] ?? $item['pet_id'] ?? ''));
            } else {
                $id = trim((string) $item);
            }
            if ($id !== '' && ctype_digit($id)) {
                $ids[] = (int) $id;
            }
        }
        if ($ids !== []) {
            return array_values(array_unique($ids));
        }
    }

    return kakiempat_booking_v2_parse_pet_ids($body);
}

function kakiempat_marketplace_v2_broadcast_radius_km(): float
{
    return 7.0;
}

/** @return array{latitude: float, longitude: float}|null */
function kakiempat_marketplace_v2_parse_query_coordinates(): ?array
{
    $lat = $_GET['latitude'] ?? $_GET['lat'] ?? null;
    $lng = $_GET['longitude'] ?? $_GET['lng'] ?? $_GET['lon'] ?? null;
    if (!is_numeric($lat) || !is_numeric($lng)) {
        return null;
    }

    return ['latitude' => (float) $lat, 'longitude' => (float) $lng];
}

/** @return array{latitude: float, longitude: float}|null */
function kakiempat_marketplace_v2_resolve_sitter_coordinates(PDO $pdo, int $userId): ?array
{
    $fromQuery = kakiempat_marketplace_v2_parse_query_coordinates();
    if ($fromQuery !== null) {
        return $fromQuery;
    }

    return kakiempat_marketplace_v2_sitter_coordinates($pdo, $userId);
}

function kakiempat_marketplace_v2_sql_json_latitude(string $jsonColumn): string
{
    return kakiempat_geo_v2_sql_json_latitude($jsonColumn);
}

function kakiempat_marketplace_v2_sql_json_longitude(string $jsonColumn): string
{
    return kakiempat_geo_v2_sql_json_longitude($jsonColumn);
}

function kakiempat_marketplace_v2_sql_haversine_km(
    string $latSql,
    string $lngSql,
    string $originLatParam,
    string $originLngParam,
    string $originLatParamRepeat,
): string {
    return kakiempat_geo_v2_sql_haversine_km(
        $latSql,
        $lngSql,
        $originLatParam,
        $originLngParam,
        $originLatParamRepeat,
    );
}

function kakiempat_marketplace_v2_count_sitters_in_radius(
    PDO $pdo,
    float $latitude,
    float $longitude,
    string $serviceCode,
    ?float $radiusKm = null,
): int {
    $radius = $radiusKm !== null && $radiusKm > 0
        ? $radiusKm
        : kakiempat_marketplace_v2_broadcast_radius_km();

    $sitterCoords = kakiempat_geo_v2_resolve_coord_sql(
        $pdo,
        'kakiempa_v2_sitter_profiles',
        'sp',
        'profile_json',
    );
    $sitterLatSql = $sitterCoords['lat_sql'];
    $sitterLngSql = $sitterCoords['lng_sql'];
    $bbox = kakiempat_geo_v2_bounding_box($latitude, $longitude, $radius);
    $distanceSql = kakiempat_geo_v2_sql_haversine_km(
        $sitterLatSql,
        $sitterLngSql,
        '?',
        '?',
        '?',
    );
    $serviceJson = json_encode($serviceCode, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    $bboxSql = $sitterCoords['use_bbox']
        ? ' AND sp.latitude BETWEEN ? AND ? AND sp.longitude BETWEEN ? AND ?'
        : '';

    $stmt = $pdo->prepare(
        "SELECT COUNT(*) FROM (
            SELECT {$distanceSql} AS distance_km
            FROM kakiempa_v2_sitter_profiles sp
            WHERE sp.status = 'approved'
              AND {$sitterLatSql} IS NOT NULL
              AND {$sitterLngSql} IS NOT NULL{$bboxSql}
              AND JSON_CONTAINS(sp.profile_json, ?, '$.services')
              AND (
                JSON_EXTRACT(sp.profile_json, '$.is_available') IS NULL
                OR JSON_EXTRACT(sp.profile_json, '$.is_available') = true
              )
            HAVING distance_km <= ?
         ) AS nearby_sitters",
    );
    $bboxParams = $sitterCoords['use_bbox']
        ? [$bbox['min_lat'], $bbox['max_lat'], $bbox['min_lng'], $bbox['max_lng']]
        : [];
    $stmt->execute(array_merge(
        [$latitude, $longitude, $latitude],
        $bboxParams,
        [$serviceJson, $radius],
    ));

    return (int) ($stmt->fetchColumn() ?: 0);
}

/** @return array{latitude: float, longitude: float}|null */
function kakiempat_marketplace_v2_sitter_coordinates(PDO $pdo, int $userId): ?array
{
    $hasGeo = kakiempat_geo_v2_has_indexed_coords($pdo, 'kakiempa_v2_sitter_profiles');
    $cols = $hasGeo ? 'latitude, longitude, profile_json' : 'profile_json';
    $stmt = $pdo->prepare(
        "SELECT {$cols} FROM kakiempa_v2_sitter_profiles WHERE user_id = ? LIMIT 1",
    );
    $stmt->execute([$userId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!is_array($row)) {
        return null;
    }

    $lat = $row['latitude'] ?? null;
    $lng = $row['longitude'] ?? null;
    if (!is_numeric($lat) || !is_numeric($lng)) {
        $meta = kakiempat_sitter_v2_decode_json((string) ($row['profile_json'] ?? ''));
        $lat = $meta['latitude'] ?? null;
        $lng = $meta['longitude'] ?? null;
    }
    if (!is_numeric($lat) || !is_numeric($lng)) {
        return null;
    }

    return ['latitude' => (float) $lat, 'longitude' => (float) $lng];
}

/** @param array<string, mixed> $row
 * @return array{latitude: float, longitude: float}|null
 */
function kakiempat_marketplace_v2_request_coordinates(array $row): ?array
{
    if (isset($row['location_json']) && $row['location_json'] !== null && $row['location_json'] !== '') {
        $decoded = json_decode((string) $row['location_json'], true);
        if (is_array($decoded)) {
            $lat = $decoded['latitude'] ?? $decoded['lat'] ?? null;
            $lng = $decoded['longitude'] ?? $decoded['lng'] ?? null;
            if (is_numeric($lat) && is_numeric($lng)) {
                return ['latitude' => (float) $lat, 'longitude' => (float) $lng];
            }
        }
    }

    return null;
}

function kakiempat_marketplace_v2_haversine_km(
    float $lat1,
    float $lon1,
    float $lat2,
    float $lon2,
): float {
    $earthRadius = 6371.0;
    $dLat = deg2rad($lat2 - $lat1);
    $dLon = deg2rad($lon2 - $lon1);
    $a = sin($dLat / 2) ** 2
        + cos(deg2rad($lat1)) * cos(deg2rad($lat2)) * sin($dLon / 2) ** 2;

    return $earthRadius * 2 * atan2(sqrt($a), sqrt(1 - $a));
}

/** @param array<string, mixed> $row
 * @return array<string, mixed>
 */
function kakiempat_marketplace_v2_format_request(array $row): array
{
    $formatted = kakiempat_booking_v2_format_request($row);
    $formatted['service_type'] = $formatted['service_code'];
    unset($formatted['service_code']);

    if (isset($row['date_label'])) {
        $formatted['date_label'] = (string) $row['date_label'];
    }
    if (isset($row['time_range'])) {
        $formatted['time_range'] = (string) $row['time_range'];
    }
    if (isset($row['location_json']) && $row['location_json'] !== null && $row['location_json'] !== '') {
        $decoded = json_decode((string) $row['location_json'], true);
        $formatted['location'] = is_array($decoded) ? $decoded : null;
    }
    if (isset($row['distance_km'])) {
        $formatted['distance_km'] = (float) $row['distance_km'];
    }
    $formatted['price'] = (int) ($row['total_price'] ?? 0);

    return kakiempat_marketplace_v2_enrich_request_pets(v2ApiPdo(), $formatted);
}

/** @param array<string, mixed> $formatted
 * @return array<string, mixed>
 */
function kakiempat_marketplace_v2_enrich_request_pets(PDO $pdo, array $formatted): array
{
    $petIds = $formatted['pet_ids'] ?? [];
    if (!is_array($petIds) || $petIds === []) {
        $formatted['pet_names'] = [];

        return $formatted;
    }

    $placeholders = implode(',', array_fill(0, count($petIds), '?'));
    $stmt = $pdo->prepare(
        "SELECT id, name FROM kakiempa_v2_pets WHERE id IN ({$placeholders})",
    );
    $stmt->execute(array_values($petIds));
    $namesById = [];
    while ($petRow = $stmt->fetch(PDO::FETCH_ASSOC)) {
        if (!is_array($petRow)) {
            continue;
        }
        $namesById[(string) ($petRow['id'] ?? '')] = (string) ($petRow['name'] ?? '');
    }

    $petNames = [];
    foreach ($petIds as $petId) {
        $key = (string) $petId;
        if ($key !== '' && isset($namesById[$key]) && $namesById[$key] !== '') {
            $petNames[] = $namesById[$key];
        }
    }
    $formatted['pet_names'] = $petNames;

    return $formatted;
}
