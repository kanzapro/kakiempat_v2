package com.shoppingagent.android.core.database.dao

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import com.shoppingagent.android.core.database.entity.WatchlistEntity
import kotlinx.coroutines.flow.Flow

@Dao
interface WatchlistDao {

    @Query("SELECT * FROM watchlist ORDER BY addedAt DESC")
    fun observeWatchlist(): Flow<List<WatchlistEntity>>

    @Query("SELECT EXISTS(SELECT 1 FROM watchlist WHERE productId = :productId)")
    suspend fun exists(productId: String): Boolean

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(item: WatchlistEntity)

    @Query("DELETE FROM watchlist WHERE productId = :productId")
    suspend fun delete(productId: String)

    @Query("UPDATE watchlist SET price = :price, originalPrice = :originalPrice WHERE productId = :productId")
    suspend fun updatePrice(productId: String, price: Long, originalPrice: Long?)
}
