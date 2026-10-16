package com.shoppingagent.android.core.network.dto

import com.shoppingagent.android.core.model.Product
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class ProductDto(
    @SerialName("id") val id: String,
    @SerialName("title") val title: String,
    @SerialName("price") val price: Long,
    @SerialName("original_price") val originalPrice: Long? = null,
    @SerialName("currency") val currency: String = "IDR",
    @SerialName("rating") val rating: Double = 0.0,
    @SerialName("review_count") val reviewCount: Int = 0,
    @SerialName("store_name") val storeName: String = "",
    @SerialName("image_url") val imageUrl: String = "",
    @SerialName("ai_summary") val aiSummary: String? = null,
    @SerialName("category") val category: String? = null,
    @SerialName("url") val url: String? = null
) {
    fun toDomain(): Product = Product(
        id = id,
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

    companion object {
        fun fromDomain(product: Product): ProductDto = ProductDto(
            id = product.id,
            title = product.title,
            price = product.price,
            originalPrice = product.originalPrice,
            currency = product.currency,
            rating = product.rating,
            reviewCount = product.reviewCount,
            storeName = product.storeName,
            imageUrl = product.imageUrl,
            aiSummary = product.aiSummary,
            category = product.category,
            url = product.url
        )
    }
}
