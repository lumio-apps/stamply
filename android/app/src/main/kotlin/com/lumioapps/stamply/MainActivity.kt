package com.lumioapps.stamply

import android.Manifest
import android.app.NotificationManager
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import androidx.core.content.pm.ShortcutInfoCompat
import androidx.core.content.pm.ShortcutManagerCompat
import androidx.core.graphics.drawable.IconCompat
import org.json.JSONArray
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private var pendingPermission: MethodChannel.Result? = null

    /// Set when the app is opened from an app shortcut; the Dart side asks for it.
    private var pendingShortcut: String? = null

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        pendingShortcut = intent?.getStringExtra("shortcut")
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        intent.getStringExtra("shortcut")?.let { pendingShortcut = it }
    }

    private fun notificationsAllowed(): Boolean {
        if (Build.VERSION.SDK_INT >= 33) {
            return checkSelfPermission(Manifest.permission.POST_NOTIFICATIONS) ==
                PackageManager.PERMISSION_GRANTED
        }
        val manager = getSystemService(NOTIFICATION_SERVICE) as NotificationManager
        return manager.areNotificationsEnabled()
    }

    override fun onRequestPermissionsResult(
        requestCode: Int, permissions: Array<out String>, grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 4711) {
            pendingPermission?.success(notificationsAllowed())
            pendingPermission = null
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Home-screen widget text and long-press app shortcuts.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "lumio/integration")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "updateWidget" -> {
                        PassportWidget.save(
                            this,
                            call.argument<String>("title") ?: "Stamply",
                            call.argument<String>("line1") ?: "",
                            call.argument<String>("line2") ?: ""
                        )
                        result.success(null)
                    }
                    "setShortcuts" -> {
                        val list = call.argument<List<Map<String, Any>>>("items") ?: emptyList()
                        val shortcuts = list.map { item ->
                            val target = item["action"] as String
                            ShortcutInfoCompat.Builder(this, target)
                                .setShortLabel(item["label"] as String)
                                .setIcon(IconCompat.createWithResource(this, R.mipmap.ic_launcher))
                                .setIntent(
                                    Intent(this, MainActivity::class.java).apply {
                                        this.action = Intent.ACTION_VIEW
                                        putExtra("shortcut", target)
                                    }
                                )
                                .build()
                        }
                        try {
                            ShortcutManagerCompat.setDynamicShortcuts(this, shortcuts)
                        } catch (_: Exception) {
                        }
                        result.success(null)
                    }
                    "consumeShortcut" -> {
                        val value = pendingShortcut
                        pendingShortcut = null
                        result.success(value)
                    }
                    else -> result.notImplemented()
                }
            }

        // Passport expiry reminders (alarms and notifications, see Reminders.kt).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "lumio/reminders")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "requestPermission" -> {
                        if (notificationsAllowed()) {
                            result.success(true)
                        } else if (Build.VERSION.SDK_INT >= 33 && pendingPermission == null) {
                            pendingPermission = result
                            requestPermissions(arrayOf(Manifest.permission.POST_NOTIFICATIONS), 4711)
                        } else {
                            result.success(false)
                        }
                    }
                    "schedule" -> {
                        val items = JSONArray()
                        val list = call.argument<List<Map<String, Any>>>("items") ?: emptyList()
                        for (item in list) {
                            items.put(
                                org.json.JSONObject().apply {
                                    put("id", (item["id"] as Number).toInt())
                                    put("at", (item["at"] as Number).toLong())
                                    put("title", item["title"] as String)
                                    put("body", item["body"] as String)
                                }
                            )
                        }
                        Reminders.schedule(this, items)
                        result.success(null)
                    }
                    "cancelAll" -> {
                        Reminders.cancelAll(this)
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }

        // Opens the system share sheet without an extra plugin.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "lumio/share")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "shareText" -> {
                        val text = call.argument<String>("text") ?: ""
                        val send = Intent(Intent.ACTION_SEND).apply {
                            type = "text/plain"
                            putExtra(Intent.EXTRA_TEXT, text)
                        }
                        startActivity(Intent.createChooser(send, null))
                        result.success(null)
                    }
                    "shareImage" -> {
                        val path = call.argument<String>("path")
                        val text = call.argument<String>("text") ?: ""
                        if (path == null) {
                            result.error("NO_PATH", "Missing image path", null)
                        } else {
                            try {
                                val uri = FileProvider.getUriForFile(
                                    this, "$packageName.fileprovider", File(path)
                                )
                                val send = Intent(Intent.ACTION_SEND).apply {
                                    type = "image/png"
                                    putExtra(Intent.EXTRA_STREAM, uri)
                                    putExtra(Intent.EXTRA_TEXT, text)
                                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                                }
                                startActivity(Intent.createChooser(send, null))
                                result.success(null)
                            } catch (e: Exception) {
                                result.error("SHARE_FAILED", e.message, null)
                            }
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
