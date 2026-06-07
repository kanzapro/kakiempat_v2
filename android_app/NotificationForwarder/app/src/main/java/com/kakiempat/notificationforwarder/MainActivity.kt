package com.kakiempat.notificationforwarder

import android.content.ComponentName
import android.content.Intent
import android.graphics.Typeface
import android.os.Bundle
import android.provider.Settings
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import androidx.appcompat.app.AppCompatActivity

class MainActivity : AppCompatActivity() {

    private lateinit var statusView: TextView
    private lateinit var logView: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        statusView = TextView(this).apply {
            textSize = 16f
            setPadding(0, 0, 0, 24)
        }
        val openSettings = Button(this).apply {
            text = getString(R.string.open_notification_access)
            setOnClickListener { openNotificationAccess() }
        }
        val refresh = Button(this).apply {
            text = getString(R.string.refresh_status)
            setOnClickListener { refreshUi() }
        }
        logView = TextView(this).apply {
            textSize = 12f
            typeface = Typeface.MONOSPACE
            setPadding(0, 24, 0, 0)
        }
        val logScroll = ScrollView(this).apply {
            addView(logView)
        }

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(48, 48, 48, 48)
            addView(statusView)
            addView(openSettings)
            addView(refresh)
            addView(
                TextView(this@MainActivity).apply {
                    text = getString(R.string.webhook_log_title)
                    setPadding(0, 32, 0, 8)
                    setTypeface(null, Typeface.BOLD)
                },
            )
            addView(
                logScroll,
                LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    0,
                    1f,
                ),
            )
        }
        setContentView(root)
        refreshUi()
    }

    override fun onResume() {
        super.onResume()
        refreshUi()
    }

    private fun openNotificationAccess() {
        startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
    }

    private fun refreshUi() {
        val listening = isNotificationListenerEnabled()
        statusView.text = if (listening) {
            getString(R.string.status_listening)
        } else {
            getString(R.string.status_not_listening)
        }
        val lines = WebhookLogStore.lines()
        logView.text = if (lines.isEmpty()) {
            getString(R.string.log_empty)
        } else {
            lines.joinToString("\n")
        }
    }

    private fun isNotificationListenerEnabled(): Boolean {
        val flat = Settings.Secure.getString(
            contentResolver,
            "enabled_notification_listeners",
        ) ?: return false
        val expected = ComponentName(this, NotificationListener::class.java)
        return flat.split(':').any { part ->
            ComponentName.unflattenFromString(part) == expected
        }
    }
}
