package com.shoppingagent.android.core.network

import com.shoppingagent.android.core.network.dto.ChatRequestDto
import com.shoppingagent.android.core.network.dto.ChatResponseDto
import com.shoppingagent.android.core.network.dto.SearchRequestDto
import com.shoppingagent.android.core.network.dto.SearchResponseDto
import retrofit2.http.Body
import retrofit2.http.POST

/**
 * Kontrak REST ke backend agen (perantara LLM / function calling / scraping).
 */
interface AgentApiService {

    @POST("api/v1/agent/chat")
    suspend fun sendMessage(@Body request: ChatRequestDto): ChatResponseDto

    @POST("api/v1/products/search")
    suspend fun searchProducts(@Body request: SearchRequestDto): SearchResponseDto
}
