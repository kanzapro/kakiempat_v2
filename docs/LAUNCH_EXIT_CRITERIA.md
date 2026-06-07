# Kriteria Exit Fase Peluncuran — Kaki Empat v2

Dokumen ini mendefinisikan ambang batas sebelum naik fase [`LaunchPhase`](../lib/core/config/mvp_scope.dart). Metrik dihitung otomatis via `admin_v2.php?action=get_launch_metrics` dan ditampilkan di tab **Peluncuran** panel admin.

## Fase saat ini: `ownerFirst`

**Tujuan:** membuktikan money engine (`owner.kakiempat.com`) stabil sebelum membuka marketplace two-sided.

### Kriteria exit ke `marketplace`

| Metrik | Ambang | Sumber data |
|--------|--------|-------------|
| Booking selesai (30 hari) | ≥ 10 | `kakiempa_v2_bookings` status `completed` |
| Pengasuh terverifikasi | ≥ 3 | `kakiempa_v2_sitter_profiles` status `approved` |
| Tingkat penyelesaian booking | ≥ 65% | completed / non-cancelled (30 hari) |
| SLA verifikasi bayar (rata-rata) | ≤ 24 jam | `kakiempa_payment_proofs` approved |
| Respons pengasuh ≤ 4 jam | ≥ 70% | request dengan offer/matched vs total request |

Konstanta Dart: [`launch_exit_criteria.dart`](../lib/core/config/launch_exit_criteria.dart)

### Cara naik fase

1. Buka admin → tab **Peluncuran** → pastikan semua checklist hijau.
2. Ubah `MvpScope.phase` di [`mvp_scope.dart`](../lib/core/config/mvp_scope.dart) menjadi `LaunchPhase.marketplace`.
3. Deploy ulang subdomain web (`deploy_web.ps1`) dan smoke-test SSO www → owner → sitter.

## Fase berikutnya (ringkas)

| Fase | Unlocks |
|------|---------|
| `marketplace` | Sitter publik, app switcher SSO, marketplace offers |
| `growth` | Wallet sitter, loyalty/referral, komunitas, rekomendasi rule-based |
| `full` | App shell terpadu, discover partner (`partner_v2.php`) |

## Monitoring

- **Pending payment proofs:** antrian admin; target backlog < 5.
- **Repeat booking 30 hari:** pantau manual dari admin tab Bookings (KPI marketplace).
