package com.shoppingagent.android.core.network.dto

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class SearchRequestDto(
    @SerialName("query") val query: String,
    @SerialName("min_price") val minPrice: Long? = null,
    @SerialName("max_price") val maxPrice: Long? = null,
    @SerialName("category") val category: String? = null,
    @SerialName("limit") val limit: Int = 20
)

@Serializable
data class SearchResponseDto(
    @SerialName("products") val products: List<ProductDto> = emptyList(),
    @SerialName("total") val total: Int = products.size
)

@Serializable
data class ApiErrorDto(
    @SerialName("error") val error: String? = null,
    @SerialName("message") val message: String? = null
)
