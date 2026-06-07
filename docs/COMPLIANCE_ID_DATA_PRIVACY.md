# Kepatuhan Data & Pembayaran — Indonesia (Kaki Empat v2)

Dokumen internal sebelum mengaktifkan **wallet**, **loyalty**, dan **referral** (`LaunchPhase.growth`). Bukan nasihat hukum; konsultasikan penasihat legal untuk keputusan final.

## Ruang lingkup data

| Data | Layanan | Penyimpanan |
|------|---------|-------------|
| Identitas & kontak | Auth, profil owner/sitter | MySQL `kakiempa_v2_users`, profil terkait |
| Lokasi | Booking, marketplace radius | Koordinat profil owner/sitter |
| Bukti bayar | Payment manual | `kakiempa_payment_proofs`, upload server |
| Dokumen verifikasi sitter | Admin approval | `profile_json` sitter (KTP/selfie) |
| Loyalty & referral | Growth | `kakiempa_v2_loyalty_*`, `kakiempa_v2_referral_*` |
| Komunitas | Gallery/stori | `kakiempa_v2_pet_gallery` |
| Wallet sitter | Growth | `kakiempa_v2_wallet_ledger`, penarikan admin |

## Prinsip governance (UU PDP / praktik 2026)

1. **Tujuan spesifik** — setiap fitur growth meminta data hanya untuk layanan pet care (booking, retensi, komunitas).
2. **Persetujuan eksplisit** — saat loyalty/referral/komunitas aktif, tampilkan persetujuan di registrasi/profil bahwa data booking dapat dipakai untuk poin dan rekomendasi (rule-based, tanpa ML eksternal).
3. **Minimisasi** — tidak mengumpulkan data di luar stack self-hosted (`api.kakiempat.com`); **tanpa** Firebase/analytics pihak ketiga (lihat rule `v2-stack-forbidden-services`).
4. **Hak subjek data** — sediakan kanal admin/founder untuk hapus akun dan ekspor data booking (proses manual cukup untuk MVP).
5. **Retensi** — bukti bayar & log transaksi: simpan minimal untuk audit pajak/penyelesaian sengketa; dokumen KTP sitter: enkripsi at-rest (schema `017`) + akses founder-only.

## Pembayaran & wallet

| Mode | Risiko regulasi | Keputusan v2 |
|------|-----------------|--------------|
| Bukti transfer manual + approval admin | Rendah (bukan stored value) | **Aktif** — fase ownerFirst |
| Ledger wallet sitter + penarikan | Menengah (pendapatan pengasuh) | **Growth** — wajib legal review sebelum skala |
| Wallet owner / top-up | Tinggi (e-money) | **Tidak direncanakan** tanpa izin payment gateway resmi |

Sebelum `LaunchPhase.growth`:

- [ ] Teks kebijakan privasi www memuat cross-service (booking → loyalty → komunitas).
- [ ] Syarat referral (bonus Rp 20.000, diskon 10%) jelas di FAQ/register.
- [ ] Prosedur admin untuk approve/reject bukti bayar terdokumentasi (SLA ≤ 24 jam).
- [ ] Audit log aksi admin payment/wallet (extend `admin_v2.php` jika diperlukan).

## Partner / discover (fase `full`)

Partner hanya via **deep link eksternal** (`partner_v2.php`); Kaki Empat tidak memproses pembayaran partner. Tampilkan disclaimer bahwa transaksi di situs partner tunduk kebijakan masing-masing.

## Kontak & insiden

- Pelaporan kebocoran: founder via admin panel + rotasi token/sesi SSO.
- Rotasi kredensial: hanya `.cursor/secrets/hosting.credentials` (jangan commit).

## Referensi teknis

- Notifikasi in-app polling: `notification_v2.php` (bukan push pihak ketiga).
- SSO subdomain: `kakiempat_sso_v2.php`, cookie `.kakiempat.com`.
- Exit criteria fase: [`LAUNCH_EXIT_CRITERIA.md`](LAUNCH_EXIT_CRITERIA.md).
