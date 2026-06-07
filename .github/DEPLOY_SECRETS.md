# GitHub Actions — FTP Deploy (Kaki Empat v2)

| Workflow | Pemicu | Target |
|----------|--------|--------|
| [`deploy.yml`](workflows/deploy.yml) | Push `main`/`master` (backend PHP) | `api.kakiempat.com/` otomatis |
| [`deploy-ftp.yml`](workflows/deploy-ftp.yml) | Manual (Actions → Run workflow) | api, owner, sitter, admin, staging, www |

Action: [SamKirkland/FTP-Deploy-Action](https://github.com/SamKirkland/FTP-Deploy-Action) (FTP/FTPS, **bukan SFTP**).

## 1. Buat 4 Repository Secrets

Di GitHub: **Settings → Secrets and variables → Actions → New repository secret**

| Secret | Nilai | Catatan |
|--------|-------|---------|
| `FTP_SERVER` | `178.83.188.195` | Alternatif: `ftp.kakiempat.com` atau `kakiempat.com` — **tanpa** `ftp://` |
| `FTP_USERNAME` | Username cPanel | Sama dengan `[cpanel] username` di `hosting.credentials` |
| `FTP_PASSWORD` | Password cPanel | Sama dengan `[cpanel] password` — jangan commit ke repo |
| `FTP_PORT` | `21` | FTP biasa cPanel. Port `22` hanya jika hosting memaksa SFTP (workflow ini tidak mendukung SFTP). |

> Password dan username juga ada di `.cursor/secrets/hosting.credentials` (lokal, gitignored).

## 2. Cara deploy

### Otomatis (push ke `main` / `master`)

Workflow **Super Charge Kaki Empat v2 Deploy** (`deploy.yml`): perubahan di `hosting/api.kakiempat.com/**` memicu deploy backend delta ke `api.kakiempat.com/`, lalu cek `health.php`.

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

Agar rahasia server tidak tertimpa, workflow mengecualikan:

- `.mysql_v2.php`, `.migrate_v2_secret`
- `.payment_webhook_secret`, `.payment_config.php`
- `uploads/**`, `backups/**`

## 4. Setelah secrets siap

1. Push repo ke GitHub (jika belum).
2. Isi keempat secrets di atas.
3. Jalankan workflow manual **Deploy via FTP** dengan target `api` (uji koneksi).
4. Lalu `owner` atau `owner-and-api` untuk money engine.

Verifikasi:

- API: `https://www.api.kakiempat.com/health.php`
- Owner: `https://owner.kakiempat.com`

## 5. Deploy lokal (tetap tersedia)

```powershell
.\scripts\deploy_api.ps1
.\scripts\deploy_via_ftp.ps1 -Target api

.\scripts\deploy_web.ps1 -Target owner -WebRenderer html -Upload
.\scripts\deploy_owner.ps1 -Layer both -WebRenderer html -Upload
```
