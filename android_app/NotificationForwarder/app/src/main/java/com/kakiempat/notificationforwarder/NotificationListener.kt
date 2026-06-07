package com.kakiempat.notificationforwarder

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import java.util.concurrent.Executors
import java.util.regex.Pattern

/**
 * Mendengarkan notifikasi SeaBank / transfer masuk dan meneruskan ke webhook API.
 */
class NotificationListener : NotificationListenerService() {

    private val executor = Executors.newSingleThreadExecutor()
    private val seenKeys = LinkedHashSet<String>()

    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.i(TAG, "Notification listener connected")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        if (sbn == null) return
        val pkg = sbn.packageName ?: return
        if (!SEA_BANK_PACKAGES.contains(pkg)) return

        val extras = sbn.notification?.extras ?: return
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString().orEmpty()
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString().orEmpty()
        val bigText = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString().orEmpty()
        val combined = listOf(title, text, bigText).filter { it.isNotBlank() }.joinToString(" ")

        if (!isTransferNotification(combined)) return

        val dedupeKey = "${sbn.key}|$combined"
        synchronized(seenKeys) {
            if (seenKeys.contains(dedupeKey)) return
            seenKeys.add(dedupeKey)
            while (seenKeys.size > MAX_SEEN) {
                seenKeys.remove(seenKeys.first())
            }
        }

        val parsed = parseTransfer(combined) ?: run {
            Log.w(TAG, "Could not parse notification: $combined")
            return
        }

        val detectedBank = detectSenderBank(combined, parsed.bank)

        executor.execute {
            WebhookSender.send(
                WebhookSender.TransferPayload(
                    nominal = parsed.nominal,
                    bank = parsed.bank,
                    nama = parsed.nama,
                    timestamp = System.currentTimeMillis(),
                    rawNotification = combined,
                    detectedBank = detectedBank,
                ),
            )
        }
    }

    private fun isTransferNotification(text: String): Boolean {
        val lower = text.lowercase()
        return lower.contains("transfer masuk")
            || lower.contains("wise")
            || lower.contains("revolut")
    }

    private fun detectSenderBank(text: String, parsedBank: String): String {
        return when {
            text.contains("REVOLUT", ignoreCase = true)
                || parsedBank.equals("REVOLUT", ignoreCase = true) -> "SEABANK_REVOLUT"
            text.contains("WISE", ignoreCase = true)
                || parsedBank.equals("WISE", ignoreCase = true) -> "SEABANK_WISE"
            else -> "SEABANK_TRANSFER"
        }
    }

    private fun parseTransfer(text: String): ParsedTransfer? {
        val nominal = parseNominal(text) ?: return null
        val nama = parseSenderName(text)
        val bank = when {
            text.contains("REVOLUT", ignoreCase = true) -> "REVOLUT"
            text.contains("WISE", ignoreCase = true) -> "WISE"
            else -> "SeaBank"
        }
        return ParsedTransfer(nominal, bank, nama)
    }

    private fun parseNominal(text: String): Long? {
        val patterns = listOf(
            Pattern.compile("""Rp\s*([\d.,]+)""", Pattern.CASE_INSENSITIVE),
            Pattern.compile("""IDR\s*([\d.,]+)""", Pattern.CASE_INSENSITIVE),
            Pattern.compile("""([\d]{1,3}(?:[.,]\d{3})+)"""),
        )
        for (pattern in patterns) {
            val m = pattern.matcher(text)
            if (m.find()) {
                val raw = m.group(1)?.replace(".", "")?.replace(",", "") ?: continue
                val value = raw.toLongOrNull()
                if (value != null && value > 0) return value
            }
        }
        return null
    }

    /** Contoh: "Transfer masuk Rp 250.000 dari BUDI SANTOSO" */
    private fun parseSenderName(text: String): String {
        val patterns = listOf(
            Pattern.compile(
                """transfer\s+masuk\s+Rp\s*[\d.,]+\s+dari\s+(.+?)(?:\s+ke\s+|\s+pada\s+|$)""",
                Pattern.CASE_INSENSITIVE,
            ),
            Pattern.compile("""dari\s+(.+?)(?:\s+ke\s+|\s+pada\s+|$)""", Pattern.CASE_INSENSITIVE),
            Pattern.compile("""from\s+(.+?)(?:\s+to\s+|\s+on\s+|$)""", Pattern.CASE_INSENSITIVE),
        )
        for (pattern in patterns) {
            val m = pattern.matcher(text)
            if (m.find()) {
                return m.group(1)?.trim().orEmpty().ifBlank { "Tidak diketahui" }
            }
        }
        return "Tidak diketahui"
    }

    private data class ParsedTransfer(
        val nominal: Long,
        val bank: String,
        val nama: String,
    )

    companion object {
        private const val TAG = "NotificationListener"
        private const val MAX_SEEN = 200

        val SEA_BANK_PACKAGES = setOf(
            "com.seabank.android",
            "com.seabank.seabank",
            "id.co.bankbkemobile.digitalbank",
            "com.bankbkemobile.digitalbank",
        )
    }
}
