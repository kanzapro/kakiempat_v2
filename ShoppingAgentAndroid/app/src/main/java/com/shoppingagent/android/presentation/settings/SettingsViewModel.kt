package com.shoppingagent.android.presentation.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.shoppingagent.android.core.datastore.UserPreferencesDataStore
import com.shoppingagent.android.core.model.ThemeMode
import com.shoppingagent.android.core.model.UserPreferences
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

class SettingsViewModel(
    private val preferencesDataStore: UserPreferencesDataStore
) : ViewModel() {

    private val isSaving = MutableStateFlow(false)
    private val message = MutableStateFlow<String?>(null)

    val uiState: StateFlow<SettingsUiState> = combine(
        preferencesDataStore.preferences,
        isSaving,
        message
    ) { preferences, saving, currentMessage ->
        SettingsUiState(
            preferences = preferences,
            isLoading = false,
            isSaving = saving,
            message = currentMessage
        )
    }.stateIn(
        scope = viewModelScope,
        started = SharingStarted.WhileSubscribed(STOP_TIMEOUT_MILLIS),
        initialValue = SettingsUiState()
    )

    fun save(apiKey: String, baseUrl: String, contextBudgetInput: String) {
        viewModelScope.launch {
            isSaving.value = true
            preferencesDataStore.updateApiKey(apiKey)
            preferencesDataStore.updateBaseUrl(baseUrl)
            preferencesDataStore.updateContextBudget(
                contextBudgetInput.filter { it.isDigit() }.toLongOrNull()
                    ?: UserPreferences.DEFAULT_CONTEXT_BUDGET
            )
            isSaving.value = false
            message.value = "Pengaturan tersimpan."
        }
    }

    fun onModelChange(modelName: String) {
        viewModelScope.launch { preferencesDataStore.updateModelName(modelName) }
    }

    fun onThemeModeChange(mode: ThemeMode) {
        viewModelScope.launch { preferencesDataStore.updateThemeMode(mode) }
    }

    fun onDynamicColorChange(enabled: Boolean) {
        viewModelScope.launch { preferencesDataStore.updateDynamicColor(enabled) }
    }

    fun onMessageShown() {
        message.value = null
    }

    companion object {
        private const val STOP_TIMEOUT_MILLIS = 5_000L
    }
}
