# Deploy Kaki Empat v2

Panduan rilis production: Flutter web (6 subdomain) + API PHP self-hosted di cPanel.

> **Stack:** Flutter web → `api.kakiempat.com` (PHP) → MySQL `kakiempa_v2`  
> **Tanpa** Firebase, FCM, Supabase, atau BaaS pihak ketiga.

---

## 1. Prasyarat

| Item | Lokasi |
|------|--------|
| Kredensial cPanel + API token | `.cursor/secrets/hosting.credentials` (salin dari `.example`) |
| Env lokal (opsional) | `.env` dari `.env.example` |
| Flutter SDK | 3.11+ |
| PowerShell | Windows (skrip deploy) |

---

## 2. Build production (lokal)

```powershell
cd d:\Project_Flutter\kakiempat_v2
.\scripts\build_release_v2.ps1
```

Skrip ini menjalankan:

1. `flutter clean`
2. `flutter pub get`
3. `flutter analyze`
4. `flutter build web --release --no-tree-shake-icons --dart-define=API_BASE_URL=https://www.api.kakiempat.com`
5. ZIP per subdomain → `build/release_v2/`
6. Paket API → `build/deploy_api/`

### Optimasi build

| Aspek | Keterangan |
|-------|------------|
| **Minifikasi JS** | Otomatis di `--release` (`main.dart.js` ter-minify) |
| **Tree shaking** | Otomatis di release mode (kode Dart tidak terpakai dihapus) |
| **Icons** | `--no-tree-shake-icons` — semua Material Icons disertakan (ukuran lebih besar, aman untuk semua ikon UI) |
| **Gambar** | Saat ini app tanpa asset gambar berat; tambahkan asset ke `pubspec.yaml` lalu kompres WebP/PNG sebelum rilis |
| **Renderer web** | Default Flutter web (CanvasKit/Skwasm); untuk ukuran lebih kecil pertimbangkan `--wasm` di versi Flutter mendatang |

Output:

```
build/web/                    # Hasil build Flutter
build/release_v2/
  www-deploy.zip              # → public_html
  owner-deploy.zip            # → owner.kakiempat.com
  sitter-deploy.zip           # → sitter.kakiempat.com
  admin-deploy.zip            # → admin.kakiempat.com
  release_manifest.json
build/deploy_api/             # Upload ke api.kakiempat.com
```

---

## 3. Deploy ke cPanel

### 3.1 Subdomain & docroot

| Subdomain | Docroot cPanel | ZIP |
|-----------|----------------|-----|
| `www.kakiempat.com` | `public_html` | `www-deploy.zip` |
| `owner.kakiempat.com` | `owner.kakiempat.com` | `owner-deploy.zip` |
| `sitter.kakiempat.com` | `sitter.kakiempat.com` | `sitter-deploy.zip` |
| `admin.kakiempat.com` | `admin.kakiempat.com` | `admin-deploy.zip` |
| `staging.kakiempat.com` | `staging.kakiempat.com` | (opsional, sama isi build) |
| `api.kakiempat.com` | `api.kakiempat.com` | `build/deploy_api/*` |

### 3.2 Deploy otomatis (Git → cPanel, tanpa FTP)

FTP/SFTP diblokir firewall. Gunakan **cPanel Git™ Version Control** + `.cpanel.yml`.

```powershell
# Build + paket semua domain
.\scripts\deploy_git.ps1 -Layer all -WebRenderer html

# Commit artefak + push
git add build/deploy build/deploy_api hosting/
git commit -m "deploy: <deskripsi>"
git push origin main
```

GitHub Actions memicu `VersionControl/update` → server git pull → `scripts/ci/cpanel_deploy.sh` rsync ke docroot.

Setup sekali: lihat `.github/DEPLOY_SECRETS.md` (API token + repo path `/home/kakiempa/repo_kakiempat`).

### 3.3 Darurat manual (File Manager)

Jika git deploy gagal, ekstrak ZIP dari `build/release_v2/` ke docroot via File Manager.

**API manual:** upload isi `build/deploy_api/` ke `api.kakiempat.com`. Pastikan `schema/mysql/` ikut.

File secret di server (jangan commit):

