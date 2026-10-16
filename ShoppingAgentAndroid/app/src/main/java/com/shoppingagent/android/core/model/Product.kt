package com.shoppingagent.android.core.model

import kotlinx.serialization.Serializable

/**
 * Model domain produk hasil rekomendasi agen maupun pencarian katalog.
 * Serializable agar bisa dipersist ke Room (JSON) maupun di-cache.
 */
@Serializable
data class Product(
    val id: String,
    val title: String,
    val price: Long,
    val originalPrice: Long? = null,
    val currency: String = "IDR",
    val rating: Double = 0.0,
    val reviewCount: Int = 0,
    val storeName: String = "",
    val imageUrl: String = "",
    val aiSummary: String? = null,
    val category: String? = null,
    val url: String? = null
) {
    /** Persentase diskon (0 bila tidak ada harga awal yang lebih tinggi). */
    val discountPercent: Int
        get() {
            val original = originalPrice ?: return 0
            if (original <= price || original <= 0L) return 0
            return (((original - price) * 100.0) / original).toInt()
        }

    val hasDiscount: Boolean get() = discountPercent > 0

    /** Rating dibulatkan ke rentang 0..5 agar aman dipakai komponen bintang. */
    val safeRating: Double get() = rating.coerceIn(0.0, 5.0)

    fun matches(query: String): Boolean {
        if (query.isBlank()) return true
        val needle = query.trim().lowercase()
        return title.lowercase().contains(needle) ||
            storeName.lowercase().contains(needle) ||
            category?.lowercase()?.contains(needle) == true ||
            aiSummary?.lowercase()?.contains(needle) == true
    }
}
