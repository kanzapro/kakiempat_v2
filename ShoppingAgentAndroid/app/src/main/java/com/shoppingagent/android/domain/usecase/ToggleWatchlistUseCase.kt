package com.shoppingagent.android.domain.usecase

import com.shoppingagent.android.core.model.Product
import com.shoppingagent.android.domain.repository.ProductRepository

/** Menambah / menghapus produk dari watchlist (toggle satu sentuhan). */
class ToggleWatchlistUseCase(
    private val repository: ProductRepository
) {

    /** @return `true` bila produk sekarang ada di watchlist, `false` bila baru dihapus. */
    suspend operator fun invoke(product: Product): Boolean = repository.toggleWatchlist(product)
}
