package com.shoppingagent.android.domain.usecase

import com.shoppingagent.android.core.model.AppResult
import com.shoppingagent.android.domain.repository.ProductRepository

/** Menyegarkan harga seluruh produk di watchlist. */
class SyncWatchlistPricesUseCase(
    private val repository: ProductRepository
) {

    suspend operator fun invoke(): AppResult<Int> = repository.syncWatchlistPrices()
}
