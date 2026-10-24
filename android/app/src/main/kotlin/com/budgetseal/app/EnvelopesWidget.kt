package com.budgetseal.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.view.View
import android.widget.RemoteViews

/// Up to four spending envelopes with what's left in each. The rows are
/// written by HomeWidgetService (Dart) to shared preferences
/// ("flutter.widget_env_*"); tapping opens the app on Fund envelopes.
class EnvelopesWidget : AppWidgetProvider() {

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    companion object {
        private val rows = arrayOf(
            Triple(R.id.env_row_0, R.id.env_name_0, R.id.env_amount_0),
            Triple(R.id.env_row_1, R.id.env_name_1, R.id.env_amount_1),
            Triple(R.id.env_row_2, R.id.env_name_2, R.id.env_amount_2),
            Triple(R.id.env_row_3, R.id.env_name_3, R.id.env_amount_3),
        )

        internal fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.envelopes_widget)
            val prefs = context.getSharedPreferences(
                "FlutterSharedPreferences", Context.MODE_PRIVATE)
            views.setTextViewText(R.id.env_title,
                prefs.getString("flutter.widget_env_title", "Envelopes"))
            // shared_preferences stores Dart ints as Long.
            val count = prefs.getLong("flutter.widget_env_count", 0L).toInt()
            for ((i, ids) in rows.withIndex()) {
                val (row, name, amount) = ids
                if (i < count) {
                    views.setViewVisibility(row, View.VISIBLE)
                    views.setTextViewText(name,
                        prefs.getString("flutter.widget_env_name_$i", ""))
                    views.setTextViewText(amount,
                        prefs.getString("flutter.widget_env_amount_$i", ""))
                    val negative = prefs.getBoolean("flutter.widget_env_neg_$i", false)
                    views.setTextColor(amount,
                        if (negative) 0xFFC62828.toInt() else 0xFF1B1B1F.toInt())
                } else {
                    views.setViewVisibility(row, View.GONE)
                }
            }
            views.setViewVisibility(R.id.env_empty,
                if (count == 0) View.VISIBLE else View.GONE)
            views.setTextViewText(R.id.env_empty,
                prefs.getString("flutter.widget_env_empty", ""))
            views.setOnClickPendingIntent(R.id.env_root,
                MainActivity.routeIntent(context, "/funding", 1))
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
