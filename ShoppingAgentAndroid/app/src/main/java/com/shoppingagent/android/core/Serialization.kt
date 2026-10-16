package com.shoppingagent.android.core

import kotlinx.serialization.json.Json

/**
 * Konfigurasi JSON tunggal untuk seluruh aplikasi (dipakai Retrofit converter dan Room TypeConverter).
 */
val AppJson: Json = Json {
    ignoreUnknownKeys = true
    isLenient = true
    explicitNulls = false
    encodeDefaults = true
    coerceInputValues = true
}
