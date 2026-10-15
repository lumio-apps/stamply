package com.lumioapps.stamply

import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.os.Build
import androidx.core.app.NotificationCompat
import org.json.JSONArray
import org.json.JSONObject

/// Passport expiry reminders: plain AlarmManager alarms, no extra plugin.
/// The list is also kept in SharedPreferences so it can be set again after a reboot.
object Reminders {
    private const val CHANNEL_ID = "passport_expiry"
    private const val PREFS = "stamply_reminders"
    private const val KEY = "items"

    fun schedule(context: Context, items: JSONArray) {
        cancelAll(context)
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .edit().putString(KEY, items.toString()).apply()
        setAlarms(context, items)
    }

    fun cancelAll(context: Context) {
        val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val old = prefs.getString(KEY, null)
        if (old != null) {
            try {
                val items = JSONArray(old)
                val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
                for (i in 0 until items.length()) {
                    val id = items.getJSONObject(i).getInt("id")
                    alarms.cancel(pendingIntent(context, id, "", ""))
                }
            } catch (_: Exception) {
            }
        }
        prefs.edit().remove(KEY).apply()
    }

    /// Called after a reboot or an app update, when the alarms are gone.
    fun restore(context: Context) {
        val saved = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            .getString(KEY, null) ?: return
        try {
            setAlarms(context, JSONArray(saved))
        } catch (_: Exception) {
        }
    }

    private fun setAlarms(context: Context, items: JSONArray) {
        val alarms = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
        val now = System.currentTimeMillis()
        for (i in 0 until items.length()) {
            val item: JSONObject = items.getJSONObject(i)
            val at = item.getLong("at")
            if (at <= now) continue
            val pi = pendingIntent(
                context, item.getInt("id"), item.getString("title"), item.getString("body")
            )
            // Inexact but still delivered in Doze mode; no special permission needed.
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at, pi)
            } else {
                alarms.set(AlarmManager.RTC_WAKEUP, at, pi)
            }
        }
    }

    private fun pendingIntent(context: Context, id: Int, title: String, body: String): PendingIntent {
        val intent = Intent(context, ReminderReceiver::class.java).apply {
            putExtra("id", id)
            putExtra("title", title)
            putExtra("body", body)
        }
        return PendingIntent.getBroadcast(
            context, id, intent, PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
    }

    fun show(context: Context, id: Int, title: String, body: String) {
        val manager = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            manager.createNotificationChannel(
                NotificationChannel(CHANNEL_ID, title, NotificationManager.IMPORTANCE_DEFAULT)
            )
        }
        val open = PendingIntent.getActivity(
            context, 0, Intent(context, MainActivity::class.java),
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        val notification = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_notification)
            .setContentTitle(title)
            .setContentText(body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(body))
            .setContentIntent(open)
            .setAutoCancel(true)
            .build()
        try {
            manager.notify(id, notification)
        } catch (_: SecurityException) {
            // Notification permission was taken away.
        }
    }
}

class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val title = intent.getStringExtra("title") ?: return
        val body = intent.getStringExtra("body") ?: return
        if (title.isEmpty()) return
        Reminders.show(context, intent.getIntExtra("id", 0), title, body)
    }
}

class ReminderBootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        Reminders.restore(context)
    }
}
