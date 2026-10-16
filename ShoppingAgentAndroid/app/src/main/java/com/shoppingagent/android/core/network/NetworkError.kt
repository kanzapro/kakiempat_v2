package com.shoppingagent.android.core.network

import kotlinx.serialization.SerializationException
import retrofit2.HttpException
import java.io.IOException
import java.net.SocketTimeoutException
import java.net.UnknownHostException

/** Menerjemahkan exception jaringan menjadi pesan siap tampil di UI. */
object NetworkError {

    const val MESSAGE_OFFLINE = "Server agen tidak dapat dihubungi. Memakai katalog offline."
    const val MESSAGE_UNKNOWN = "Terjadi kesalahan tidak terduga saat menghubungi server."

    fun messageFor(error: Throwable): String = when (error) {
        is UnknownHostException -> "Server tidak ditemukan. Periksa koneksi internet atau Base URL."
        is SocketTimeoutException -> "Server tidak merespons tepat waktu. Coba lagi."
        is HttpException -> "Server mengembalikan kode error ${error.code()}."
        is SerializationException -> "Format respons server tidak dikenali aplikasi."
        is IOException -> "Koneksi ke server terputus. Periksa jaringan Anda."
        else -> error.message?.takeIf { it.isNotBlank() } ?: MESSAGE_UNKNOWN
    }
}
