package com.shoppingagent.android.data.repository

import com.shoppingagent.android.core.model.Product
import com.shoppingagent.android.core.model.SearchQuery

/**
 * Katalog produk contoh yang dipakai saat backend belum aktif / perangkat offline,
 * sehingga aplikasi tetap interaktif dan tidak crash.
 */
object OfflineCatalog {

    val products: List<Product> = listOf(
        Product(
            id = "offline-tws-01",
            title = "Soundcore Life P3i TWS ANC Bluetooth 5.2",
            price = 449_000L,
            originalPrice = 699_000L,
            rating = 4.7,
            reviewCount = 1_248,
            storeName = "Soundcore Official Store",
            imageUrl = "https://picsum.photos/seed/tws01/600/600",
            aiSummary = "ANC hibrida, baterai 32 jam, ideal untuk komuter harian di bawah 500 ribu.",
            category = "Audio"
        ),
        Product(
            id = "offline-tws-02",
            title = "TWS ANC Pro Hybrid 40 Jam Baterai",
            price = 879_000L,
            originalPrice = 1_299_000L,
            rating = 4.8,
            reviewCount = 863,
            storeName = "Audio Prime Store",
            imageUrl = "https://picsum.photos/seed/tws02/600/600",
            aiSummary = "Mode transparansi + ANC 42 dB, cocok untuk kerja di ruang bising.",
            category = "Audio"
        ),
        Product(
            id = "offline-laptop-01",
            title = "ASUS TUF Gaming A15 Ryzen 7 16GB RTX 4050",
            price = 14_999_000L,
            originalPrice = 16_499_000L,
            rating = 4.8,
            reviewCount = 520,
            storeName = "ASUS Official Store",
            imageUrl = "https://picsum.photos/seed/laptop01/600/600",
            aiSummary = "GPU RTX 4050 sangat ideal untuk AutoCAD, Revit, dan Blender.",
            category = "Laptop"
        ),
        Product(
            id = "offline-laptop-02",
            title = "Lenovo LOQ 15IRX9 i7 16GB RTX 4060",
            price = 16_799_000L,
            originalPrice = 18_999_000L,
            rating = 4.6,
            reviewCount = 341,
            storeName = "Lenovo Official Store",
            imageUrl = "https://picsum.photos/seed/laptop02/600/600",
            aiSummary = "RTX 4060 untuk render 3D lebih cepat, layar 144Hz.",
            category = "Laptop"
        ),
        Product(
            id = "offline-hp-01",
            title = "Xiaomi Redmi Note 13 Pro 5G 8/256GB",
            price = 4_299_000L,
            originalPrice = 4_999_000L,
            rating = 4.7,
            reviewCount = 2_104,
            storeName = "Xiaomi Official Store",
            imageUrl = "https://picsum.photos/seed/phone01/600/600",
            aiSummary = "Kamera 200MP OIS dan layar AMOLED 120Hz, value terbaik kelas 4 jutaan.",
            category = "Smartphone"
        ),
        Product(
            id = "offline-vacuum-01",
            title = "Robot Vacuum Cleaner LDS Mapping 4000Pa",
            price = 2_899_000L,
            originalPrice = 3_599_000L,
            rating = 4.5,
            reviewCount = 412,
            storeName = "Home Smart Store",
            imageUrl = "https://picsum.photos/seed/vacuum01/600/600",
            aiSummary = "Navigasi LDS + kontrol aplikasi, cocok untuk rumah berkarpet dan hewan peliharaan.",
            category = "Smart Home"
        ),
        Product(
            id = "offline-watch-01",
            title = "Smartwatch AMOLED GPS 14 Hari Baterai",
            price = 749_000L,
            originalPrice = 999_000L,
            rating = 4.4,
            reviewCount = 655,
            storeName = "Wearable Hub",
            imageUrl = "https://picsum.photos/seed/watch01/600/600",
            aiSummary = "GPS dual-band, 100+ mode olahraga, tahan air 5ATM.",
            category = "Wearable"
        ),
        Product(
            id = "offline-chair-01",
            title = "Kursi Ergonomis Mesh dengan Lumbar Support",
            price = 1_349_000L,
            originalPrice = 1_899_000L,
            rating = 4.6,
            reviewCount = 289,
            storeName = "Office Comfort ID",
            imageUrl = "https://picsum.photos/seed/chair01/600/600",
            aiSummary = "Sandaran mesh breathable dan headrest adjustable untuk kerja 8 jam.",
            category = "Furniture"
        )
    )

    fun search(query: SearchQuery): List<Product> {
        val keywords = query.text.trim().lowercase()
            .split(' ')
            .filter { it.length >= 3 }

        return products
            .asSequence()
            .filter { product ->
                keywords.isEmpty() || keywords.any { keyword -> product.matches(keyword) }
            }
            .filter { product -> query.minPrice?.let { product.price >= it } ?: true }
            .filter { product -> query.maxPrice?.let { product.price <= it } ?: true }
            .filter { product ->
                query.category?.takeIf { it.isNotBlank() }?.let { category ->
                    product.category.equals(category, ignoreCase = true)
                } ?: true
            }
            .sortedByDescending { it.rating }
            .take(query.limit)
            .toList()
    }

    /** Mencari produk yang paling relevan dengan pesan pengguna (untuk balasan agen offline). */
    fun topMatches(message: String, limit: Int = 3): List<Product> {
        val keywords = message.lowercase().split(' ').filter { it.length >= 3 }
        return products
            .map { product -> product to keywords.count { product.matches(it) } }
            .filter { (_, score) -> score > 0 }
            .sortedByDescending { (_, score) -> score }
            .map { (product, _) -> product }
            .ifEmpty { products.sortedByDescending { it.rating } }
            .take(limit)
    }
}
