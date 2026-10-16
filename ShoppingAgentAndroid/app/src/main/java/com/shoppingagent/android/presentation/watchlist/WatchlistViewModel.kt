package com.shoppingagent.android.presentation.watchlist

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.shoppingagent.android.core.model.AppResult
import com.shoppingagent.android.core.model.Product
import com.shoppingagent.android.domain.usecase.GetWatchlistUseCase
import com.shoppingagent.android.domain.usecase.SyncWatchlistPricesUseCase
import com.shoppingagent.android.domain.usecase.ToggleWatchlistUseCase
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

class WatchlistViewModel(
    getWatchlistUseCase: GetWatchlistUseCase,
    private val toggleWatchlistUseCase: ToggleWatchlistUseCase,
    private val syncWatchlistPricesUseCase: SyncWatchlistPricesUseCase
) : ViewModel() {

    private val isSyncing = MutableStateFlow(false)
    private val message = MutableStateFlow<String?>(null)

    val uiState: StateFlow<WatchlistUiState> = combine(
        getWatchlistUseCase(),
        isSyncing,
        message
    ) { items, syncing, currentMessage ->
        WatchlistUiState(
            items = items,
            isLoading = false,
            isSyncing = syncing,
            message = currentMessage
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(STOP_TIMEOUT_MILLIS),
        initialValue = WatchlistUiState()
    )

    fun onRemove(product: Product) {
        viewModelScope.launch { toggleWatchlistUseCase(product) }
    }

    fun onSyncPrices() {
        if (isSyncing.value) return
        isSyncing.value = true
        viewModelScope.launch {
            val result = runCatching { syncWatchlistPricesUseCase() }.getOrNull()
            message.value = when (result) {
                is AppResult.Success -> if (result.data > 0) {
                    "${result.data} harga produk diperbarui."
                } else {
                    "Semua harga sudah yang terbaru."
                }

                is AppResult.Failure -> result.message
                else -> "Sinkronisasi harga gagal."
            }
            isSyncing.value = false
        }
    }

    fun onMessageShown() {
        message.value = null
    }

    companion object {
        private const val STOP_TIMEOUT_MILLIS = 5_000L
    }
}
