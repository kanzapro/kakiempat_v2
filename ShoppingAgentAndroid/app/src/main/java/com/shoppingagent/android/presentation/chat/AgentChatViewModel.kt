package com.shoppingagent.android.presentation.chat

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.shoppingagent.android.core.model.AppResult
import com.shoppingagent.android.core.model.ChatRole
import com.shoppingagent.android.core.model.Product
import com.shoppingagent.android.domain.repository.ShoppingAgentRepository
import com.shoppingagent.android.domain.usecase.GetWatchlistUseCase
import com.shoppingagent.android.domain.usecase.SendMessageUseCase
import com.shoppingagent.android.domain.usecase.ToggleWatchlistUseCase
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

class AgentChatViewModel(
    private val sendMessageUseCase: SendMessageUseCase,
    private val repository: ShoppingAgentRepository,
    getWatchlistUseCase: GetWatchlistUseCase,
    private val toggleWatchlistUseCase: ToggleWatchlistUseCase
) : ViewModel() {

    private val _uiState = MutableStateFlow(AgentChatUiState())
    val uiState: StateFlow<AgentChatUiState> = _uiState.asStateFlow()

    init {
        viewModelScope.launch {
            repository.observeMessages().collect { messages ->
                _uiState.update { state ->
                    state.copy(
                        messages = messages,
                        suggestions = messages
                            .lastOrNull { it.role == ChatRole.AGENT }
                            ?.suggestions
                            .orEmpty()
                    )
                }
            }
        }

        viewModelScope.launch {
            getWatchlistUseCase().collect { products ->
                _uiState.update { it.copy(watchlistIds = products.map(Product::id).toSet()) }
            }
        }
    }

    fun onInputChange(value: String) {
        _uiState.update { it.copy(inputText = value) }
    }

    fun onSend() {
        val text = _uiState.value.inputText
        if (text.isBlank() || _uiState.value.isAgentThinking) return

        _uiState.update { it.copy(inputText = "", isAgentThinking = true, errorMessage = null) }

        viewModelScope.launch {
            val result = runCatching { sendMessageUseCase(text) }
                .getOrElse { error ->
                    AppResult.Failure(error.message ?: "Gagal mengirim pesan.", error)
                }

            _uiState.update { state ->
                state.copy(
                    isAgentThinking = false,
                    errorMessage = (result as? AppResult.Failure)?.message
                )
            }
        }
    }

    fun onSuggestionClick(suggestion: String) {
        _uiState.update { it.copy(inputText = suggestion) }
        onSend()
    }

    fun onWatchlistToggle(product: Product) {
        viewModelScope.launch { toggleWatchlistUseCase(product) }
    }

    fun onNewSession() {
        repository.startNewSession()
        _uiState.update {
            it.copy(
                messages = emptyList(),
                suggestions = emptyList(),
                inputText = "",
                errorMessage = null
            )
        }
    }

    fun onClearConversation() {
        viewModelScope.launch { repository.clearConversation() }
    }

    fun dismissError() {
        _uiState.update { it.copy(errorMessage = null) }
    }
}
