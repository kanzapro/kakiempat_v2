<?php
declare(strict_types=1);

require_once __DIR__ . '/../v2_api_common.php';

const KAKIEMPAT_V2_SESSION_DAYS = 30;
const KAKIEMPAT_V2_REFRESH_DAYS = 90;
const KAKIEMPAT_V2_TOKEN_PREFIX = 'native_';
const KAKIEMPAT_V2_REFRESH_PREFIX = 'refresh_';
const KAKIEMPAT_V2_SSO_COOKIE = 'ke_sso_rt';
const KAKIEMPAT_V2_SSO_HANDOFF_PREFIX = 'sso_';
const KAKIEMPAT_V2_RESET_PREFIX = 'reset_';
const KAKIEMPAT_V2_SSO_HANDOFF_SECONDS = 120;
const KAKIEMPAT_V2_RESET_MINUTES = 30;

/** Normalisasi: 08xx, 62xx, +62xx → 62xxxxxxxxxx (11–14 digit). */
function kakiempat_v2_normalize_phone(string $raw): ?string
{
    $digits = preg_replace('/\D+/', '', trim($raw)) ?? '';
    if ($digits === '') {
        return null;
    }
    if (str_starts_with($digits, '0')) {
        $digits = '62' . substr($digits, 1);
    }
    if (!str_starts_with($digits, '62')) {
        return null;
    }
    $len = strlen($digits);
    if ($len < 11 || $len > 14) {
        return null;
    }
    return $digits;
}

function kakiempat_v2_validate_password(string $password): bool
{
    return strlen($password) >= 6;
}

function kakiempat_v2_phone_to_email(string $phone): string
{
    return $phone . '@phone.kakiempat.local';
}

/** @return list<string> */
function kakiempat_v2_fetch_user_roles(PDO $pdo, int $userId, ?string $fallbackRole = null): array
{
    if (v2ApiTableExists($pdo, 'kakiempa_v2_user_roles')) {
        $stmt = $pdo->prepare(
            'SELECT role FROM kakiempa_v2_user_roles WHERE user_id = ? ORDER BY role',
        );
        $stmt->execute([$userId]);
        $roles = $stmt->fetchAll(PDO::FETCH_COLUMN);
        if (is_array($roles) && $roles !== []) {
            return array_map('strval', $roles);
        }
    }
    if ($fallbackRole !== null && $fallbackRole !== '') {
        return [$fallbackRole];
    }
    return [];
}

function kakiempat_v2_ensure_user_role(PDO $pdo, int $userId, string $role): void
{
    if (!v2ApiTableExists($pdo, 'kakiempa_v2_user_roles')) {
        return;
    }
    $pdo->prepare(
        'INSERT IGNORE INTO kakiempa_v2_user_roles (user_id, role) VALUES (:uid, :role)',
    )->execute(['uid' => $userId, 'role' => $role]);
}

/** @return array<string, mixed> */
function kakiempat_v2_user_payload_from_row(PDO $pdo, array $row): array
{
    $userId = (int) $row['id'];
    $role = (string) $row['role'];
    $roles = kakiempat_v2_fetch_user_roles($pdo, $userId, $role);

    return [
        'id' => $userId,
        'phone' => (string) ($row['whatsapp'] ?? ''),
        'role' => $role,
        'roles' => $roles,
        'name' => (string) $row['name'],
    ];
}

function kakiempat_v2_extract_bearer_token(): string
{
    return v2ApiExtractBearerToken();
}

/** @return array<string, mixed> */
function kakiempat_v2_auth_read_json_body(): array
{
    $raw = (string) file_get_contents('php://input');
    if ($raw === '') {
        return $_POST;
    }
    $decoded = json_decode($raw, true);
    return is_array($decoded) ? $decoded : [];
}

function kakiempat_v2_sso_cookie_domain(): ?string
{
    $host = strtolower(trim((string) ($_SERVER['HTTP_HOST'] ?? '')));
    if (str_ends_with($host, 'kakiempat.com')) {
        return '.kakiempat.com';
    }
    return null;
}

