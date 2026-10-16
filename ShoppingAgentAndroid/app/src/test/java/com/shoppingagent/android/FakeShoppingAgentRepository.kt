package com.shoppingagent.android

import com.shoppingagent.android.core.model.AppResult
import com.shoppingagent.android.core.model.ChatMessage
import com.shoppingagent.android.core.model.ChatRole
import com.shoppingagent.android.domain.repository.ShoppingAgentRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow

/** Fake repository in-memory agar use case bisa diuji tanpa Android/Room. */
class FakeShoppingAgentRepository : ShoppingAgentRepository {

    private val messages = MutableStateFlow<List<ChatMessage>>(emptyList())

    val sentTexts = mutableListOf<String>()

    var failure: Throwable? = null

    override var sessionId: String = "test-session"

    override fun observeMessages(): Flow<List<ChatMessage>> = messages

    override suspend fun sendMessage(text: String): AppResult<ChatMessage> {
        sentTexts += text
        failure?.let { error ->
            return AppResult.Failure(error.message ?: "error", error)
        }
        val message = ChatMessage(
            id = "message-${sentTexts.size}",
            sessionId = sessionId,
            content = "echo: $text",
            role = ChatRole.AGENT,
            timestamp = sentTexts.size.toLong()
        )
        messages.value = messages.value + message
        return AppResult.Success(message)
    }

    override suspend fun clearConversation() {
        messages.value = emptyList()
    }

    override fun startNewSession(): String {
        sessionId = "test-session-new"
        return sessionId
    }
}