| File server | Isi |
|-------------|-----|
| `.mysql_v2.php` | Return array `host`, `db`, `user`, `pass` |
| `.migrate_v2_secret` | Secret migrasi & backup HTTP |
| `.payment_config.php` | Konfigurasi rekening (opsional) |
| `.payment_webhook_secret` | Secret webhook simulasi (opsional) |

Template MySQL: salin dari `[mysql_v2]` di `hosting.credentials`.

### 3.4 Picu deploy manual dari laptop

```powershell
.\scripts\trigger_cpanel_deploy.ps1
```

Butuh `CPANEL_API_TOKEN` (env) atau `cpanel.api_token` di `hosting.credentials`.

---

## 4. Konfigurasi environment

### 4.1 Lokal (developer)

File `.env` (gitignored):

```ini
CPANEL_MYSQL_HOST=localhost
CPANEL_MYSQL_DATABASE=kakiempa_v2
CPANEL_MYSQL_USER=kakiempa_v2_user
CPANEL_MYSQL_PASSWORD=***
V2_MIGRATE_SECRET=***
API_BASE_URL=https://www.api.kakiempat.com
```

### 4.2 Build Flutter (dart-define)

Production web embed:

```
API_BASE_URL=https://www.api.kakiempat.com
```

Jangan embed password MySQL di build web production.

### 4.3 Server API

- **`.mysql_v2.php`** — koneksi DB (wajib)
- **`.migrate_v2_secret`** — migrasi SQL & backup HTTP
- **`.htaccess`** — HTTPS, deny akses file `.mysql_v2.php`, `.env`, schema

### 4.4 CORS

File: `hosting/api.kakiempat.com/cors.php`

Origin diizinkan:

- `https://www.kakiempat.com`
- `https://kakiempat.com`
- `https://owner.kakiempat.com`
- `https://sitter.kakiempat.com`
- `https://admin.kakiempat.com`
- `https://staging.kakiempat.com`
- `http://localhost` / `http://127.0.0.1` (dev)

Setelah ubah CORS, deploy ulang `cors.php` ke API.

---

## 5. Migrasi database

Urutan file: `hosting/api.kakiempat.com/schema/mysql/001_*.sql` … `017_*.sql`

```powershell
# Satu file
.\scripts\run_v2_migration.ps1 -File 001_core_tables.sql

# Secret dari hosting.credentials [api_deploy] migrate_secret
# atau .env V2_MIGRATE_SECRET
```

URL:

```
GET https://www.api.kakiempat.com/apply_v2_migration.php?secret=SECRET&file=001_core_tables.sql
```

Verifikasi:

```powershell
curl https://api.kakiempat.com/health.php
# { "ok": true, "mysql_ok": true, ... }
```

---

## 6. Cron job backup database

Script: `backup_db_v2.php`

**Opsi A — CLI di server (disarankan):**

```cron
0 2 * * * /usr/local/bin/php /home/kakiempa/api.kakiempat.com/backup_db_v2.php
```

**Opsi B — HTTP (curl):**

```cron
0 2 * * * /usr/bin/curl -sS "https://api.kakiempat.com/backup_db_v2.php?key=SECRET" > /dev/null 2>&1
```

Secret = isi `.migrate_v2_secret` atau `V2_MIGRATE_SECRET`.

Backup disimpan: `/home/kakiempa/backups/` (retensi 7 hari).

Manual:

```powershell
.\scripts\run_backup_v2.ps1
```

---

## 7. Endpoint API v2

Base URL: `https://api.kakiempat.com` atau `https://www.api.kakiempat.com`

Format respons: `{ "ok": true, "data": ... }` atau `{ "ok": false, "error": "...", "message": "..." }`

Auth: `Authorization: Bearer <token>` (kecuali login/register/public).

### Utility

| Method | URL | Keterangan |
|--------|-----|------------|
| GET | `/health.php` | Health + `mysql_ok` |
| GET | `/index.php` | Info API |
| GET | `/apply_v2_migration.php?secret=&file=` | Migrasi SQL |
| GET | `/backup_db_v2.php?key=` | Backup DB |

### auth_v2.php

| Action | Method |
|--------|--------|
| `register` | POST |
| `login` | POST |
| `logout` | POST |
| `validate_token` | GET |
| `change_password` | POST |
| `refresh_token` | POST |

### owner_v2.php