function kakiempat_v2_set_sso_cookie(string $refreshToken): void
{
    if ($refreshToken === '' || headers_sent()) {
        return;
    }
    $options = [
        'expires' => time() + (KAKIEMPAT_V2_REFRESH_DAYS * 86400),
        'path' => '/',
        'secure' => true,
        'httponly' => true,
        'samesite' => 'None',
    ];
    $domain = kakiempat_v2_sso_cookie_domain();
    if ($domain !== null) {
        $options['domain'] = $domain;
    }
    setcookie(KAKIEMPAT_V2_SSO_COOKIE, $refreshToken, $options);
}

function kakiempat_v2_clear_sso_cookie(): void
{
    if (headers_sent()) {
        return;
    }
    $options = [
        'expires' => time() - 3600,
        'path' => '/',
        'secure' => true,
        'httponly' => true,
        'samesite' => 'None',
    ];
    $domain = kakiempat_v2_sso_cookie_domain();
    if ($domain !== null) {
        $options['domain'] = $domain;
    }
    setcookie(KAKIEMPAT_V2_SSO_COOKIE, '', $options);
}

function kakiempat_v2_extract_sso_refresh_cookie(): string
{
    return trim((string) ($_COOKIE[KAKIEMPAT_V2_SSO_COOKIE] ?? ''));
}

/** @return array{ok:true,token:string,refresh_token:string,user:array<string,mixed>} */
function kakiempat_v2_auth_success(int $userId, string $phone, string $role, string $name, PDO $pdo): array
{
    $token = KAKIEMPAT_V2_TOKEN_PREFIX . bin2hex(random_bytes(32));
    $tokenHash = hash('sha256', $token);
    $refreshToken = KAKIEMPAT_V2_REFRESH_PREFIX . bin2hex(random_bytes(32));
    $refreshHash = hash('sha256', $refreshToken);
    $expires = (new DateTimeImmutable('now', new DateTimeZone('UTC')))
        ->modify('+' . KAKIEMPAT_V2_SESSION_DAYS . ' days')
        ->format('Y-m-d H:i:s.u');
    $refreshExpires = (new DateTimeImmutable('now', new DateTimeZone('UTC')))
        ->modify('+' . KAKIEMPAT_V2_REFRESH_DAYS . ' days')
        ->format('Y-m-d H:i:s.u');

    if (v2ApiColumnExists($pdo, 'kakiempa_v2_sessions', 'refresh_token_hash')) {
        $pdo->prepare(
            'INSERT INTO kakiempa_v2_sessions
                (token_hash, user_id, phone, role, expires_at, refresh_token_hash, refresh_expires_at)
             VALUES (:hash, :uid, :phone, :role, :exp, :refresh_hash, :refresh_exp)',
        )->execute([
            'hash' => $tokenHash,
            'uid' => $userId,
            'phone' => $phone,
            'role' => $role,
            'exp' => $expires,
            'refresh_hash' => $refreshHash,
            'refresh_exp' => $refreshExpires,
        ]);
    } else {
        $pdo->prepare(
            'INSERT INTO kakiempa_v2_sessions (token_hash, user_id, phone, role, expires_at)
             VALUES (:hash, :uid, :phone, :role, :exp)',
        )->execute([
            'hash' => $tokenHash,
            'uid' => $userId,
            'phone' => $phone,
            'role' => $role,
            'exp' => $expires,
        ]);
    }

    $roles = kakiempat_v2_fetch_user_roles($pdo, $userId, $role);
    $payload = [
        'ok' => true,
        'token' => $token,
        'user' => [
            'id' => $userId,
            'phone' => $phone,
            'role' => $role,
            'roles' => $roles,
            'name' => $name,
        ],
    ];
    if (v2ApiColumnExists($pdo, 'kakiempa_v2_sessions', 'refresh_token_hash')) {
        $payload['refresh_token'] = $refreshToken;
        kakiempat_v2_set_sso_cookie($refreshToken);
    }

    return $payload;
}

function kakiempat_v2_insert_owner_profile(PDO $pdo, int $userId, string $name, string $phone): void
{
    $pdo->prepare(
        'INSERT INTO kakiempa_v2_owner_profiles (user_id, display_name, whatsapp)
         VALUES (:uid, :display, :phone)',
    )->execute([
        'uid' => $userId,
        'display' => $name,
        'phone' => $phone,
    ]);
}

