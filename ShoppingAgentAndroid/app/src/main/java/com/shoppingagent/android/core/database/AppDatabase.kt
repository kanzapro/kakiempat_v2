package com.shoppingagent.android.core.database

import android.content.Context
import androidx.room.Database
import androidx.room.Room
import androidx.room.RoomDatabase
import androidx.room.TypeConverters
import com.shoppingagent.android.core.database.dao.ChatMessageDao
import com.shoppingagent.android.core.database.dao.WatchlistDao
import com.shoppingagent.android.core.database.entity.ChatMessageEntity
import com.shoppingagent.android.core.database.entity.WatchlistEntity

@Database(
    entities = [ChatMessageEntity::class, WatchlistEntity::class],
    version = 1,
    exportSchema = false
)
@TypeConverters(Converters::class)
abstract class AppDatabase : RoomDatabase() {

    abstract fun chatMessageDao(): ChatMessageDao

    abstract fun watchlistDao(): WatchlistDao

    companion object {
        const val DATABASE_NAME = "shopping_agent.db"

        @Volatile
        private var instance: AppDatabase? = null

        fun getInstance(context: Context): AppDatabase =
            instance ?: synchronized(this) {
                instance ?: build(context).also { instance = it }
            }

        private fun build(context: Context): AppDatabase =
            Room.databaseBuilder(
                context.applicationContext,
                AppDatabase::class.java,
                DATABASE_NAME
            )
                .fallbackToDestructiveMigration()
                .build()
    }
}
