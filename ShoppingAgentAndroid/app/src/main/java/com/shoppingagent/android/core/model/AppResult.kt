package com.shoppingagent.android.core.model

/**
 * Pembungkus hasil operasi asinkron (berhasil / gagal) yang dipakai lintas lapisan.
 * Sengaja bukan [kotlin.Result] agar tipe gagal dapat membawa pesan siap-tampil ke UI.
 */
sealed interface AppResult<out T> {

    data class Success<T>(val data: T) : AppResult<T>

    data class Failure(
        val message: String,
        val cause: Throwable? = null
    ) : AppResult<Nothing>

    data object Loading : AppResult<Nothing>
}

inline fun <T> AppResult<T>.onSuccess(block: (T) -> Unit): AppResult<T> {
    if (this is AppResult.Success) block(data)
    return this
}

inline fun <T> AppResult<T>.onFailure(block: (AppResult.Failure) -> Unit): AppResult<T> {
    if (this is AppResult.Failure) block(this)
    return this
}

fun <T> AppResult<T>.dataOrNull(): T? = (this as? AppResult.Success)?.data

fun AppResult<*>.errorMessageOrNull(): String? = (this as? AppResult.Failure)?.message