function kakiempat_v2_insert_sitter_profile(PDO $pdo, int $userId, string $name, string $phone): void
{
    $pdo->prepare(
        'INSERT INTO kakiempa_v2_sitter_profiles
            (user_id, display_name, legal_name, whatsapp, address, status)
         VALUES (:uid, :display, :legal, :phone, :address, :status)',
    )->execute([
        'uid' => $userId,
        'display' => $name,
        'legal' => $name,
        'phone' => $phone,
        'address' => '-',
        'status' => 'draft',
    ]);
}

function kakiempat_v2_auth_register(PDO $pdo, array $body): void
{
    v2ApiRateLimit($pdo, 'auth:register');

    $phone = kakiempat_v2_normalize_phone((string) ($body['phone'] ?? ''));
    $password = (string) ($body['password'] ?? '');
    $name = v2ApiSanitizeText((string) ($body['name'] ?? ''), 255);
    $role = strtolower(trim((string) ($body['role'] ?? 'owner')));

    if ($phone === null) {
        v2ApiFail(
            'invalid_phone',
            'Format nomor tidak dikenali. Gunakan 08xx, 62xx, atau +62xx.',
            400,
        );
    }
    if (!kakiempat_v2_validate_password($password)) {
        v2ApiFail('invalid_password', 'Kata sandi minimal 6 karakter.', 400);
    }
    if ($name === '' || strlen($name) > 255) {
        v2ApiFail('invalid_name', 'Nama wajib diisi.', 400);
    }
    if (!in_array($role, ['owner', 'sitter'], true)) {
        v2ApiFail('invalid_role', 'Peran harus owner atau sitter.', 400);
    }

    $check = $pdo->prepare('SELECT id FROM kakiempa_v2_users WHERE whatsapp = :phone LIMIT 1');
    $check->execute(['phone' => $phone]);
    if ($check->fetch()) {
        v2ApiFail('already_registered', 'Nomor sudah terdaftar. Silakan login.', 409);
    }

    $pdo->beginTransaction();
    try {
        $pdo->prepare(
            'INSERT INTO kakiempa_v2_users (name, email, password_hash, role, whatsapp, is_active)
             VALUES (:name, :email, :hash, :role, :phone, 1)',
        )->execute([
            'name' => $name,
            'email' => kakiempat_v2_phone_to_email($phone),
            'hash' => password_hash($password, PASSWORD_BCRYPT),
            'role' => $role,
            'phone' => $phone,
        ]);
        $userId = (int) $pdo->lastInsertId();

        kakiempat_v2_ensure_user_role($pdo, $userId, $role);
        if ($role === 'owner') {
            kakiempat_v2_insert_owner_profile($pdo, $userId, $name, $phone);
        } elseif ($role === 'sitter') {
            kakiempat_v2_insert_sitter_profile($pdo, $userId, $name, $phone);
        }

        $referralCode = trim((string) ($body['referral_code'] ?? ''));
        if ($referralCode !== '') {
            require_once __DIR__ . '/kakiempat_referral_v2.php';
            kakiempat_referral_v2_apply_on_register($pdo, $userId, $referralCode);
        }

        $payload = kakiempat_v2_auth_success($userId, $phone, $role, $name, $pdo);
        $pdo->commit();
        v2ApiRespond($payload, 201);
    } catch (Throwable $e) {
        $pdo->rollBack();
        error_log('auth_v2 register: ' . $e->getMessage());
        v2ApiFail('register_failed', 'Pendaftaran gagal. Coba lagi sebentar.', 500);
    }
}

