# Log transaksi Notification Forwarder

Produksi **Kaki Empat v2** memakai **MySQL** (`kakiempa_v2`), bukan PostgreSQL. Skrip PostgreSQL di folder `postgresql/` hanya referensi arsitektur.

## Pemetaan skema

| PostgreSQL (referensi) | MySQL v2 (produksi) |
|------------------------|---------------------|
| `users` | `kakiempa_v2_users` |
| `pets` | `kakiempa_v2_pets` |
| `bookings.total_amount` | `kakiempa_v2_bookings.payment_amount` (INTEGER IDR, contoh `150102`) |
| `bookings.status` | `kakiempa_v2_bookings.status` (`awaitingPayment`, `paid`, …) |
| `transaction_logs` | `kakiempa_v2_transaction_logs` |
| `in_app_notifications` | `kakiempa_v2_in_app_notifications` |
| `idx_bookings_lookup_amount` | `idx_v2_bookings_lookup_amount` (`payment_amount`, `status`) |
| `idx_notif_user_unread` | `idx_v2_notif_user_unread` (`user_id`, `is_read`) |
| `idx_transaction_amount` | `idx_v2_transaction_amount` |

Migrasi notifikasi: `009_in_app_notifications.sql`

Migrasi MySQL: `007_transaction_logs_optimization.sql`, lalu `011_transaction_logs_sender_source.sql`

`sender_bank`: `SEABANK_WISE` | `SEABANK_REVOLUT` | `SEABANK_TRANSFER`

## Alur webhook

1. Booking dibuat dengan `payment_amount = 150102`, `status = awaitingPayment`
2. Android Forwarder POST ke `payment_webhook.php` + header `X-Payment-Webhook-Secret`
3. PHP: `hash_equals` token → `SELECT … WHERE status='awaitingPayment' AND payment_amount=150102`
4. `UPDATE status='paid'`, insert `kakiempa_v2_transaction_logs`, notifikasi owner/sitter

## Mengapa DECIMAL / INTEGER, bukan FLOAT

Nominal unik (150102) harus cocok persis. `DECIMAL(12,2)` di MySQL / `NUMERIC` di PostgreSQL menghindari error pembulatan float.

## Deploy migrasi

```text
GET apply_v2_migration.php?secret=...&file=007_transaction_logs_optimization.sql
```
