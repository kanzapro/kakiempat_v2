package com.shoppingagent.android.core.model

/** Parameter pencarian produk yang dipakai oleh SearchProductsUseCase. */
data class SearchQuery(
    val text: String = "",
    val minPrice: Long? = null,
    val maxPrice: Long? = null,
    val category: String? = null,
    val limit: Int = DEFAULT_LIMIT
) {
    val isFiltered: Boolean
        get() = minPrice != null || maxPrice != null || !category.isNullOrBlank()

    val isActive: Boolean get() = text.isNotBlank() || isFiltered

    companion object {
        const val DEFAULT_LIMIT = 20
    }
}