function kakiempat_v2_auth_login(PDO $pdo, array $body): void
{
    v2ApiRateLimit($pdo, 'auth:login');

    $phone = kakiempat_v2_normalize_phone((string) ($body['phone'] ?? ''));
    $password = (string) ($body['password'] ?? '');

    if ($phone === null) {
        v2ApiFail(
            'invalid_phone',
            'Format nomor tidak dikenali. Gunakan 08xx, 62xx, atau +62xx.',
            400,
        );
    }
    if ($password === '') {
        v2ApiFail('invalid_password', 'Kata sandi wajib diisi.', 400);
    }

    $stmt = $pdo->prepare(
        'SELECT id, name, role, password_hash, whatsapp, is_active
         FROM kakiempa_v2_users WHERE whatsapp = :phone LIMIT 1',
    );
    $stmt->execute(['phone' => $phone]);
    $row = $stmt->fetch();
    if (!$row || !(int) $row['is_active']) {
        v2ApiSecurityLog($pdo, 'login_failed', null, ['phone' => $phone, 'reason' => 'user_not_found']);
        v2ApiFail(
            'user_not_found',
            'Nomor belum terdaftar. Silakan daftar terlebih dahulu.',
            401,
        );
    }
    if (!password_verify($password, (string) $row['password_hash'])) {
        v2ApiSecurityLog($pdo, 'login_failed', (int) $row['id'], ['phone' => $phone, 'reason' => 'wrong_password']);
        v2ApiFail(
            'wrong_password',
            'Kata sandi salah. Periksa lagi atau gunakan nomor lain.',
            401,
        );
    }

    v2ApiRespond(kakiempat_v2_auth_success(
        (int) $row['id'],
        $phone,
        (string) $row['role'],
        (string) $row['name'],
        $pdo,
    ));
}

function kakiempat_v2_auth_validate_token(PDO $pdo): void
{
    v2ApiRateLimit($pdo, 'auth:validate_token');

    $token = kakiempat_v2_extract_bearer_token();
    if ($token === '') {
        v2ApiFail('token_required', 'Token tidak ditemukan. Silakan masuk lagi.', 401);
    }
    if (!preg_match('/^native_[a-f0-9]{64}$/', $token)) {
        v2ApiSecurityLog($pdo, 'invalid_token_format');
        v2ApiFail('invalid_token', 'Sesi tidak valid. Silakan masuk lagi.', 401);
    }

    $stmt = $pdo->prepare(
        'SELECT u.id, u.name, u.role, u.whatsapp, s.expires_at
         FROM kakiempa_v2_sessions s
         INNER JOIN kakiempa_v2_users u ON u.id = s.user_id
         WHERE s.token_hash = :hash AND u.is_active = 1 LIMIT 1',
    );
    $stmt->execute(['hash' => hash('sha256', $token)]);
    $row = $stmt->fetch();
    if (!$row) {
        v2ApiSecurityLog($pdo, 'invalid_token');
        v2ApiFail('invalid_token', 'Sesi tidak ditemukan. Silakan masuk lagi.', 401);
    }

    $expires = new DateTimeImmutable((string) $row['expires_at'], new DateTimeZone('UTC'));
    if ($expires < new DateTimeImmutable('now', new DateTimeZone('UTC'))) {
        v2ApiSecurityLog($pdo, 'token_expired', (int) $row['id']);
        v2ApiFail('token_expired', 'Sesi kedaluwarsa. Silakan masuk lagi.', 401);
    }

    v2ApiRespond(['ok' => true, 'user' => kakiempat_v2_user_payload_from_row($pdo, $row)]);
}

