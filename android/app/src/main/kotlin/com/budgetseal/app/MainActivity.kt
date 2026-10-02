package com.budgetseal.app

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // HomeWidgetService (Dart) saved new numbers: redraw the widgets now.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "budgetseal/widget")
            .setMethodCallHandler { call, result ->
                if (call.method == "update") {
                    val manager = AppWidgetManager.getInstance(this)
                    val ids = manager.getAppWidgetIds(
                        ComponentName(this, SpendingWidget::class.java))
                    for (id in ids) SpendingWidget.updateAppWidget(this, manager, id)
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
