package com.shoppingagent.android.core.di

import android.content.Context
import com.shoppingagent.android.BuildConfig
import com.shoppingagent.android.core.database.AppDatabase
import com.shoppingagent.android.core.datastore.UserPreferencesDataStore
import com.shoppingagent.android.core.model.UserPreferences
import com.shoppingagent.android.core.network.AgentApiService
import com.shoppingagent.android.core.network.NetworkClient
import com.shoppingagent.android.data.repository.ProductRepositoryImpl
import com.shoppingagent.android.data.repository.ShoppingAgentRepositoryImpl
import com.shoppingagent.android.domain.repository.ProductRepository
import com.shoppingagent.android.domain.repository.ShoppingAgentRepository
import com.shoppingagent.android.domain.usecase.GetWatchlistUseCase
import com.shoppingagent.android.domain.usecase.SearchProductsUseCase
import com.shoppingagent.android.domain.usecase.SendMessageUseCase
import com.shoppingagent.android.domain.usecase.SyncWatchlistPricesUseCase
import com.shoppingagent.android.domain.usecase.ToggleWatchlistUseCase
import kotlinx.coroutines.flow.first

/**
 * Service locator sederhana (pure DI). Semua dependency dibuat lazy dan singleton
 * per proses aplikasi; siap dimigrasikan ke Hilt/Koin tanpa mengubah lapisan domain.
 */
class AppContainer(context: Context) {

    private val appContext: Context = context.applicationContext

    private val database: AppDatabase by lazy { AppDatabase.getInstance(appContext) }

    val preferencesDataStore: UserPreferencesDataStore by lazy {
        UserPreferencesDataStore(appContext)
    }

    private val preferencesProvider: suspend () -> UserPreferences = {
        preferencesDataStore.preferences.first()
    }

    private data class ApiCacheKey(val baseUrl: String, val apiKey: String)

    private var apiCache: Pair<ApiCacheKey, AgentApiService>? = null

    /** Retrofit client dibuat ulang hanya bila Base URL / API Key berubah. */
    private val apiProvider: suspend () -> AgentApiService = {
        val preferences = preferencesProvider()
        val cacheKey = ApiCacheKey(preferences.safeBaseUrl, preferences.apiKey)
        apiCache?.takeIf { it.first == cacheKey }?.second
            ?: NetworkClient.createApiService(preferences, debugLogging = BuildConfig.DEBUG)
                .also { apiCache = cacheKey to it }
    }

    val shoppingAgentRepository: ShoppingAgentRepository by lazy {
        ShoppingAgentRepositoryImpl(
            chatMessageDao = database.chatMessageDao(),
            apiProvider = apiProvider,
            preferencesProvider = preferencesProvider
        )
    }

    val productRepository: ProductRepository by lazy {
        ProductRepositoryImpl(
            watchlistDao = database.watchlistDao(),
            apiProvider = apiProvider
        )
    }

    val sendMessageUseCase by lazy { SendMessageUseCase(shoppingAgentRepository) }

    val searchProductsUseCase by lazy { SearchProductsUseCase(productRepository) }

    val getWatchlistUseCase by lazy { GetWatchlistUseCase(productRepository) }

    val toggleWatchlistUseCase by lazy { ToggleWatchlistUseCase(productRepository) }

    val syncWatchlistPricesUseCase by lazy { SyncWatchlistPricesUseCase(productRepository) }
}
