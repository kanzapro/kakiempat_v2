<?php
declare(strict_types=1);

require_once __DIR__ . '/kakiempat_platform_fee_v2.php';

function kakiempat_wallet_v2_get_summary(PDO $pdo, int $userId): void
{
    $balanceStmt = $pdo->prepare(
        'SELECT COALESCE(SUM(amount_cents), 0) FROM kakiempa_v2_wallet_ledger WHERE user_id = ?',
    );
    $balanceStmt->execute([$userId]);
    $balance = (int) $balanceStmt->fetchColumn();

    $grossStmt = $pdo->prepare(
        "SELECT COALESCE(SUM(amount_cents), 0) FROM kakiempa_v2_wallet_ledger
         WHERE user_id = ? AND kind = 'income'",
    );
    $grossStmt->execute([$userId]);
    $grossIncome = (int) $grossStmt->fetchColumn();

    $feeStmt = $pdo->prepare(
        "SELECT COALESCE(SUM(amount_cents), 0) FROM kakiempa_v2_wallet_ledger
         WHERE user_id = ? AND kind = 'platform_fee'",
    );
    $feeStmt->execute([$userId]);
    $platformFees = (int) $feeStmt->fetchColumn();

    $ledgerStmt = $pdo->prepare(
        'SELECT id, booking_id, amount_cents, kind, description, created_at
         FROM kakiempa_v2_wallet_ledger
         WHERE user_id = ?
         ORDER BY created_at DESC, id DESC
         LIMIT 100',
    );
    $ledgerStmt->execute([$userId]);
    $rows = $ledgerStmt->fetchAll(PDO::FETCH_ASSOC) ?: [];

    $entries = [];
    foreach ($rows as $row) {
        if (!is_array($row)) {
            continue;
        }
        $entries[] = [
            'id' => (string) $row['id'],
            'booking_id' => $row['booking_id'] !== null ? (string) $row['booking_id'] : null,
            'amount' => (int) $row['amount_cents'],
            'type' => (string) $row['kind'],
            'description' => (string) ($row['description'] ?? ''),
            'created_at' => (string) ($row['created_at'] ?? ''),
        ];
    }

    $rates = kakiempat_platform_fee_v2_rates();

    v2ApiRespondData([
        'balance' => $balance,
        'gross_income' => $grossIncome,
        'platform_fees' => $platformFees,
        'net_income' => $grossIncome + $platformFees,
        'platform_fee_sitter_percent' => $rates['sitter'],
        'entries' => $entries,
    ]);
}

function kakiempat_wallet_v2_balance(PDO $pdo, int $userId): int
{
    $stmt = $pdo->prepare(
        'SELECT COALESCE(SUM(amount_cents), 0) FROM kakiempa_v2_wallet_ledger WHERE user_id = ?',
    );
    $stmt->execute([$userId]);

    return (int) $stmt->fetchColumn();
}

function kakiempat_wallet_v2_pending_withdrawal_sum(PDO $pdo, int $userId): int
{
    if (!v2ApiTableExists($pdo, 'kakiempa_v2_withdrawals')) {
        return 0;
    }
    $stmt = $pdo->prepare(
        "SELECT COALESCE(SUM(amount), 0) FROM kakiempa_v2_withdrawals
         WHERE user_id = ? AND status = 'pending'",
    );
    $stmt->execute([$userId]);

    return (int) $stmt->fetchColumn();
}

/** @param array<string, mixed> $body */
function kakiempat_wallet_v2_request_withdraw(PDO $pdo, int $userId, array $body): void
{
    if (!v2ApiTableExists($pdo, 'kakiempa_v2_withdrawals')) {
        v2ApiFail('schema_missing', 'Tabel penarikan belum tersedia. Jalankan migrasi 015.', 503);
    }

    $amount = (int) ($body['amount'] ?? 0);
    if ($amount < 10000) {
        v2ApiFail('invalid_amount', 'Minimal penarikan Rp 10.000.', 400);
    }

    $balance = kakiempat_wallet_v2_balance($pdo, $userId);
    $pending = kakiempat_wallet_v2_pending_withdrawal_sum($pdo, $userId);
    $available = $balance - $pending;
    if ($amount > $available) {
        v2ApiFail(
            'insufficient_balance',
            'Saldo tidak mencukupi untuk penarikan ini.',
            409,
        );
    }

    $pdo->prepare(
        "INSERT INTO kakiempa_v2_withdrawals (user_id, amount, status) VALUES (?, ?, 'pending')",
    )->execute([$userId, $amount]);

    $withdrawalId = (int) $pdo->lastInsertId();
    v2ApiRespondData([
        'withdrawal' => kakiempat_wallet_v2_format_withdrawal([
            'id' => $withdrawalId,
            'user_id' => $userId,
            'amount' => $amount,
            'status' => 'pending',
            'created_at' => date('Y-m-d H:i:s.u'),
            'completed_at' => null,
        ]),
        'available_balance' => $available - $amount,
        'message' => 'Permintaan penarikan dikirim. Menunggu persetujuan admin.',
    ], 201);
}

function kakiempat_wallet_v2_list_my_withdrawals(PDO $pdo, int $userId): void
{
    if (!v2ApiTableExists($pdo, 'kakiempa_v2_withdrawals')) {
        v2ApiRespondData(['withdrawals' => [], 'total' => 0]);
        return;
    }

    $stmt = $pdo->prepare(
        'SELECT id, user_id, amount, status, created_at, completed_at
         FROM kakiempa_v2_withdrawals
         WHERE user_id = ?
         ORDER BY created_at DESC, id DESC
         LIMIT 100',
    );
    $stmt->execute([$userId]);

    $items = [];
    while ($row = $stmt->fetch(PDO::FETCH_ASSOC)) {
        if (is_array($row)) {
            $items[] = kakiempat_wallet_v2_format_withdrawal($row);
        }
    }

    v2ApiRespondData(['withdrawals' => $items, 'total' => count($items)]);
}

/** @param array<string, mixed> $row */
function kakiempat_wallet_v2_format_withdrawal(array $row): array
{
    return [
        'id' => (string) ($row['id'] ?? ''),
        'user_id' => (string) ($row['user_id'] ?? ''),
        'amount' => (int) ($row['amount'] ?? 0),
        'status' => (string) ($row['status'] ?? ''),
        'created_at' => (string) ($row['created_at'] ?? ''),
        'completed_at' => $row['completed_at'] !== null ? (string) $row['completed_at'] : null,
    ];
}

function kakiempat_wallet_v2_deduct_for_withdrawal(
    PDO $pdo,
    int $userId,
    int $withdrawalId,
    int $amount,
): void {
    $pdo->prepare(
        'INSERT INTO kakiempa_v2_wallet_ledger
            (user_id, booking_id, amount_cents, kind, description)
         VALUES (?, NULL, ?, ?, ?)',
    )->execute([
        $userId,
        -$amount,
        'withdrawal',
        'Penarikan #' . $withdrawalId,
    ]);
}
