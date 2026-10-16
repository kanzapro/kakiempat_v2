package com.shoppingagent.android

import com.shoppingagent.android.core.model.Product
import com.shoppingagent.android.core.model.UserPreferences
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class ProductTest {

    private val product = Product(
        id = "prod-101",
        title = "Soundcore Life P3i TWS ANC",
        price = 750_000L,
        originalPrice = 1_000_000L,
        rating = 4.7,
        reviewCount = 1_248,
        storeName = "Soundcore Official Store",
        aiSummary = "ANC hibrida untuk komuter harian.",
        category = "Audio"
    )

    @Test
    fun `diskon dihitung dari harga awal`() {
        assertEquals(25, product.discountPercent)
        assertTrue(product.hasDiscount)
    }

    @Test
    fun `tanpa harga awal tidak ada diskon`() {
        val tanpaHargaAwal = product.copy(originalPrice = null)

        assertEquals(0, tanpaHargaAwal.discountPercent)
        assertFalse(tanpaHargaAwal.hasDiscount)
    }

    @Test
    fun `harga awal yang lebih rendah diabaikan`() {
        val aneh = product.copy(originalPrice = 500_000L)

        assertEquals(0, aneh.discountPercent)
        assertFalse(aneh.hasDiscount)
    }

    @Test
    fun `rating dibatasi antara nol dan lima`() {
        assertEquals(5.0, product.copy(rating = 9.9).safeRating, 0.0001)
        assertEquals(0.0, product.copy(rating = -3.0).safeRating, 0.0001)
    }

    @Test
    fun `pencarian keyword mencocokkan judul toko dan kategori`() {
        assertTrue(product.matches("tws"))
        assertTrue(product.matches("official"))
        assertTrue(product.matches("audio"))
        assertFalse(product.matches("sepatu"))
    }

    @Test
    fun `base url selalu dinormalkan berakhir dengan slash`() {
        assertEquals("https://api.example.com/", UserPreferences(baseUrl = "https://api.example.com").safeBaseUrl)
        assertEquals(UserPreferences.DEFAULT_BASE_URL, UserPreferences(baseUrl = "   ").safeBaseUrl)
    }

    @Test
    fun `budget konteks dibatasi pada nilai maksimum`() {
        assertEquals(
            UserPreferences.MAX_CONTEXT_BUDGET,
            UserPreferences(contextBudget = Long.MAX_VALUE).safeContextBudget
        )
        assertEquals(0L, UserPreferences(contextBudget = -1L).safeContextBudget)
    }

    @Test
    fun `preferensi default memakai model gpt-4o-mini`() {
        assertEquals("gpt-4o-mini", UserPreferences().modelName)
        assertFalse(UserPreferences().hasApiKey)
        assertTrue(UserPreferences(apiKey = "sk-test").hasApiKey)
    }
}
