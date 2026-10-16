package com.shoppingagent.android.core.model

import kotlinx.serialization.Serializable

enum class ChatRole {
    USER,
    AGENT;

    companion object {
        fun fromRaw(raw: String): ChatRole =
            entries.firstOrNull { it.name.equals(raw, ignoreCase = true) } ?: AGENT
    }
}

/**
 * Satu gelembung percakapan. [recommendedProducts] & [suggestions] hanya terisi pada pesan agen.
 */
@Serializable
data class ChatMessage(
    val id: String,
    val sessionId: String,
    val content: String,
    val role: ChatRole,
    val timestamp: Long,
    val recommendedProducts: List<Product> = emptyList(),
    val suggestions: List<String> = emptyList(),
    val isError: Boolean = false
) {
    val isFromUser: Boolean get() = role == ChatRole.USER
}
