# Notifikasi in-app (file event log)

Pengganti email/WhatsApp — 100% self-hosted di server Kaki Empat v2.

## Folder server

**cPanel (produksi):**
```text
api.kakiempat.com/uploads/notifications/
```

**VPS (opsional):**
```bash
sudo mkdir -p /var/www/kakiempat/uploads/notifications
sudo chown -R $USER:$USER /var/www/kakiempat/uploads/notifications
sudo chmod -R 755 /var/www/kakiempat/uploads/notifications
```

Atau set path kustom via `.notifications_path.php` (salin dari `.notifications_path.php.example`).

## Alur

1. `payment_webhook.php` → booking `paid` → INSERT `kakiempa_v2_in_app_notifications` (+ file JSON fallback)
2. Flutter polling `GET get_unread_notifications.php` setiap **5 detik** (Bearer token)
3. Server auto `is_read=1` dalam transaksi; Flutter tampilkan overlay pop-up oranye
4. Legacy: `get_notifications.php` (satu notifikasi + `?mark_read=1`)

Migrasi DB: `009_in_app_notifications.sql`

## Format file `user_12.json`

```json
{
  "user_id": 12,
  "type": "payment_paid",
  "booking_id": 5,
  "message": "Payment received! Your booking #5 is now active.",
  "timestamp": 1717550000,
  "unread": true
}
```

## Endpoint

| URL | Auth |
|-----|------|
| `GET /get_notifications.php` | Bearer token |
| `GET /get_notifications.php?mark_read=1` | Tandai dibaca |

## Nginx statis (opsional)

Lihat `hosting/nginx/notifications-static.conf.example`.
