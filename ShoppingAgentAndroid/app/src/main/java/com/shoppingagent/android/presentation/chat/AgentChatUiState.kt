package com.shoppingagent.android.presentation.chat

import com.shoppingagent.android.core.model.ChatMessage

/** State layar obrolan agen (immutable, diperbarui via StateFlow). */
data class AgentChatUiState(
    val messages: List<ChatMessage> = emptyList(),
    val inputText: String = "",
    val isAgentThinking: Boolean = false,
    val suggestions: List<String> = emptyList(),
    val watchlistIds: Set<String> = emptySet(),
    val errorMessage: String? = null
) {
    val isEmpty: Boolean get() = messages.isEmpty()

    val canSend: Boolean get() = inputText.isNotBlank() && !isAgentThinking
}
