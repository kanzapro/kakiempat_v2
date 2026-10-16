package com.shoppingagent.android.domain.usecase

import com.shoppingagent.android.core.model.AppResult
import com.shoppingagent.android.core.model.Product
import com.shoppingagent.android.core.model.SearchQuery
import com.shoppingagent.android.domain.repository.ProductRepository
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.debounce
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.mapLatest

/**
 * Pencarian produk berparameter (harga/kategori) dengan debouncing.
 *
 * Pemakaian dari ViewModel:
 * ```
 * searchProductsUseCase(queryStateFlow).collect { result -> ... }
 * ```
 */
@OptIn(ExperimentalCoroutinesApi::class, FlowPreview::class)
class SearchProductsUseCase(
    private val repository: ProductRepository,
    private val debounceMillis: Long = DEFAULT_DEBOUNCE_MILLIS
) {

    operator fun invoke(queries: Flow<SearchQuery>): Flow<AppResult<List<Product>>> =
        queries
            .debounce { query -> if (query.isActive) debounceMillis else 0L }
            .distinctUntilChanged()
            .mapLatest { query -> repository.searchProducts(query) }

    /** Pencarian sekali jalan (tanpa debounce), dipakai untuk retry manual. */
    suspend fun searchOnce(query: SearchQuery): AppResult<List<Product>> =
        repository.searchProducts(query)

    companion object {
        const val DEFAULT_DEBOUNCE_MILLIS = 300L
    }
}
