# Notification Forwarder (SeaBank → Kaki Empat API)

Aplikasi Android mandiri (bukan Flutter) yang membaca notifikasi transfer masuk SeaBank di HP pengguna dan mengirim webhook ke server Kaki Empat.

## Instal APK

1. Salin `app-release.apk` ke HP (USB, Google Drive, atau folder Download).
2. Di Android, aktifkan **Instal dari sumber tidak dikenal** untuk file manager / browser yang dipakai.
3. Buka APK → **Instal** → buka aplikasi **Kaki Empat Payment Forwarder**.

Atau dari PC (ADB):

```bash
adb install -r app/build/outputs/apk/release/app-release.apk
```

## Aktifkan akses notifikasi

1. Buka aplikasi → tap **Buka akses notifikasi**.
2. Di **Akses notifikasi**, aktifkan untuk **Kaki Empat Payment Forwarder**.
3. Kembali ke app → **Periksa status** harus menampilkan **Listening**.
4. Pastikan notifikasi SeaBank tidak dibisukan di pengaturan sistem.

## Konfigurasi webhook secret (wajib)

Server API: salin `.payment_webhook_secret.example` → `.payment_webhook_secret` di docroot `api.kakiempat.com` (satu baris token).

Android: salin `local.properties.example` → `local.properties`:

```properties
payment.webhook.secret=KE_SECURE_NOTIF_TOKEN_2026_BYPASS
```

Token **harus identik** di server dan APK. PHP memverifikasi dengan `hash_equals()` (anti timing attack). Tanpa header `X-Payment-Webhook-Secret` yang valid → **HTTP 401**.

Uji dari PC:

```powershell
.\scripts\test_payment_webhook_auth.ps1 -ApiBase https://www.api.kakiempat.com
```

## Konfigurasi webhook URL

Default: `https://www.api.kakiempat.com/payment_webhook.php` (di `app/build.gradle.kts`).

Body JSON:

```json
{
  "nominal": 250000,
  "bank": "SeaBank",
  "nama": "BUDI SANTOSO",
  "timestamp": 1717550000000
}
```

(Field `bank_pengirim` / `nama_pengirim` juga dikirim untuk kompatibilitas API.)

## Build APK

**Debug (cepat, untuk HP uji):**

```powershell
cd android_app\NotificationForwarder
.\gradlew.bat assembleDebug
```

Output: `app\build\outputs\apk\debug\app-debug.apk`

**Release:**

```powershell
.\gradlew.bat assembleRelease
```

Output: `app\build\outputs\apk\release\app-release.apk`

Pastikan `local.properties` berisi `payment.webhook.secret` (sama dengan `.payment_webhook_secret` di server).

Windows: `gradle.properties` mengarahkan JDK ke JBR Android Studio.

`gradle.properties` sudah mengarahkan `org.gradle.java.home` ke JBR Android Studio bila tersedia.

## Paket SeaBank

Daftar package di `NotificationListener.kt` (`SEA_BANK_PACKAGES`). Tambahkan package name jika berbeda di perangkat (mis. `com.seabank.android`).

## Verifikasi

1. Instal APK dan aktifkan akses notifikasi.
2. Uji dengan notifikasi transfer masuk SeaBank nyata, atau kirim notifikasi uji dari app lain (hanya untuk cek parsing jika teks mirip format SeaBank).
3. Di aplikasi, cek **Log webhook** — entri `OK 200` berarti server menerima.
4. Opsional di PC: `scripts/test_payment_automation.ps1` untuk simulasi webhook langsung ke API.

## Arsitektur

| File | Peran |
|------|--------|
| `NotificationListener.kt` | `NotificationListenerService`, filter SeaBank, parse teks |
| `WebhookSender.kt` | OkHttp POST + retry |
| `MainActivity.kt` | Status Listening / Not listening + log |
