package com.shoppingagent.android.core.network

import com.jakewharton.retrofit2.converter.kotlinx.serialization.asConverterFactory
import com.shoppingagent.android.core.AppJson
import com.shoppingagent.android.core.model.UserPreferences
import kotlinx.serialization.json.Json
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import java.util.concurrent.TimeUnit

/**
 * Pabrik Retrofit/OkHttp. API Key diambil dari preferensi pengguna dan dikirim
 * sebagai header `Authorization: Bearer <key>`.
 */
object NetworkClient {

    const val DEFAULT_BASE_URL: String = UserPreferences.DEFAULT_BASE_URL

    private const val CONNECT_TIMEOUT_SECONDS = 15L
    private const val READ_TIMEOUT_SECONDS = 30L
    private const val WRITE_TIMEOUT_SECONDS = 30L

    private val JSON_MEDIA_TYPE = "application/json".toMediaType()

    /** Konfigurasi JSON bersama seluruh aplikasi (lihat [AppJson]). */
    val json: Json get() = AppJson

    fun createOkHttpClient(apiKey: String? = null, debugLogging: Boolean = false): OkHttpClient {
        val builder = OkHttpClient.Builder()
            .connectTimeout(CONNECT_TIMEOUT_SECONDS, TimeUnit.SECONDS)
            .readTimeout(READ_TIMEOUT_SECONDS, TimeUnit.SECONDS)
            .writeTimeout(WRITE_TIMEOUT_SECONDS, TimeUnit.SECONDS)
            .retryOnConnectionFailure(true)
            .addInterceptor { chain ->
                val request = chain.request().newBuilder()
                    .header("Accept", "application/json")
                    .apply {
                        if (!apiKey.isNullOrBlank()) {
                            header("Authorization", "Bearer ${apiKey.trim()}")
                        }
                    }
                    .build()
                chain.proceed(request)
            }

        if (debugLogging) {
            val logging = HttpLoggingInterceptor().apply {
                level = HttpLoggingInterceptor.Level.BASIC
            }
            builder.addInterceptor(logging)
        }

        return builder.build()
    }

    fun createApiService(
        baseUrl: String = DEFAULT_BASE_URL,
        apiKey: String? = null,
        debugLogging: Boolean = false
    ): AgentApiService {
        val normalizedBaseUrl = when {
            baseUrl.isBlank() -> DEFAULT_BASE_URL
            baseUrl.endsWith("/") -> baseUrl
            else -> "$baseUrl/"
        }
        return Retrofit.Builder()
            .baseUrl(normalizedBaseUrl)
            .client(createOkHttpClient(apiKey = apiKey, debugLogging = debugLogging))
            .addConverterFactory(json.asConverterFactory(JSON_MEDIA_TYPE))
            .build()
            .create(AgentApiService::class.java)
    }

    fun createApiService(
        preferences: UserPreferences,
        debugLogging: Boolean = false
    ): AgentApiService = createApiService(
        baseUrl = preferences.safeBaseUrl,
        apiKey = preferences.apiKey,
        debugLogging = debugLogging
    )
}