function kakiempat_v2_auth_refresh_token(PDO $pdo, array $body): void
{
    v2ApiRateLimit($pdo, 'auth:refresh_token');

    if (!v2ApiColumnExists($pdo, 'kakiempa_v2_sessions', 'refresh_token_hash')) {
        v2ApiFail('refresh_unavailable', 'Refresh token belum tersedia. Silakan login ulang.', 501);
    }

    $refreshToken = trim((string) ($body['refresh_token'] ?? ''));
    if ($refreshToken === '' || !preg_match('/^refresh_[a-f0-9]{64}$/', $refreshToken)) {
        v2ApiSecurityLog($pdo, 'invalid_refresh_token');
        v2ApiFail('invalid_refresh_token', 'Refresh token tidak valid.', 401);
    }

    $stmt = $pdo->prepare(
        'SELECT s.user_id, s.phone, s.role, s.refresh_expires_at, u.name, u.is_active
         FROM kakiempa_v2_sessions s
         INNER JOIN kakiempa_v2_users u ON u.id = s.user_id
         WHERE s.refresh_token_hash = :hash LIMIT 1',
    );
    $stmt->execute(['hash' => hash('sha256', $refreshToken)]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!is_array($row) || !(int) $row['is_active']) {
        v2ApiSecurityLog($pdo, 'invalid_refresh_token');
        v2ApiFail('invalid_refresh_token', 'Refresh token tidak ditemukan.', 401);
    }

    $refreshExpires = new DateTimeImmutable((string) $row['refresh_expires_at'], new DateTimeZone('UTC'));
    if ($refreshExpires < new DateTimeImmutable('now', new DateTimeZone('UTC'))) {
        v2ApiSecurityLog($pdo, 'refresh_token_expired', (int) $row['user_id']);
        v2ApiFail('refresh_token_expired', 'Refresh token kedaluwarsa. Silakan login ulang.', 401);
    }

    $pdo->prepare('DELETE FROM kakiempa_v2_sessions WHERE refresh_token_hash = ?')->execute([
        hash('sha256', $refreshToken),
    ]);

    v2ApiRespond(kakiempat_v2_auth_success(
        (int) $row['user_id'],
        (string) $row['phone'],
        (string) $row['role'],
        (string) $row['name'],
        $pdo,
    ));
}

function kakiempat_v2_auth_logout(PDO $pdo): void
{
    $token = kakiempat_v2_extract_bearer_token();
    if ($token === '' || !preg_match('/^native_[a-f0-9]{64}$/', $token)) {
        v2ApiFail('token_required', 'Token tidak ditemukan.', 401);
    }

    $pdo->prepare('DELETE FROM kakiempa_v2_sessions WHERE token_hash = ?')->execute([
        hash('sha256', $token),
    ]);

    kakiempat_v2_clear_sso_cookie();
    v2ApiRespondData(['message' => 'Berhasil keluar.']);
}

function kakiempat_v2_auth_change_password(PDO $pdo, array $body): void
{
    $auth = v2ApiRequireAuth($pdo);
    $current = (string) ($body['current_password'] ?? '');
    $next = (string) ($body['new_password'] ?? '');

    if ($current === '') {
        v2ApiFail('invalid_password', 'Kata sandi saat ini wajib diisi.', 400);
    }
    if (!kakiempat_v2_validate_password($next)) {
        v2ApiFail('invalid_password', 'Kata sandi baru minimal 6 karakter.', 400);
    }

    $stmt = $pdo->prepare(
        'SELECT password_hash FROM kakiempa_v2_users WHERE id = ? LIMIT 1',
    );
    $stmt->execute([$auth['user_id']]);
    $hash = (string) ($stmt->fetchColumn() ?: '');
    if ($hash === '' || !password_verify($current, $hash)) {
        v2ApiFail('wrong_password', 'Kata sandi saat ini salah.', 401);
    }

    $pdo->prepare('UPDATE kakiempa_v2_users SET password_hash = ? WHERE id = ?')->execute([
        password_hash($next, PASSWORD_BCRYPT),
        $auth['user_id'],
    ]);

    v2ApiRespondData(['message' => 'Kata sandi berhasil diubah.']);
}

