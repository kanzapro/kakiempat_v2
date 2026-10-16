package com.shoppingagent.android.data.repository

import com.shoppingagent.android.core.database.dao.WatchlistDao
import com.shoppingagent.android.core.database.entity.toDomain
import com.shoppingagent.android.core.database.entity.toWatchlistEntity
import com.shoppingagent.android.core.model.AppResult
import com.shoppingagent.android.core.model.Product
import com.shoppingagent.android.core.model.SearchQuery
import com.shoppingagent.android.core.network.AgentApiService
import com.shoppingagent.android.core.network.NetworkError
import com.shoppingagent.android.core.network.dto.SearchRequestDto
import com.shoppingagent.android.domain.repository.ProductRepository
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext

/**
 * Katalog produk dari backend dengan fallback [OfflineCatalog] saat server belum aktif.
 * Saat fallback dipakai, [isOffline] menjadi `true` supaya UI bisa menampilkan banner.
 */
class ProductRepositoryImpl(
    private val watchlistDao: WatchlistDao,
    private val apiProvider: suspend () -> AgentApiService,
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO
) : ProductRepository {

    private val offlineState = MutableStateFlow(false)

    override val isOffline: StateFlow<Boolean> = offlineState.asStateFlow()

    override suspend fun searchProducts(query: SearchQuery): AppResult<List<Product>> =
        withContext(ioDispatcher) {
            runCatching {
                apiProvider().searchProducts(
                    SearchRequestDto(
                        query = query.text,
                        minPrice = query.minPrice,
                        maxPrice = query.maxPrice,
                        category = query.category,
                        limit = query.limit
                    )
                ).products.map { it.toDomain() }
            }.fold(
                onSuccess = { products ->
                    offlineState.value = false
                    AppResult.Success(products)
                },
                onFailure = {
                    offlineState.value = true
                    AppResult.Success(OfflineCatalog.search(query))
                }
            )
        }

    override fun observeWatchlist(): Flow<List<Product>> =
        watchlistDao.observeWatchlist()
            .map { entities -> entities.map { it.toDomain() } }
            .flowOn(ioDispatcher)

    override suspend fun toggleWatchlist(product: Product): Boolean = withContext(ioDispatcher) {
        if (watchlistDao.exists(product.id)) {
            watchlistDao.delete(product.id)
            false
        } else {
            watchlistDao.upsert(product.toWatchlistEntity(System.currentTimeMillis()))
            true
        }
    }

    override suspend fun isInWatchlist(productId: String): Boolean =
        withContext(ioDispatcher) { watchlistDao.exists(productId) }

    override suspend fun syncWatchlistPrices(): AppResult<Int> = withContext(ioDispatcher) {
        val items = watchlistDao.observeWatchlist().first()
        if (items.isEmpty()) return@withContext AppResult.Success(0)

        var updated = 0
        var lastError: Throwable? = null

        items.forEach { item ->
            runCatching {
                val match = apiProvider()
                    .searchProducts(SearchRequestDto(query = item.title, limit = 1))
                    .products
                    .firstOrNull()
                if (match != null &&
                    (match.price != item.price || match.originalPrice != item.originalPrice)
                ) {
                    watchlistDao.updatePrice(item.productId, match.price, match.originalPrice)
                    updated++
                }
            }.onFailure { lastError = it }
        }

        when {
            updated > 0 -> AppResult.Success(updated)
            lastError != null -> AppResult.Failure(NetworkError.messageFor(lastError!!))
            else -> AppResult.Success(0)
        }
    }
}
