package com.budgetseal.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.view.View
import android.widget.RemoteViews

/// Up to three templates (most used first), each opening the add form
/// filled in from it ("/template/<id>"), and a "+" for an empty form. The
/// labels ("Coffee\n$4.00") are written by HomeWidgetService (Dart).
class TemplatesWidget : AppWidgetProvider() {

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
        private val slots = intArrayOf(R.id.tmpl_0, R.id.tmpl_1, R.id.tmpl_2)

        internal fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.templates_widget)
            val prefs = context.getSharedPreferences(
                "FlutterSharedPreferences", Context.MODE_PRIVATE)
            // Flutter stores ints as longs.
            val count = prefs.getLong("flutter.widget_tmpl_count", 0L).toInt()
            for ((i, slot) in slots.withIndex()) {
                val id = prefs.getString("flutter.widget_tmpl_id_$i", null)
                if (i < count && id != null) {
                    views.setViewVisibility(slot, View.VISIBLE)
                    views.setTextViewText(slot,
                        prefs.getString("flutter.widget_tmpl_label_$i", ""))
                    views.setOnClickPendingIntent(slot,
                        MainActivity.routeIntent(context, "/template/$id", 10 + i))
                } else {
                    views.setViewVisibility(slot, View.GONE)
                }
            }
            views.setViewVisibility(R.id.tmpl_empty,
                if (count == 0) View.VISIBLE else View.GONE)
            views.setTextViewText(R.id.tmpl_empty,
                prefs.getString("flutter.widget_tmpl_empty", ""))
            views.setOnClickPendingIntent(R.id.tmpl_add,
                MainActivity.routeIntent(context, "/add-transaction", 13))
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
