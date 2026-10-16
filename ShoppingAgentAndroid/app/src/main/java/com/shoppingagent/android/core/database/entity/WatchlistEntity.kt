package com.shoppingagent.android.core.database.entity

import androidx.room.Entity
import androidx.room.PrimaryKey
import com.shoppingagent.android.core.model.Product

/** Produk yang dipantau pengguna beserta harga saat ditambahkan. */
@Entity(tableName = "watchlist")
data class WatchlistEntity(
    @PrimaryKey val productId: String,
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
    val url: String? = null,
    val addedAt: Long
)

fun WatchlistEntity.toDomain(): Product = Product(
    id = productId,
    title = title,
    price = price,
    originalPrice = originalPrice,
    currency = currency,
    rating = rating,
    reviewCount = reviewCount,
    storeName = storeName,
    imageUrl = imageUrl,
    aiSummary = aiSummary,
    category = category,
    url = url
)

fun Product.toWatchlistEntity(addedAt: Long): WatchlistEntity = WatchlistEntity(
    productId = id,
    title = title,
    price = price,
    originalPrice = originalPrice,
    currency = currency,
    rating = rating,
    reviewCount = reviewCount,
    storeName = storeName,
    imageUrl = imageUrl,
    aiSummary = aiSummary,
    category = category,
    url = url,
    addedAt = addedAt
)
