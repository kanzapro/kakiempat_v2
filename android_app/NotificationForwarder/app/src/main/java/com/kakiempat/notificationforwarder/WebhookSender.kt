package com.kakiempat.notificationforwarder

import android.util.Log
import com.kakiempat.notificationforwarder.BuildConfig
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.util.concurrent.TimeUnit

/**
 * HTTP POST ke payment_webhook.php dengan retry.
 */
object WebhookSender {

    private const val TAG = "WebhookSender"
    private const val MAX_ATTEMPTS = 3
    private val JSON_MEDIA = "application/json; charset=utf-8".toMediaType()

    private val client = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(15, TimeUnit.SECONDS)
        .writeTimeout(15, TimeUnit.SECONDS)
        .build()

    data class TransferPayload(
        val nominal: Long,
        val bank: String,
        val nama: String,
        val timestamp: Long,
        val rawNotification: String = "",
        val detectedBank: String = "SEABANK_TRANSFER",
    )

    fun send(payload: TransferPayload) {
        val secret = BuildConfig.PAYMENT_WEBHOOK_SECRET
        if (secret.isBlank()) {
            val msg = "PAYMENT_WEBHOOK_SECRET kosong — set payment.webhook.secret di local.properties"
            Log.e(TAG, msg)
            WebhookLogStore.appendFailure(msg)
            return
        }

        val bodyJson = JSONObject().apply {
            put("nominal", payload.nominal)
            put("bank", payload.bank)
            put("nama", payload.nama)
            put("timestamp", payload.timestamp)
            put("bank_pengirim", payload.bank)
            put("nama_pengirim", payload.nama)
            put("detected_bank", payload.detectedBank)
            put("sender_bank", payload.detectedBank)
            if (payload.rawNotification.isNotBlank()) {
                put("raw_notification", payload.rawNotification)
                put("text", payload.rawNotification)
            }
        }.toString()

        var lastError = "unknown"
        for (attempt in 1..MAX_ATTEMPTS) {
            try {
                val request = Request.Builder()
                    .url(BuildConfig.PAYMENT_WEBHOOK_URL)
                    .post(bodyJson.toRequestBody(JSON_MEDIA))
                    .header("Content-Type", "application/json; charset=utf-8")
                    .header("X-Payment-Webhook-Secret", secret)
                    .build()

                client.newCall(request).execute().use { response ->
                    val responseBody = (response.body?.string()).orEmpty()
                    if (response.isSuccessful) {
                        Log.i(TAG, "Webhook OK (${response.code}): $responseBody")
                        WebhookLogStore.appendSuccess(
                            payload.nominal,
                            payload.bank,
                            payload.nama,
                            response.code,
                        )
                        return
                    }
                    lastError = "HTTP ${response.code}: $responseBody"
                    Log.w(TAG, "Attempt $attempt failed: $lastError")
                }
            } catch (e: Exception) {
                lastError = e.message ?: e.javaClass.simpleName
                Log.w(TAG, "Attempt $attempt error", e)
            }
            if (attempt < MAX_ATTEMPTS) {
                Thread.sleep((attempt * 1000L))
            }
        }
        WebhookLogStore.appendFailure(lastError)
        Log.e(TAG, "Webhook gave up after $MAX_ATTEMPTS attempts")
    }
}
