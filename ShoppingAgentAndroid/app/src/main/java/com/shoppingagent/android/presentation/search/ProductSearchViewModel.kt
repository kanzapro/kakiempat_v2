package com.shoppingagent.android.presentation.search

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.shoppingagent.android.core.model.AppResult
import com.shoppingagent.android.core.model.Product
import com.shoppingagent.android.core.model.SearchQuery
import com.shoppingagent.android.core.ui.format.digitsOnly
import com.shoppingagent.android.domain.repository.ProductRepository
import com.shoppingagent.android.domain.usecase.SearchProductsUseCase
import com.shoppingagent.android.domain.usecase.ToggleWatchlistUseCase
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

class ProductSearchViewModel(
    private val searchProductsUseCase: SearchProductsUseCase,
    private val productRepository: ProductRepository,
    private val toggleWatchlistUseCase: ToggleWatchlistUseCase
) : ViewModel() {

    private val queryState = MutableStateFlow(SearchQuery())

    private val _uiState = MutableStateFlow(ProductSearchUiState())
    val uiState: StateFlow<ProductSearchUiState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch {
            searchProductsUseCase(queryState).collect { result ->
                _uiState.update { state ->
                    when (result) {
                        is AppResult.Success -> state.copy(
                            products = result.data,
                            isLoading = false,
                            errorMessage = null
                        )

                        is AppResult.Failure -> state.copy(
                            isLoading = false,
                            errorMessage = result.message
                        )

                        AppResult.Loading -> state.copy(isLoading = true)
                    }
                }
            }
        }

        viewModelScope.launch {
            productRepository.isOffline.collect { offline ->
                _uiState.update { it.copy(isOffline = offline) }
            }
        }

        viewModelScope.launch {
            productRepository.observeWatchlist().collect { items ->
                _uiState.update { it.copy(watchlistIds = items.map(Product::id).toSet()) }
            }
        }
    }

    fun onQueryChange(value: String) {
        _uiState.update { it.copy(query = value, isLoading = true) }
        queryState.update { it.copy(text = value) }
    }

    fun onMinPriceChange(value: String) {
        val digits = value.digitsOnly()
        _uiState.update { it.copy(minPriceInput = digits, isLoading = true) }
        queryState.update { it.copy(minPrice = digits.toLongOrNull()) }
    }

    fun onMaxPriceChange(value: String) {
        val digits = value.digitsOnly()
        _uiState.update { it.copy(maxPriceInput = digits, isLoading = true) }
        queryState.update { it.copy(maxPrice = digits.toLongOrNull()) }
    }

    fun onCategorySelected(category: String?) {
        val next = if (category == _uiState.value.selectedCategory) null else category
        _uiState.update { it.copy(selectedCategory = next, isLoading = true) }
        queryState.update { it.copy(category = next) }
    }

    fun onClearFilters() {
        _uiState.update {
            it.copy(
                minPriceInput = "",
                maxPriceInput = "",
                selectedCategory = null,
                isLoading = true
            )
        }
        queryState.update { it.copy(minPrice = null, maxPrice = null, category = null) }
    }

    fun onRetry() {
        viewModelScope.launch {
            _uiState.update { it.copy(isLoading = true) }
            val result = runCatching { searchProductsUseCase.searchOnce(queryState.value) }
                .getOrElse { error -> AppResult.Failure(error.message ?: "Pencarian gagal.") }

            _uiState.update { state ->
                when (result) {
                    is AppResult.Success -> state.copy(
                        products = result.data,
                        isLoading = false,
                        errorMessage = null
                    )

                    is AppResult.Failure -> state.copy(
                        isLoading = false,
                        errorMessage = result.message
                    )

                    AppResult.Loading -> state.copy(isLoading = true)
                }
            }
        }
    }

    fun onWatchlistToggle(product: Product) {
        viewModelScope.launch { toggleWatchlistUseCase(product) }
    }

    fun dismissError() {
        _uiState.update { it.copy(errorMessage = null) }
    }
}