function kakiempat_v2_auth_session_from_refresh(PDO $pdo, string $refreshToken): array
{
    if ($refreshToken === '' || !preg_match('/^refresh_[a-f0-9]{64}$/', $refreshToken)) {
        v2ApiSecurityLog($pdo, 'invalid_refresh_token');
        v2ApiFail('invalid_refresh_token', 'Sesi SSO tidak valid. Silakan masuk lagi.', 401);
    }

    if (!v2ApiColumnExists($pdo, 'kakiempa_v2_sessions', 'refresh_token_hash')) {
        v2ApiFail('refresh_unavailable', 'SSO belum tersedia. Silakan login ulang.', 501);
    }

    $stmt = $pdo->prepare(
        'SELECT s.user_id, s.phone, s.role, s.refresh_expires_at, u.name, u.is_active
         FROM kakiempa_v2_sessions s
         INNER JOIN kakiempa_v2_users u ON u.id = s.user_id
         WHERE s.refresh_token_hash = :hash LIMIT 1',
    );
    $stmt->execute(['hash' => hash('sha256', $refreshToken)]);
    $row = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!is_array($row) || !(int) $row['is_active']) {
        v2ApiSecurityLog($pdo, 'invalid_refresh_token');
        v2ApiFail('invalid_refresh_token', 'Sesi SSO tidak ditemukan.', 401);
    }

    $refreshExpires = new DateTimeImmutable((string) $row['refresh_expires_at'], new DateTimeZone('UTC'));
    if ($refreshExpires < new DateTimeImmutable('now', new DateTimeZone('UTC'))) {
        v2ApiSecurityLog($pdo, 'refresh_token_expired', (int) $row['user_id']);
        v2ApiFail('refresh_token_expired', 'Sesi SSO kedaluwarsa. Silakan masuk lagi.', 401);
    }

    $pdo->prepare('DELETE FROM kakiempa_v2_sessions WHERE refresh_token_hash = ?')->execute([
        hash('sha256', $refreshToken),
    ]);

    return kakiempat_v2_auth_success(
        (int) $row['user_id'],
        (string) $row['phone'],
        (string) $row['role'],
        (string) $row['name'],
        $pdo,
    );
}

function kakiempat_v2_auth_sso_bootstrap(PDO $pdo): void
{
    v2ApiRateLimit($pdo, 'auth:sso_bootstrap', 20, 300);

    $refreshToken = kakiempat_v2_extract_sso_refresh_cookie();
    if ($refreshToken === '') {
        $body = kakiempat_v2_auth_read_json_body();
        $refreshToken = trim((string) ($body['refresh_token'] ?? ''));
    }
    if ($refreshToken === '') {
        v2ApiFail('sso_required', 'Tidak ada sesi SSO. Silakan masuk di www.kakiempat.com.', 401);
    }

    v2ApiRespond(kakiempat_v2_auth_session_from_refresh($pdo, $refreshToken));
}

function kakiempat_v2_auth_sso_handoff_create(PDO $pdo): void
{
    v2ApiRateLimit($pdo, 'auth:sso_handoff', 10, 300);

    $auth = v2ApiRequireAuth($pdo);
    if (!v2ApiTableExists($pdo, 'kakiempa_v2_sso_handoffs')) {
        v2ApiFail('sso_unavailable', 'SSO handoff belum tersedia.', 501);
    }

    $code = KAKIEMPAT_V2_SSO_HANDOFF_PREFIX . bin2hex(random_bytes(24));
    $expires = (new DateTimeImmutable('now', new DateTimeZone('UTC')))
        ->modify('+' . KAKIEMPAT_V2_SSO_HANDOFF_SECONDS . ' seconds')
        ->format('Y-m-d H:i:s.u');

    $pdo->prepare(
        'INSERT INTO kakiempa_v2_sso_handoffs (code_hash, user_id, expires_at)
         VALUES (:hash, :uid, :exp)',
    )->execute([
        'hash' => hash('sha256', $code),
        'uid' => (int) $auth['user_id'],
        'exp' => $expires,
    ]);

    v2ApiRespondData([
        'code' => $code,
        'expires_in' => KAKIEMPAT_V2_SSO_HANDOFF_SECONDS,
    ]);
}

