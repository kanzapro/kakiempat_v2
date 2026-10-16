package com.shoppingagent.android.domain.repository

import com.shoppingagent.android.core.model.AppResult
import com.shoppingagent.android.core.model.Product
import com.shoppingagent.android.core.model.SearchQuery
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.StateFlow

/**
 * Kontrak katalog produk: pencarian, watchlist, dan sinkronisasi harga.
 * Implementasi menyediakan fallback katalog offline bila backend belum tersedia.
 */
interface ProductRepository {

    /** `true` bila data terakhir berasal dari katalog offline (backend tidak tersedia). */
    val isOffline: StateFlow<Boolean>

    suspend fun searchProducts(query: SearchQuery): AppResult<List<Product>>

    fun observeWatchlist(): Flow<List<Product>>

    /** @return `true` bila produk sekarang tersimpan di watchlist. */
    suspend fun toggleWatchlist(product: Product): Boolean

    suspend fun isInWatchlist(productId: String): Boolean

    /** @return jumlah produk watchlist yang harganya berhasil diperbarui. */
    suspend fun syncWatchlistPrices(): AppResult<Int>
}
