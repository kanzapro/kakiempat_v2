package com.shoppingagent.android.data.repository

import com.shoppingagent.android.core.database.dao.ChatMessageDao
import com.shoppingagent.android.core.database.entity.ChatMessageEntity
import com.shoppingagent.android.core.database.entity.toDomain
import com.shoppingagent.android.core.model.AppResult
import com.shoppingagent.android.core.model.ChatMessage
import com.shoppingagent.android.core.model.ChatRole
import com.shoppingagent.android.core.model.UserPreferences
import com.shoppingagent.android.core.network.AgentApiService
import com.shoppingagent.android.core.network.NetworkError
import com.shoppingagent.android.core.network.dto.ChatRequestDto
import com.shoppingagent.android.domain.repository.ShoppingAgentRepository
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.withContext
import java.util.UUID

/**
 * Alur pengiriman pesan:
 * 1. simpan pesan pengguna ke Room, 2. panggil backend agen, 3. simpan balasan agen ke Room.
 * Bila backend tidak terjangkau, balasan agen dibuat dari [OfflineCatalog] agar chat tetap jalan.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class ShoppingAgentRepositoryImpl(
    private val chatMessageDao: ChatMessageDao,
    private val apiProvider: suspend () -> AgentApiService,
    private val preferencesProvider: suspend () -> UserPreferences,
    private val ioDispatcher: CoroutineDispatcher = Dispatchers.IO
) : ShoppingAgentRepository {

    private val sessionState = MutableStateFlow(UUID.randomUUID().toString())

    override val sessionId: String get() = sessionState.value

    override fun observeMessages(): Flow<List<ChatMessage>> =
        sessionState
            .flatMapLatest { session -> chatMessageDao.observeMessages(session) }
            .map { entities -> entities.map(ChatMessageEntity::toDomain) }
            .flowOn(ioDispatcher)

    override suspend fun sendMessage(text: String): AppResult<ChatMessage> =
        withContext(ioDispatcher) {
            val trimmed = text.trim()
            if (trimmed.isEmpty()) {
                return@withContext AppResult.Failure("Pesan tidak boleh kosong.")
            }

            val session = sessionId
            chatMessageDao.upsert(
                ChatMessageEntity(
                    id = UUID.randomUUID().toString(),
                    sessionId = session,
                    content = trimmed,
                    role = ChatRole.USER.name,
                    timestamp = System.currentTimeMillis()
                )
            )

            runCatching {
                val preferences = preferencesProvider()
                apiProvider().sendMessage(
                    ChatRequestDto(
                        message = trimmed,
                        sessionId = session,
                        contextBudget = preferences.safeContextBudget,
                        preferredStores = preferences.preferredStores.toList(),
                        model = preferences.modelName
                    )
                )
            }.fold(
                onSuccess = { response ->
                    val entity = ChatMessageEntity(
                        id = UUID.randomUUID().toString(),
                        sessionId = session,
                        content = response.reply,
                        role = ChatRole.AGENT.name,
                        timestamp = System.currentTimeMillis(),
                        recommendedProducts = response.recommendedProducts.map { it.toDomain() },
                        suggestions = response.suggestions
                    )
                    chatMessageDao.upsert(entity)
                    AppResult.Success(entity.toDomain())
                },
                onFailure = { error -> saveOfflineReply(session, trimmed, error) }
            )
        }

    private suspend fun saveOfflineReply(
        session: String,
        query: String,
        error: Throwable
    ): AppResult<ChatMessage> {
        val matches = OfflineCatalog.topMatches(query)
        val entity = ChatMessageEntity(
            id = UUID.randomUUID().toString(),
            sessionId = session,
            content = buildString {
                append(NetworkError.messageFor(error))
                append("\n\nBerikut ")
                append(matches.size)
                append(" produk dari katalog contoh yang paling mendekati permintaanmu:")
            },
            role = ChatRole.AGENT.name,
            timestamp = System.currentTimeMillis(),
            recommendedProducts = matches,
            suggestions = listOf("Tampilkan yang termurah", "Cari dengan budget lebih tinggi"),
            isError = true
        )
        chatMessageDao.upsert(entity)
        return AppResult.Success(entity.toDomain())
    }

    override suspend fun clearConversation() {
        withContext(ioDispatcher) { chatMessageDao.deleteSession(sessionId) }
    }

    override fun startNewSession(): String {
        val newSession = UUID.randomUUID().toString()
        sessionState.value = newSession
        return newSession
    }
}
