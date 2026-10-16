package com.shoppingagent.android.presentation.watchlist

import com.shoppingagent.android.core.model.Product

/** State layar watchlist. */
data class WatchlistUiState(
    val items: List<Product> = emptyList(),
    val isLoading: Boolean = true,
    val isSyncing: Boolean = false,
    val message: String? = null
) {
    val isEmpty: Boolean get() = !isLoading && items.isEmpty()

    /** Total potensi penghematan dari seluruh produk yang punya harga coret. */
    val totalSavings: Long
        get() = items.sumOf { product ->
            val original = product.originalPrice ?: return@sumOf 0L
            if (original > product.price) original - product.price else 0L
        }
}
