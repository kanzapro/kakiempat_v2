# ShoppingAgentAndroid

Aplikasi Android **AI Shopping Assistant** — Kotlin + Jetpack Compose (Material 3) dengan
**Clean Architecture** (domain – data – presentation) dan MVVM/MVI-ready.

## Stack

| Dimensi | Spesifikasi |
|---|---|
| Bahasa | Kotlin 2.0.20 |
| UI | Jetpack Compose + Material 3 (dynamic color / Material You) |
| State | `StateFlow` + Coroutines, `collectAsStateWithLifecycle()` |
| DI | `AppContainer` (pure DI / service locator), siap migrasi ke Hilt |
| Lokal | Room 2.6.1 (SQLite) + DataStore Preferences |
| Jaringan | Retrofit 2 + OkHttp 4 + Kotlinx Serialization |
| Build | Gradle Version Catalog (`gradle/libs.versions.toml`) + Kotlin DSL |
| SDK | minSdk 26, target/compileSdk 34, JDK 17 |

## Struktur

```
app/src/main/java/com/shoppingagent/android/
├── ShoppingAgentApplication.kt      # inisialisasi AppContainer
├── MainActivity.kt                  # entrypoint Compose
├── core/
│   ├── model/                       # Product, ChatMessage, SearchQuery, AppResult, UserPreferences
│   ├── network/                     # AgentApiService, NetworkClient, dto/
│   ├── database/                    # AppDatabase, dao/, entity/, Converters
│   ├── datastore/                   # UserPreferencesDataStore
│   ├── di/                          # AppContainer, ViewModelFactory
│   └── ui/theme/                    # Color, Type, Theme
├── domain/
│   ├── repository/                  # kontrak ShoppingAgentRepository, ProductRepository
│   └── usecase/                     # SendMessage, SearchProducts, GetWatchlist, ToggleWatchlist
├── data/repository/                 # implementasi + OfflineCatalog (fallback)
└── presentation/
    ├── navigation/                  # Screen + NavGraph + bottom bar
    ├── components/                  # ProductCard, ChatMessageBubble, ThinkingIndicator
    ├── chat/ search/ watchlist/ settings/
```

## Menjalankan

1. Buka folder ini di Android Studio (Hedgehog ke atas) → **Open**.
2. Pastikan **Gradle JDK = 17** (Settings → Build, Execution, Deployment → Build Tools → Gradle).
3. Sync Gradle, lalu **Run 'app'** ke emulator/perangkat API 26+.
4. Unit test: `./gradlew test` (atau `:app:testDebugUnitTest`).

## Kontrak Backend

`NetworkClient.BASE_URL` default `https://api.yourdomain.com/` dan bisa diubah dari layar Pengaturan.

- `POST /api/v1/agent/chat`
  ```json
  {
    "message": "Cari laptop untuk mahasiswa arsitektur",
    "session_id": "8f3b2e5a-...",
    "context_budget": 15000000,
    "preferred_stores": ["Official Store"],
    "model": "gpt-4o-mini"
  }
  ```
  Respons: `{ "reply": "...", "recommended_products": [ ... ], "suggestions": [ "..." ] }`
- `POST /api/v1/products/search` → `{ "products": [ ... ], "total": 12 }`

Authorization dikirim sebagai `Bearer <API Key>` bila API Key diisi di Pengaturan.

## Fallback offline

Bila backend belum aktif / jaringan mati:
- `ProductRepositoryImpl` otomatis memakai `OfflineCatalog` (katalog contoh) dan menandai
  `isOffline = true` sehingga UI menampilkan banner "Mode offline".
- `ShoppingAgentRepositoryImpl` menyimpan pesan agen fallback yang berisi rekomendasi katalog lokal,
  jadi chat tidak pernah crash dan tetap interaktif.