function kakiempat_v2_auth_sso_handoff_consume(PDO $pdo, array $body): void
{
    v2ApiRateLimit($pdo, 'auth:sso_consume', 20, 300);

    $code = trim((string) ($body['code'] ?? ''));
    if ($code === '' || !preg_match('/^sso_[a-f0-9]{48}$/', $code)) {
        v2ApiFail('invalid_sso_code', 'Kode SSO tidak valid.', 401);
    }
    if (!v2ApiTableExists($pdo, 'kakiempa_v2_sso_handoffs')) {
        v2ApiFail('sso_unavailable', 'SSO handoff belum tersedia.', 501);
    }

    $pdo->beginTransaction();
    try {
        $stmt = $pdo->prepare(
            'SELECT user_id, expires_at, consumed_at
             FROM kakiempa_v2_sso_handoffs
             WHERE code_hash = :hash
             FOR UPDATE',
        );
        $stmt->execute(['hash' => hash('sha256', $code)]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!is_array($row)) {
            $pdo->rollBack();
            v2ApiSecurityLog($pdo, 'invalid_sso_code');
            v2ApiFail('invalid_sso_code', 'Kode SSO tidak ditemukan atau sudah dipakai.', 401);
        }
        if ($row['consumed_at'] !== null) {
            $pdo->rollBack();
            v2ApiFail('invalid_sso_code', 'Kode SSO sudah dipakai.', 401);
        }

        $expires = new DateTimeImmutable((string) $row['expires_at'], new DateTimeZone('UTC'));
        if ($expires < new DateTimeImmutable('now', new DateTimeZone('UTC'))) {
            $pdo->rollBack();
            v2ApiFail('sso_code_expired', 'Kode SSO kedaluwarsa. Silakan masuk lagi.', 401);
        }

        $userId = (int) $row['user_id'];
        $userStmt = $pdo->prepare(
            'SELECT id, name, whatsapp, role, is_active FROM kakiempa_v2_users WHERE id = ? LIMIT 1',
        );
        $userStmt->execute([$userId]);
        $user = $userStmt->fetch(PDO::FETCH_ASSOC);
        if (!is_array($user) || !(int) $user['is_active']) {
            $pdo->rollBack();
            v2ApiFail('user_not_found', 'Akun tidak ditemukan.', 401);
        }

        $pdo->prepare(
            'UPDATE kakiempa_v2_sso_handoffs SET consumed_at = CURRENT_TIMESTAMP(6) WHERE code_hash = ?',
        )->execute([hash('sha256', $code)]);
        $pdo->commit();

        v2ApiRespond(kakiempat_v2_auth_success(
            $userId,
            (string) ($user['whatsapp'] ?? ''),
            (string) $user['role'],
            (string) $user['name'],
            $pdo,
        ));
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        error_log('auth_v2 sso_consume: ' . $e->getMessage());
        v2ApiFail('sso_failed', 'Gagal masuk otomatis. Silakan coba lagi.', 500);
    }
}

function kakiempat_v2_auth_forgot_password(PDO $pdo, array $body): void
{
    v2ApiRateLimit($pdo, 'auth:forgot_password', 5, 900);

    $phone = kakiempat_v2_normalize_phone((string) ($body['phone'] ?? ''));
    $genericMessage =
        'Jika nomor terdaftar, kode reset dikirim ke notifikasi aplikasi Anda.';

    if ($phone === null) {
        v2ApiRespond(['ok' => true, 'message' => $genericMessage]);
        return;
    }

    if (!v2ApiTableExists($pdo, 'kakiempa_v2_password_resets')) {
        v2ApiFail('reset_unavailable', 'Reset kata sandi belum tersedia.', 501);
    }

    $stmt = $pdo->prepare(
        'SELECT id FROM kakiempa_v2_users WHERE whatsapp = :phone AND is_active = 1 LIMIT 1',
    );
    $stmt->execute(['phone' => $phone]);
    $userId = (int) ($stmt->fetchColumn() ?: 0);

    if ($userId > 0) {
        $token = KAKIEMPAT_V2_RESET_PREFIX . bin2hex(random_bytes(24));
        $expires = (new DateTimeImmutable('now', new DateTimeZone('UTC')))
            ->modify('+' . KAKIEMPAT_V2_RESET_MINUTES . ' minutes')
            ->format('Y-m-d H:i:s.u');

        $pdo->prepare('DELETE FROM kakiempa_v2_password_resets WHERE user_id = ?')->execute([$userId]);
        $pdo->prepare(
            'INSERT INTO kakiempa_v2_password_resets (token_hash, user_id, expires_at)
             VALUES (:hash, :uid, :exp)',
        )->execute([
            'hash' => hash('sha256', $token),
            'uid' => $userId,
            'exp' => $expires,
        ]);

        require_once __DIR__ . '/kakiempat_event_notifications.php';
        kakiempat_in_app_notifications_insert(
            $pdo,
            $userId,
            'Reset Kata Sandi',
            'Kode reset Anda: ' . $token . '. Berlaku ' . KAKIEMPAT_V2_RESET_MINUTES
                . ' menit. Buka www.kakiempat.com/?auth=reset untuk memasukkan kode.',
            null,
            'security',
        );

        v2ApiSecurityLog($pdo, 'password_reset_requested', $userId, ['phone' => $phone]);
    } else {
        v2ApiSecurityLog($pdo, 'password_reset_unknown_phone', null, ['phone' => $phone]);
    }

    v2ApiRespond(['ok' => true, 'message' => $genericMessage]);
}

