package com.shoppingagent.android.presentation.search

import com.shoppingagent.android.core.model.Product

/** State layar pencarian produk. */
data class ProductSearchUiState(
    val query: String = "",
    val minPriceInput: String = "",
    val maxPriceInput: String = "",
    val selectedCategory: String? = null,
    val products: List<Product> = emptyList(),
    val watchlistIds: Set<String> = emptySet(),
    val isLoading: Boolean = true,
    val isOffline: Boolean = false,
    val errorMessage: String? = null
) {
    val isEmptyResult: Boolean get() = !isLoading && products.isEmpty()

    val hasActiveFilter: Boolean
        get() = minPriceInput.isNotBlank() || maxPriceInput.isNotBlank() || selectedCategory != null

    companion object {
        val CATEGORY_OPTIONS = listOf(
            "Audio",
            "Laptop",
            "Smartphone",
            "Wearable",
            "Smart Home",
            "Furniture"
        )
    }
}
