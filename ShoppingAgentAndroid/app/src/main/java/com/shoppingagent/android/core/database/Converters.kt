package com.shoppingagent.android.core.database

import androidx.room.TypeConverter
import com.shoppingagent.android.core.AppJson
import com.shoppingagent.android.core.model.Product

/**
 * Serialisasi JSON kustom untuk menyimpan daftar produk & saran langsung di dalam entitas chat.
 * Kegagalan parse dikembalikan sebagai daftar kosong agar database tidak pernah membuat app crash.
 */
class Converters {

    @TypeConverter
    fun fromProductList(value: List<Product>): String = AppJson.encodeToString(value)

    @TypeConverter
    fun toProductList(value: String): List<Product> =
        runCatching { AppJson.decodeFromString<List<Product>>(value) }.getOrDefault(emptyList())

    @TypeConverter
    fun fromStringList(value: List<String>): String = AppJson.encodeToString(value)

    @TypeConverter
    fun toStringList(value: String): List<String> =
        runCatching { AppJson.decodeFromString<List<String>>(value) }.getOrDefault(emptyList())
}
