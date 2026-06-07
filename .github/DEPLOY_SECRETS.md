# GitHub Actions — FTP Deploy (Kaki Empat v2)

| Workflow | Pemicu | Target |
|----------|--------|--------|
| [`deploy.yml`](workflows/deploy.yml) | Push `main`/`master` (path filter) | **6 domain paralel** — hanya yang berubah |
| [`deploy-ftp.yml`](workflows/deploy-ftp.yml) | Manual (Actions → Run workflow) | api, owner, sitter, admin, staging, www |

Action: [SamKirkland/FTP-Deploy-Action](https://github.com/SamKirkland/FTP-Deploy-Action) (FTP/FTPS, **bukan SFTP**).

## 6 domain (docroot FTP relatif `/home/kakiempa/`)

| Domain | Docroot FTP | Path filter (delta) |
|--------|-------------|---------------------|
| `www.kakiempat.com` | `public_html/` | `lib/features/www/**`, `lib/core/**`, `web/**`, … |
| `owner.kakiempat.com` | `owner.kakiempat.com/` | `lib/features/owner/**`, `lib/core/**`, … |
| `sitter.kakiempat.com` | `sitter.kakiempat.com/` | `lib/features/sitter/**`, `lib/core/**`, … |
| `admin.kakiempat.com` | `admin.kakiempat.com/` | `lib/features/admin/**`, `lib/core/**`, … |
| `staging.kakiempat.com` | `staging.kakiempat.com/` | `lib/features/owner/**` (staging pakai owner shell), `lib/core/**`, … |
| `api.kakiempat.com` | `api.kakiempat.com/` | `hosting/api.kakiempat.com/**` |

> **Bukan** `public_html/owner/` — setiap subdomain punya docroot terpisah di cPanel.

Proyek ini **monolith Flutter** (satu `lib/`), bukan folder `www/` / `owner/` terpisah di root repo. Workflow mem-build sekali lalu matrix deploy paralel ke docroot yang benar.

## 1. Buat 4 Repository Secrets

Di GitHub: **Settings → Secrets and variables → Actions → New repository secret**

| Secret | Nilai | Catatan |
|--------|-------|---------|
| `FTP_SERVER` | `178.83.188.195` | Alternatif: `ftp.kakiempat.com` — **tanpa** `ftp://` |
| `FTP_USERNAME` | Username cPanel | Sama dengan `[cpanel] username` di `hosting.credentials` |
| `FTP_PASSWORD` | Password cPanel | Jangan commit ke repo |
| `FTP_PORT` | `21` | FTP biasa cPanel |

## 2. Cara deploy

### Otomatis (push ke `main` / `master`)

Workflow **Automatic Multi-Domain Deploy**:

1. `dorny/paths-filter` mendeteksi domain mana yang berubah
2. Jika ada perubahan web → `flutter build web` **sekali** (artifact shared)
3. Matrix **6 job paralel** — domain tanpa delta di-skip
4. FTP delta sync per docroot (IP runner GitHub, bukan laptop)

Contoh: edit hanya `lib/features/owner/**` → hanya `owner.kakiempat.com` yang di-deploy.

### Manual (semua target)

**Actions → Deploy via FTP → Run workflow**

| Target | Docroot FTP |
|--------|-------------|
| `api` | `api.kakiempat.com/` |
| `owner` | `owner.kakiempat.com/` |
| `sitter` | `sitter.kakiempat.com/` |
| `admin` | `admin.kakiempat.com/` |
| `staging` | `staging.kakiempat.com/` |
| `www` | `public_html/` |
| `owner-and-api` | API + owner (money engine) |

## 3. File yang tidak di-upload

- `.mysql_v2.php`, `.migrate_v2_secret`
- `.payment_webhook_secret`, `.payment_config.php`
- `uploads/**`, `backups/**`

## 4. Setelah secrets siap

1. Push repo ke GitHub.
2. Isi keempat secrets.
3. Push ke `main` (atau jalankan manual **Deploy via FTP** → `api` untuk uji koneksi).

Verifikasi:

- API: `https://www.api.kakiempat.com/health.php`
- Owner: `https://owner.kakiempat.com`

## 5. Deploy lokal (tetap tersedia)

```powershell
.\scripts\deploy_api.ps1
.\scripts\deploy_web.ps1 -Target owner -WebRenderer html -Upload
.\scripts\deploy_owner.ps1 -Layer both -WebRenderer html -Upload
```
