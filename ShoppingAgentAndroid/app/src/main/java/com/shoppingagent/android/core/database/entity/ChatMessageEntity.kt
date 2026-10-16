package com.shoppingagent.android.core.database.entity

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey
import com.shoppingagent.android.core.model.ChatMessage
import com.shoppingagent.android.core.model.ChatRole
import com.shoppingagent.android.core.model.Product

/**
 * Entitas pesan chat. Daftar produk rekomendasi & saran disimpan sebagai JSON
 * (lihat [com.shoppingagent.android.core.database.Converters]).
 */
@Entity(
    tableName = "chat_messages",
    indices = [Index(value = ["sessionId"])]
)
data class ChatMessageEntity(
    @PrimaryKey val id: String,
    val sessionId: String,
    val content: String,
    val role: String,
    val timestamp: Long,
    val recommendedProducts: List<Product> = emptyList(),
    val suggestions: List<String> = emptyList(),
    val isError: Boolean = false
)

fun ChatMessageEntity.toDomain(): ChatMessage = ChatMessage(
    id = id,
    sessionId = sessionId,
    content = content,
    role = ChatRole.fromRaw(role),
    timestamp = timestamp,
    recommendedProducts = recommendedProducts,
    suggestions = suggestions,
    isError = isError
)

fun ChatMessage.toEntity(): ChatMessageEntity = ChatMessageEntity(
    id = id,
    sessionId = sessionId,
    content = content,
    role = role.name,
    timestamp = timestamp,
    recommendedProducts = recommendedProducts,
    suggestions = suggestions,
    isError = isError
)
