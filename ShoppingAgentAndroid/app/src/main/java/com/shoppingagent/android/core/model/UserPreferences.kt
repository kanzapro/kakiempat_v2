package com.shoppingagent.android.core.model

enum class ThemeMode {
    SYSTEM,
    LIGHT,
    DARK;

    companion object {
        fun fromRaw(raw: String): ThemeMode =
            entries.firstOrNull { it.name.equals(raw, ignoreCase = true) } ?: SYSTEM
    }
}

/**
 * Preferensi pengguna yang dipersist di DataStore (API key, model AI, tema, budget konteks).
 */
data class UserPreferences(
    val apiKey: String = "",
    val modelName: String = DEFAULT_MODEL,
    val baseUrl: String = DEFAULT_BASE_URL,
    val preferredStores: Set<String> = emptySet(),
    val contextBudget: Long = DEFAULT_CONTEXT_BUDGET,
    val themeMode: ThemeMode = ThemeMode.SYSTEM,
    val dynamicColor: Boolean = true
) {
    val hasApiKey: Boolean get() = apiKey.isNotBlank()

    /** Retrofit mensyaratkan base URL berakhir dengan "/". */
    val safeBaseUrl: String
        get() = when {
            baseUrl.isBlank() -> DEFAULT_BASE_URL
            baseUrl.endsWith("/") -> baseUrl
            else -> "$baseUrl/"
        }

    val safeContextBudget: Long
        get() = contextBudget.coerceIn(MIN_CONTEXT_BUDGET, MAX_CONTEXT_BUDGET)

    companion object {
        const val DEFAULT_MODEL = "gpt-4o-mini"
        const val DEFAULT_BASE_URL = "https://api.yourdomain.com/"
        const val DEFAULT_CONTEXT_BUDGET = 15_000_000L
        const val MIN_CONTEXT_BUDGET = 0L
        const val MAX_CONTEXT_BUDGET = 500_000_000L

        val AVAILABLE_MODELS = listOf(
            "gpt-4o-mini",
            "gpt-4o",
            "gemini-1.5-pro",
            "gemini-1.5-flash"
        )
    }
}
