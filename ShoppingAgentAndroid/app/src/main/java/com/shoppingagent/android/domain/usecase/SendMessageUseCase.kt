package com.shoppingagent.android.domain.usecase

import com.shoppingagent.android.core.model.AppResult
import com.shoppingagent.android.core.model.ChatMessage
import com.shoppingagent.android.domain.repository.ShoppingAgentRepository

/**
 * Memvalidasi input pengguna lalu menyerahkannya ke repository agen.
 * Validasi dilakukan di domain agar UI tetap tipis dan bisa diuji tanpa Android.
 */
class SendMessageUseCase(
    private val repository: ShoppingAgentRepository
) {

    suspend operator fun invoke(text: String): AppResult<ChatMessage> {
        val trimmed = text.trim()
        return when {
            trimmed.isEmpty() -> AppResult.Failure(ERROR_EMPTY)
            trimmed.length > MAX_LENGTH -> AppResult.Failure(ERROR_TOO_LONG)
            else -> repository.sendMessage(trimmed)
        }
    }

    companion object {
        const val MAX_LENGTH = 1000
        const val ERROR_EMPTY = "Pesan tidak boleh kosong."
        const val ERROR_TOO_LONG = "Pesan terlalu panjang (maksimal $MAX_LENGTH karakter)."
    }
}
