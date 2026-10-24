package com.budgetseal.app

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.widget.RemoteViews

/// One button: opens the add-transaction form. Its label is written by
/// HomeWidgetService (Dart) in the app's language.
class QuickAddWidget : AppWidgetProvider() {

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
        internal fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            val views = RemoteViews(context.packageName, R.layout.quick_add_widget)
            val prefs = context.getSharedPreferences(
                "FlutterSharedPreferences", Context.MODE_PRIVATE)
            views.setTextViewText(R.id.quick_add_label,
                prefs.getString("flutter.widget_add_label", "Add"))
            views.setOnClickPendingIntent(R.id.quick_add_root,
                MainActivity.routeIntent(context, "/add-transaction", 2))
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
