package com.shoppingagent.android.core.network.dto

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Payload request obrolan ke backend agen.
 *
 * ```json
 * {
 *   "message": "Cari laptop untuk mahasiswa arsitektur",
 *   "session_id": "8f3b2e5a-...",
 *   "context_budget": 15000000,
 *   "preferred_stores": ["Official Store"],
 *   "model": "gpt-4o-mini"
 * }
 * ```
 */
@Serializable
data class ChatRequestDto(
    @SerialName("message") val message: String,
    @SerialName("session_id") val sessionId: String,
    @SerialName("context_budget") val contextBudget: Long? = null,
    @SerialName("preferred_stores") val preferredStores: List<String> = emptyList(),
    @SerialName("model") val model: String? = null
)

@Serializable
data class ChatResponseDto(
    @SerialName("reply") val reply: String,
    @SerialName("recommended_products") val recommendedProducts: List<ProductDto> = emptyList(),
    @SerialName("suggestions") val suggestions: List<String> = emptyList(),
    @SerialName("session_id") val sessionId: String? = null
)
