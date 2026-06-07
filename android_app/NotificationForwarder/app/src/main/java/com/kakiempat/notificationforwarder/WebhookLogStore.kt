package com.kakiempat.notificationforwarder

import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/** Log webhook terkirim/gagal untuk ditampilkan di MainActivity. */
object WebhookLogStore {

    private const val MAX_ENTRIES = 50
    private val entries = ArrayDeque<String>()
    private val timeFmt = SimpleDateFormat("HH:mm:ss", Locale.getDefault())

    fun appendSuccess(nominal: Long, bank: String, nama: String, httpCode: Int) {
        append("OK $httpCode — Rp $nominal · $bank · $nama")
    }

    fun appendFailure(message: String) {
        append("GAGAL — $message")
    }

    fun lines(): List<String> = synchronized(entries) { entries.toList() }

    private fun append(line: String) {
        val stamped = "${timeFmt.format(Date())} $line"
        synchronized(entries) {
            entries.addFirst(stamped)
            while (entries.size > MAX_ENTRIES) {
                entries.removeLast()
            }
        }
    }
}
