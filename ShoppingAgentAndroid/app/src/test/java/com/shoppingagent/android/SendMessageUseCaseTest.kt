package com.shoppingagent.android

import com.shoppingagent.android.core.model.AppResult
import com.shoppingagent.android.core.model.ChatMessage
import com.shoppingagent.android.domain.usecase.SendMessageUseCase
import kotlinx.coroutines.test.runTest
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class SendMessageUseCaseTest {

    @Test
    fun `pesan kosong ditolak tanpa memanggil repository`() = runTest {
        val repository = FakeShoppingAgentRepository()
        val useCase = SendMessageUseCase(repository)

        val result = useCase("   ")

        assertTrue(result is AppResult.Failure)
        assertEquals(SendMessageUseCase.ERROR_EMPTY, (result as AppResult.Failure).message)
        assertTrue(repository.sentTexts.isEmpty())
    }

    @Test
    fun `pesan melebihi batas karakter ditolak`() = runTest {
        val repository = FakeShoppingAgentRepository()
        val useCase = SendMessageUseCase(repository)

        val result = useCase("a".repeat(SendMessageUseCase.MAX_LENGTH + 1))

        assertTrue(result is AppResult.Failure)
        assertEquals(SendMessageUseCase.ERROR_TOO_LONG, (result as AppResult.Failure).message)
        assertTrue(repository.sentTexts.isEmpty())
    }

    @Test
    fun `pesan valid diteruskan dalam bentuk ter-trim`() = runTest {
        val repository = FakeShoppingAgentRepository()
        val useCase = SendMessageUseCase(repository)

        val result = useCase("  Cari TWS ANC  ")

        assertTrue(result is AppResult.Success)
        assertEquals(listOf("Cari TWS ANC"), repository.sentTexts)
        val message = (result as AppResult.Success<ChatMessage>).data
        assertEquals("echo: Cari TWS ANC", message.content)
    }

    @Test
    fun `kegagalan repository diteruskan sebagai failure`() = runTest {
        val repository = FakeShoppingAgentRepository().apply {
            failure = IllegalStateException("server agen mati")
        }
        val useCase = SendMessageUseCase(repository)

        val result = useCase("halo")

        assertTrue(result is AppResult.Failure)
        assertEquals("server agen mati", (result as AppResult.Failure).message)
    }
}