function kakiempat_v2_auth_reset_password(PDO $pdo, array $body): void
{
    v2ApiRateLimit($pdo, 'auth:reset_password', 10, 900);

    $phone = kakiempat_v2_normalize_phone((string) ($body['phone'] ?? ''));
    $resetCode = trim((string) ($body['reset_code'] ?? $body['reset_token'] ?? ''));
    $password = (string) ($body['new_password'] ?? '');

    if ($phone === null) {
        v2ApiFail(
            'invalid_phone',
            'Format nomor tidak dikenali. Gunakan 08xx, 62xx, atau +62xx.',
            400,
        );
    }
    if ($resetCode === '' || !preg_match('/^reset_[a-f0-9]{48}$/', $resetCode)) {
        v2ApiFail('invalid_reset_code', 'Kode reset tidak valid.', 400);
    }
    if (!kakiempat_v2_validate_password($password)) {
        v2ApiFail('invalid_password', 'Kata sandi baru minimal 6 karakter.', 400);
    }
    if (!v2ApiTableExists($pdo, 'kakiempa_v2_password_resets')) {
        v2ApiFail('reset_unavailable', 'Reset kata sandi belum tersedia.', 501);
    }

    $pdo->beginTransaction();
    try {
        $stmt = $pdo->prepare(
            'SELECT r.user_id, r.expires_at, r.used_at
             FROM kakiempa_v2_password_resets r
             INNER JOIN kakiempa_v2_users u ON u.id = r.user_id
             WHERE r.token_hash = :hash AND u.whatsapp = :phone AND u.is_active = 1
             FOR UPDATE',
        );
        $stmt->execute([
            'hash' => hash('sha256', $resetCode),
            'phone' => $phone,
        ]);
        $row = $stmt->fetch(PDO::FETCH_ASSOC);
        if (!is_array($row) || $row['used_at'] !== null) {
            $pdo->rollBack();
            v2ApiSecurityLog($pdo, 'invalid_reset_code', null, ['phone' => $phone]);
            v2ApiFail('invalid_reset_code', 'Kode reset tidak valid atau sudah dipakai.', 401);
        }

        $expires = new DateTimeImmutable((string) $row['expires_at'], new DateTimeZone('UTC'));
        if ($expires < new DateTimeImmutable('now', new DateTimeZone('UTC'))) {
            $pdo->rollBack();
            v2ApiFail('reset_code_expired', 'Kode reset kedaluwarsa. Minta kode baru.', 401);
        }

        $userId = (int) $row['user_id'];
        $pdo->prepare('UPDATE kakiempa_v2_users SET password_hash = ? WHERE id = ?')->execute([
            password_hash($password, PASSWORD_BCRYPT),
            $userId,
        ]);
        $pdo->prepare(
            'UPDATE kakiempa_v2_password_resets SET used_at = CURRENT_TIMESTAMP(6) WHERE token_hash = ?',
        )->execute([hash('sha256', $resetCode)]);
        $pdo->prepare('DELETE FROM kakiempa_v2_sessions WHERE user_id = ?')->execute([$userId]);
        $pdo->commit();

        kakiempat_v2_clear_sso_cookie();
        v2ApiSecurityLog($pdo, 'password_reset_completed', $userId);
        v2ApiRespondData(['message' => 'Kata sandi berhasil diubah. Silakan masuk.']);
    } catch (Throwable $e) {
        if ($pdo->inTransaction()) {
            $pdo->rollBack();
        }
        error_log('auth_v2 reset_password: ' . $e->getMessage());
        v2ApiFail('reset_failed', 'Gagal mengubah kata sandi. Coba lagi.', 500);
    }
}
