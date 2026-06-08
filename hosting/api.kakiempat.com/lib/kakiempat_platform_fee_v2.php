<?php
declare(strict_types=1);

/** @return array<string, mixed> */
function kakiempat_platform_fee_v2_config(): array
{
    static $cfg = null;
    if (is_array($cfg)) {
        return $cfg;
    }
    $file = dirname(__DIR__) . '/.payment_config.php';
    if (is_readable($file)) {
        $loaded = require $file;
        $cfg = is_array($loaded) ? $loaded : [];
    } else {
        $cfg = [];
    }

    return $cfg;
}

/** @return array{owner: float, sitter: float} */
function kakiempat_platform_fee_v2_rates(): array
{
    $cfg = kakiempat_platform_fee_v2_config();
    $owner = (float) ($cfg['platform_fee_owner_percent'] ?? 0.05);
    $sitter = (float) ($cfg['platform_fee_sitter_percent'] ?? 0.08);
    if ($owner < 0 || $owner > 1) {
        $owner = 0.05;
    }
    if ($sitter < 0 || $sitter > 1) {
        $sitter = 0.08;
    }

    return ['owner' => $owner, 'sitter' => $sitter];
}

function kakiempat_platform_fee_v2_owner_fee(int $totalPrice): int
{
    if ($totalPrice <= 0) {
        return 0;
    }
    $rates = kakiempat_platform_fee_v2_rates();

    return (int) round($totalPrice * $rates['owner']);
}

function kakiempat_platform_fee_v2_sitter_fee(int $totalPrice): int
{
    if ($totalPrice <= 0) {
        return 0;
    }
    $rates = kakiempat_platform_fee_v2_rates();

    return (int) round($totalPrice * $rates['sitter']);
}

function kakiempat_platform_fee_v2_owner_payment_amount(int $totalPrice): int
{
    if ($totalPrice <= 0) {
        return 0;
    }

    return $totalPrice + kakiempat_platform_fee_v2_owner_fee($totalPrice);
}

function kakiempat_platform_fee_v2_sitter_net(int $totalPrice): int
{
    if ($totalPrice <= 0) {
        return 0;
    }

    return $totalPrice - kakiempat_platform_fee_v2_sitter_fee($totalPrice);
}

function kakiempat_platform_fee_v2_resolve_total_price(int $storedTotal, int $paymentAmount): int
{
    if ($storedTotal > 0) {
        return $storedTotal;
    }
    if ($paymentAmount <= 0) {
        return 0;
    }
    $rates = kakiempat_platform_fee_v2_rates();
    $divisor = 1 + $rates['owner'];
    if ($divisor <= 0) {
        return $paymentAmount;
    }

    return (int) round($paymentAmount / $divisor);
}

function kakiempat_platform_fee_v2_ledger_exists(PDO $pdo, int $bookingId, string $kind): bool
{
    $stmt = $pdo->prepare(
        'SELECT id FROM kakiempa_v2_wallet_ledger WHERE booking_id = ? AND kind = ? LIMIT 1',
    );
    $stmt->execute([$bookingId, $kind]);

    return (bool) $stmt->fetchColumn();
}

function kakiempat_platform_fee_v2_insert_ledger(
    PDO $pdo,
    int $userId,
    int $bookingId,
    int $amountIdr,
    string $kind,
    string $description,
): void {
    $pdo->prepare(
        'INSERT INTO kakiempa_v2_wallet_ledger
            (user_id, booking_id, amount_cents, kind, description)
         VALUES (?, ?, ?, ?, ?)',
    )->execute([$userId, $bookingId, $amountIdr, $kind, $description]);
}

/**
 * Pembagian biaya platform saat booking PAID — idempoten per booking.
 *
 * @return array{
 *   total_price: int,
 *   platform_fee_owner: int,
 *   platform_fee_sitter: int,
 *   sitter_net: int,
 *   amount_received: int
 * }
 */
function kakiempat_platform_fee_v2_apply_for_booking(PDO $pdo, int $bookingId): array
{
    $stmt = $pdo->prepare(
        'SELECT id, sitter_user_id, total_price, payment_amount, status
         FROM kakiempa_v2_bookings WHERE id = ? LIMIT 1 FOR UPDATE',
    );
    $stmt->execute([$bookingId]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!is_array($row)) {
        v2ApiFail('booking_not_found', 'Booking tidak ditemukan.', 404);
    }

    $status = strtolower(str_replace(['_', '-'], '', (string) ($row['status'] ?? '')));
    if ($status !== 'paid') {
        v2ApiFail('booking_not_paid', 'Biaya platform hanya diproses untuk booking paid.', 409);
    }

    $rates = kakiempat_platform_fee_v2_rates();
    $sitterId = (int) ($row['sitter_user_id'] ?? 0);
    $paymentAmount = (int) ($row['payment_amount'] ?? 0);
    $totalPrice = kakiempat_platform_fee_v2_resolve_total_price(
        (int) ($row['total_price'] ?? 0),
        $paymentAmount,
    );
    $platformFeeOwner = kakiempat_platform_fee_v2_owner_fee($totalPrice);
    $platformFeeSitter = kakiempat_platform_fee_v2_sitter_fee($totalPrice);
    $sitterNet = kakiempat_platform_fee_v2_sitter_net($totalPrice);
    $amountReceived = $totalPrice + $platformFeeOwner;

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

    if ($totalPrice > 0 && (int) ($row['total_price'] ?? 0) === 0) {
        $pdo->prepare('UPDATE kakiempa_v2_bookings SET total_price = ? WHERE id = ?')
            ->execute([$totalPrice, $bookingId]);
    }

    return [
        'total_price' => $totalPrice,
        'platform_fee_owner' => $platformFeeOwner,
        'platform_fee_sitter' => $platformFeeSitter,
        'sitter_net' => $sitterNet,
        'amount_received' => $amountReceived,
    ];
}

/** @return array<string, mixed> */
function kakiempat_platform_fee_v2_payment_breakdown(int $totalPrice): array
{
    $ownerFee = kakiempat_platform_fee_v2_owner_fee($totalPrice);
    $sitterFee = kakiempat_platform_fee_v2_sitter_fee($totalPrice);
    $rates = kakiempat_platform_fee_v2_rates();

    return [
        'total_price' => $totalPrice,
        'platform_fee_owner' => $ownerFee,
        'platform_fee_sitter' => $sitterFee,
        'platform_fee_owner_percent' => $rates['owner'],
        'platform_fee_sitter_percent' => $rates['sitter'],
        'owner_pays' => $totalPrice + $ownerFee,
        'sitter_net' => kakiempat_platform_fee_v2_sitter_net($totalPrice),
        'platform_total' => $ownerFee + $sitterFee,
    ];
}
