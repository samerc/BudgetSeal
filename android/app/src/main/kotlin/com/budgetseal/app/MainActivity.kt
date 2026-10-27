package com.budgetseal.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.app.NotificationManagerCompat
import org.json.JSONArray
import org.json.JSONObject
import android.util.Log
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterFragmentActivity() {
    private var channel: MethodChannel? = null

    /// A route asked for by a widget tap that Dart hasn't read yet.
    private var pendingRoute: String? = null

    private var shareChannel: MethodChannel? = null

    /// Something shared into the app that Dart hasn't taken yet:
    /// {"text": String, "files": [paths in the cache]}.
    private var pendingShare: Map<String, Any>? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        pendingRoute = intent?.getStringExtra(EXTRA_ROUTE)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "budgetseal/widget")
        channel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                // HomeWidgetService (Dart) saved new numbers: redraw the widgets now.
                "update" -> {
                    redrawAll(this)
                    result.success(null)
                }
                // Dart is ready: hand over the route of the widget that
                // launched the app (once).
                "launchRoute" -> {
                    result.success(pendingRoute)
                    pendingRoute = null
                }
                else -> result.notImplemented()
            }
        }
        // Bank alerts (BankAlerts in Dart): what AlertListener kept.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "budgetseal/alerts")
            .setMethodCallHandler { call, result ->
                val prefs = getSharedPreferences(AlertListener.PREFS, Context.MODE_PRIVATE)
                when (call.method) {
                    "status" -> {
                        val seen = JSONObject(prefs.getString(AlertListener.KEY_SEEN, "{}") ?: "{}")
                        val apps = JSONArray(prefs.getString(AlertListener.KEY_APPS, "[]") ?: "[]")
                        result.success(mapOf(
                            "enabled" to NotificationManagerCompat
                                .getEnabledListenerPackages(this).contains(packageName),
                            "seen" to seen.keys().asSequence().associateWith { seen.optString(it) },
                            "apps" to (0 until apps.length()).map { apps.optString(it) },
                        ))
                    }
                    "setApps" -> {
                        val apps = (call.arguments as? List<*>)?.map { it.toString() } ?: emptyList()
                        prefs.edit().putString(AlertListener.KEY_APPS, JSONArray(apps).toString()).apply()
                        result.success(null)
                    }
                    // The kept alerts, once (a JSON list).
                    "take" -> {
                        val queue = prefs.getString(AlertListener.KEY_QUEUE, "[]") ?: "[]"
                        prefs.edit().putString(AlertListener.KEY_QUEUE, "[]").apply()
                        result.success(queue)
                    }
                    "openSettings" -> {
                        startActivity(Intent(Settings.ACTION_NOTIFICATION_LISTENER_SETTINGS))
                        result.success(null)
                    }
                    else -> result.notImplemented()
                }
            }
        // Share into BudgetSeal (ShareIntake in Dart takes it when ready).
        pendingShare = readShare(intent)
        shareChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "budgetseal/share")
        shareChannel!!.setMethodCallHandler { call, result ->
            when (call.method) {
                "take" -> {
                    result.success(pendingShare)
                    pendingShare = null
                }
                else -> result.notImplemented()
            }
        }
    }

    // A widget tapped, or something shared, while the app is running.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val share = readShare(intent)
        if (share != null) {
            pendingShare = share
            shareChannel?.invokeMethod("arrived", null)
            return
        }
        val route = intent.getStringExtra(EXTRA_ROUTE) ?: return
        channel?.invokeMethod("open", route)
    }

    /// The text and image of a share, the image copied into the cache (the
    /// sharing app's permission to read it ends with this intent).
    private fun readShare(intent: Intent?): Map<String, Any>? {
        if (intent?.action != Intent.ACTION_SEND) return null
        val text = listOfNotNull(
            intent.getStringExtra(Intent.EXTRA_SUBJECT),
            intent.getStringExtra(Intent.EXTRA_TEXT),
        ).joinToString("\n")
        val uri: Uri? = if (Build.VERSION.SDK_INT >= 33) {
            intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
        } else {
            @Suppress("DEPRECATION")
            intent.getParcelableExtra(Intent.EXTRA_STREAM)
        }
        val files = listOfNotNull(uri?.let { copyToCache(it, intent.type) })
        // Read once: a recreated activity mustn't share it again.
        intent.action = Intent.ACTION_MAIN
        if (text.isBlank() && files.isEmpty()) return null
        return mapOf("text" to text, "files" to files)
    }

    /// [shareType]: the share's own type, for providers that don't say.
    private fun copyToCache(uri: Uri, shareType: String?): String? = try {
        val type = contentResolver.getType(uri) ?: shareType ?: ""
        if (!type.startsWith("image/")) {
            null
        } else {
            val ext = when {
                type.contains("png") -> "png"
                type.contains("webp") -> "webp"
                else -> "jpg"
            }
            val dir = File(cacheDir, "shared").apply { mkdirs() }
            val file = File(dir, "share_${System.currentTimeMillis()}.$ext")
            contentResolver.openInputStream(uri)?.use { input ->
                file.outputStream().use { input.copyTo(it) }
            }
            file.absolutePath
        }
    } catch (e: Exception) {
        Log.w("BudgetSealShare", "copying $uri failed: $e")
        null
    }

    companion object {
        const val EXTRA_ROUTE = "budgetseal_route"

        /// Opens the app on [route] (handled by Dart's HomeWidgetService).
        fun routeIntent(context: Context, route: String, requestCode: Int): PendingIntent {
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP
                putExtra(EXTRA_ROUTE, route)
            }
            return PendingIntent.getActivity(
                context, requestCode, intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
        }

        fun redrawAll(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            for (id in manager.getAppWidgetIds(ComponentName(context, SpendingWidget::class.java)))
                SpendingWidget.updateAppWidget(context, manager, id)
            for (id in manager.getAppWidgetIds(ComponentName(context, EnvelopesWidget::class.java)))
                EnvelopesWidget.updateAppWidget(context, manager, id)
            for (id in manager.getAppWidgetIds(ComponentName(context, QuickAddWidget::class.java)))
                QuickAddWidget.updateAppWidget(context, manager, id)
        }
    }
}
