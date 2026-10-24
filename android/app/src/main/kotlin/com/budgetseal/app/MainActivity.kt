package com.budgetseal.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private var channel: MethodChannel? = null

    /// A route asked for by a widget tap that Dart hasn't read yet.
    private var pendingRoute: String? = null

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
    }

    // A widget tapped while the app is running.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val route = intent.getStringExtra(EXTRA_ROUTE) ?: return
        channel?.invokeMethod("open", route)
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
