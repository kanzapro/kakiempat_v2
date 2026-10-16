package com.shoppingagent.android.domain.repository

import com.shoppingagent.android.core.model.AppResult
import com.shoppingagent.android.core.model.ChatMessage
import kotlinx.coroutines.flow.Flow

/**
 * Kontrak pengelolaan sesi obrolan dengan agen AI.
 * Implementasi berada di lapisan data (Room + Retrofit).
 */
interface ShoppingAgentRepository {

    /** ID sesi aktif yang dikirim ke backend sebagai `session_id`. */
    val sessionId: String

    fun observeMessages(): Flow<List<ChatMessage>>

    /** Menyimpan pesan pengguna, memanggil backend, lalu menyimpan balasan agen. */
    suspend fun sendMessage(text: String): AppResult<ChatMessage>

    suspend fun clearConversation()

    /** Membuat sesi baru dan mengembalikan ID-nya. */
    fun startNewSession(): String
}
