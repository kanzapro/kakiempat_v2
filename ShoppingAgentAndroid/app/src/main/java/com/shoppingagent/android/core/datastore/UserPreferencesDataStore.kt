package com.shoppingagent.android.core.datastore

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.MutablePreferences
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.emptyPreferences
import androidx.datastore.preferences.core.longPreferencesKey
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.core.stringSetPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import com.shoppingagent.android.core.model.ThemeMode
import com.shoppingagent.android.core.model.UserPreferences
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.map
import java.io.IOException

private val Context.userPreferencesStore: DataStore<Preferences> by preferencesDataStore(
    name = UserPreferencesDataStore.STORE_NAME
)

/**
 * Penyimpanan preferensi pengguna (API key, model AI, base URL, tema, budget konteks).
 * Nilai sensitif dikecualikan dari backup cloud lewat `backup_rules.xml`.
 */
class UserPreferencesDataStore(private val context: Context) {

    val preferences: Flow<UserPreferences> = context.userPreferencesStore.data
        .catch { error ->
            if (error is IOException) emit(emptyPreferences()) else throw error
        }
        .map { prefs -> prefs.toUserPreferences() }

    suspend fun updateApiKey(value: String) = edit { it[Keys.API_KEY] = value.trim() }

    suspend fun updateModelName(value: String) = edit { it[Keys.MODEL_NAME] = value.trim() }

    suspend fun updateBaseUrl(value: String) = edit { it[Keys.BASE_URL] = value.trim() }

    suspend fun updatePreferredStores(stores: Set<String>) =
        edit { it[Keys.PREFERRED_STORES] = stores }

    suspend fun updateContextBudget(value: Long) =
        edit { it[Keys.CONTEXT_BUDGET] = value.coerceIn(0L, UserPreferences.MAX_CONTEXT_BUDGET) }

    suspend fun updateThemeMode(mode: ThemeMode) = edit { it[Keys.THEME_MODE] = mode.name }

    suspend fun updateDynamicColor(enabled: Boolean) = edit { it[Keys.DYNAMIC_COLOR] = enabled }

    suspend fun reset() {
        context.userPreferencesStore.edit { it.clear() }
    }

    private suspend fun edit(block: suspend (MutablePreferences) -> Unit) {
        context.userPreferencesStore.edit(block)
    }

    private fun Preferences.toUserPreferences(): UserPreferences = UserPreferences(
        apiKey = this[Keys.API_KEY] ?: "",
        modelName = this[Keys.MODEL_NAME] ?: UserPreferences.DEFAULT_MODEL,
        baseUrl = this[Keys.BASE_URL] ?: UserPreferences.DEFAULT_BASE_URL,
        preferredStores = this[Keys.PREFERRED_STORES] ?: emptySet(),
        contextBudget = this[Keys.CONTEXT_BUDGET] ?: UserPreferences.DEFAULT_CONTEXT_BUDGET,
        themeMode = ThemeMode.fromRaw(this[Keys.THEME_MODE] ?: ThemeMode.SYSTEM.name),
        dynamicColor = this[Keys.DYNAMIC_COLOR] ?: true
    )

    private object Keys {
        val API_KEY = stringPreferencesKey("api_key")
        val MODEL_NAME = stringPreferencesKey("model_name")
        val BASE_URL = stringPreferencesKey("base_url")
        val PREFERRED_STORES = stringSetPreferencesKey("preferred_stores")
        val CONTEXT_BUDGET = longPreferencesKey("context_budget")
        val THEME_MODE = stringPreferencesKey("theme_mode")
        val DYNAMIC_COLOR = booleanPreferencesKey("dynamic_color")
    }

    companion object {
        const val STORE_NAME = "user_preferences"
    }
}