| Action | Method |
|--------|--------|
| `get_profile` | GET |
| `save_profile` | POST |
| `add_pet` | POST |
| `update_pet` | POST |
| `delete_pet` | POST |

### sitter_v2.php

| Action | Method |
|--------|--------|
| `get_profile` | GET |
| `save_profile` | POST |
| `submit_verification` | POST |
| `get_wallet` | GET |
| `request_withdraw` | POST |
| `list_my_withdrawals` | GET |

### service_v2.php

| Action | Method |
|--------|--------|
| `get_catalog` | GET |

### marketplace_v2.php

| Action | Method |
|--------|--------|
| `create_request` | POST |
| `list_requests` | GET |
| `list_my_requests` | GET |
| `list_offers` | GET |
| `create_offer` | POST |
| `accept_offer` | POST |

### booking_v2.php

| Action | Method |
|--------|--------|
| `create_request` | POST |
| `list_incoming_requests` | GET |
| `accept_request` | POST |
| `reject_request` | POST |
| `get_booking` | GET |
| `list_my_bookings` | GET |
| `sitter_confirm` | POST |
| `sitter_en_route` | POST |
| `start_booking` | POST |
| `complete_booking` | POST |
| `cancel_booking` | POST |

### payment_v2.php

| Action | Method |
|--------|--------|
| `submit_payment_proof` | POST |
| `admin_approve_payment` | POST |
| `admin_reject_payment` | POST |
| `list_pending_verification` | GET |
| `get_payment_config` | GET |

### wallet_v2.php

| Action | Method |
|--------|--------|
| `get_balance` | GET |
| `get_ledger` | GET |
| `request_withdrawal` | POST |

### chat_v2.php

| Action | Method |
|--------|--------|
| `send_message` | POST |
| `get_messages` | GET |
| `check_new_messages` | GET |

### notification_v2.php

| Action | Method |
|--------|--------|
| `check_new` | GET |
| `get_notifications` | GET |
| `mark_read` | POST |

### review_v2.php

| Action | Method |
|--------|--------|
| `submit_review` | POST |
| `get_sitter_reviews` | GET |
| `list_booking_review` | GET |

### admin_v2.php

| Action | Method |
|--------|--------|
| `list_pending_sitters` | GET |
| `list_sitters` | GET |
| `list_owners` | GET |
| `list_bookings` | GET |
| `list_pending_withdrawals` | GET |
| `approve_sitter` | POST |
| `reject_sitter` | POST |
| `approve_withdrawal` | POST |
| `reject_withdrawal` | POST |

### Legacy / webhook

| File | Fungsi |
|------|--------|
| `payment_webhook.php` | Webhook simulasi pembayaran |
| `payment_status.php` | Cek status pembayaran |
| `get_notifications.php` | Legacy notifikasi |
| `get_unread_notifications.php` | Legacy unread |

---

## 8. Verifikasi setelah deploy

```powershell
# Audit pra-rilis (lokal)
.\scripts\verify_release_v2.ps1

# Integrasi API penuh
.\scripts\verify_final_v2.ps1

# Health cepat
curl https://api.kakiempat.com/health.php
```

Smoke test manual:

1. `owner.kakiempat.com` — login owner, buat request
2. `sitter.kakiempat.com` — login sitter, kirim offer
3. `admin.kakiempat.com` — approve sitter / payment
4. Notifikasi in-app (polling, bukan push eksternal)

---

## 9. Keamanan checklist

- [ ] Tidak ada password di repo (`hosting.credentials`, `.env`, `.mysql_v2.php` di-gitignore)
- [ ] Tidak ada Firebase/FCM/Supabase aktif di `lib/` atau `pubspec.yaml`
- [ ] `.htaccess` API deny file secret
- [ ] CORS hanya subdomain resmi
- [ ] SSL aktif (wildcard `*.kakiempat.com`)
- [ ] Backup cron terpasang

---

## 10. Rollback

**Frontend:** simpan ZIP rilis sebelumnya di `build/release_v2/`, extract ulang ke docroot.

**API:** restore dari backup `/home/kakiempa/backups/` atau deploy ulang commit sebelumnya.

**DB:** restore dump SQL dari backup (hati-hati data production).

---

*Dokumen ini untuk Kaki Empat v2 — self-hosted PHP + MySQL + Flutter web.*
