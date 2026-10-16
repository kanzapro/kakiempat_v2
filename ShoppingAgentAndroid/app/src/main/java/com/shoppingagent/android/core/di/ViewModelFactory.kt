package com.shoppingagent.android.core.di

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import com.shoppingagent.android.presentation.chat.AgentChatViewModel
import com.shoppingagent.android.presentation.search.ProductSearchViewModel
import com.shoppingagent.android.presentation.settings.SettingsViewModel
import com.shoppingagent.android.presentation.watchlist.WatchlistViewModel

/**
 * Factory ViewModel manual yang membaca dependency dari [AppContainer].
 * Menghindari refleksi (aman untuk R8) dan tidak butuh anotasi Hilt.
 */
class ViewModelFactory(private val container: AppContainer) : ViewModelProvider.Factory {

    @Suppress("UNCHECKED_CAST")
    override fun <T : ViewModel> create(modelClass: Class<T>): T = when {
        modelClass.isAssignableFrom(AgentChatViewModel::class.java) ->
            AgentChatViewModel(
                sendMessageUseCase = container.sendMessageUseCase,
                repository = container.shoppingAgentRepository,
                getWatchlistUseCase = container.getWatchlistUseCase,
                toggleWatchlistUseCase = container.toggleWatchlistUseCase
            ) as T

        modelClass.isAssignableFrom(ProductSearchViewModel::class.java) ->
            ProductSearchViewModel(
                searchProductsUseCase = container.searchProductsUseCase,
                productRepository = container.productRepository,
                toggleWatchlistUseCase = container.toggleWatchlistUseCase
            ) as T

        modelClass.isAssignableFrom(WatchlistViewModel::class.java) ->
            WatchlistViewModel(
                getWatchlistUseCase = container.getWatchlistUseCase,
                toggleWatchlistUseCase = container.toggleWatchlistUseCase,
                syncWatchlistPricesUseCase = container.syncWatchlistPricesUseCase
            ) as T

        modelClass.isAssignableFrom(SettingsViewModel::class.java) ->
            SettingsViewModel(preferencesDataStore = container.preferencesDataStore) as T

        else -> throw IllegalArgumentException("ViewModel tidak dikenal: ${modelClass.name}")
    }
}
