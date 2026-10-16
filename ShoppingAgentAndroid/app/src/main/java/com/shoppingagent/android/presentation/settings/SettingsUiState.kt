package com.shoppingagent.android.presentation.settings

import com.shoppingagent.android.core.model.UserPreferences

/** State layar pengaturan (API key, model AI, base URL, tema). */
data class SettingsUiState(
    val preferences: UserPreferences = UserPreferences(),
    val isLoading: Boolean = true,
    val isSaving: Boolean = false,
    val message: String? = null
) {
    val availableModels: List<String> get() = UserPreferences.AVAILABLE_MODELS
}
