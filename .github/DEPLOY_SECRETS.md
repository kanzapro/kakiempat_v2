# GitHub Actions — cPanel Git Deploy (Kaki Empat v2)

FTP/SFTP **diblokir** firewall hosting. Deploy hanya lewat **git push → cPanel pull → `.cpanel.yml`**.

| Workflow | Pemicu | Fungsi |
|----------|--------|--------|
| [`deploy.yml`](workflows/deploy.yml) | Push `main`/`master`, manual dispatch | Picu `VersionControl/update` di cPanel |

## 6 domain (docroot relatif `/home/kakiempa/`)

| Domain | Docroot | Artefak di repo |
|--------|---------|-----------------|
| `www.kakiempat.com` | `public_html/` | `build/deploy/www/web/` |
| `owner.kakiempat.com` | `owner.kakiempat.com/` | `build/deploy/owner/web/` |
| `sitter.kakiempat.com` | `sitter.kakiempat.com/` | `build/deploy/sitter/web/` |
| `admin.kakiempat.com` | `admin.kakiempat.com/` | `build/deploy/admin/web/` |
| `staging.kakiempat.com` | `staging.kakiempat.com/` | `build/deploy/staging/web/` |
| `api.kakiempat.com` | `api.kakiempat.com/` | `build/deploy_api/` |

> **Bukan** `public_html/owner/` — setiap subdomain punya docroot terpisah di cPanel.

## 1. Setup cPanel (sekali, lewat browser)

1. cPanel → **Git™ Version Control** → **Create**
2. Clone URL: repo GitHub Kaki Empat v2
3. Repository Path: `/home/kakiempa/repo_kakiempat` (di luar docroot publik)
4. Branch: `main`
5. Aktifkan **Pull & Deploy** / deployment hook (`.cpanel.yml` di root repo)

## 2. Buat API Token cPanel

1. cPanel → **Manage API Tokens** → Create
2. GitHub → **Settings → Secrets → Actions** → `CPANEL_API_TOKEN`
3. Opsional: `CPANEL_REPO_PATH` = `/home/kakiempa/repo_kakiempat`

## 3. Cara deploy (solo dev)

```powershell
.\scripts\deploy_git.ps1 -Layer all -WebRenderer html
git add build/deploy build/deploy_api hosting/
git commit -m "deploy: <deskripsi>"
git push origin main
```

GitHub Actions memanggil:

```http
GET https://kakiempat.com:2083/execute/VersionControl/update
  ?repository_root=/home/kakiempa/repo_kakiempat&branch=main
Authorization: cpanel kakiempa:<CPANEL_API_TOKEN>
```

cPanel menjalankan `scripts/ci/cpanel_deploy.sh` via `.cpanel.yml`.

## 4. File yang tidak di-rsync ke produksi

- `.mysql_v2.php`, `.migrate_v2_secret`
- `.payment_webhook_secret`, `.payment_config.php`
- `uploads/**`, `backups/**` (tetap di server)

## 5. Verifikasi

- API: `https://www.api.kakiempat.com/health.php`
- Owner: `https://owner.kakiempat.com`
- Manual: `.\scripts\trigger_cpanel_deploy.ps1`

## 6. Troubleshooting

| Gejala | Cek |
|--------|-----|
| Workflow gagal HTTP 401 | `CPANEL_API_TOKEN` salah/expired |
| Web tidak berubah | Apakah `build/deploy/<target>/web/` ikut di-commit? |
| API tidak berubah | Jalankan `deploy_git.ps1 -Layer api`, commit `build/deploy_api/` |
| `.cpanel.yml` error | cPanel → Git → **Deployment** log |
