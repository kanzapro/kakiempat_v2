# hosting_v2

Salinan sinkron dari **`hosting/api.kakiempat.com`** (sumber deploy: `scripts/deploy_api.ps1`).

Jalankan ulang sinkron setelah mengubah API di folder `hosting/`:

```powershell
Remove-Item hosting_v2\api -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item hosting\api.kakiempat.com\* hosting_v2\api -Recurse -Force
```
