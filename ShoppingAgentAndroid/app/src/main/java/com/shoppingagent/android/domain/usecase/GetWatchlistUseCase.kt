package com.shoppingagent.android.domain.usecase

import com.shoppingagent.android.core.model.Product
import com.shoppingagent.android.domain.repository.ProductRepository
import kotlinx.coroutines.flow.Flow

/** Mengamati daftar produk yang dipantau pengguna secara reaktif. */
class GetWatchlistUseCase(
    private val repository: ProductRepository
) {

    operator fun invoke(): Flow<List<Product>> = repository.observeWatchlist()
}
