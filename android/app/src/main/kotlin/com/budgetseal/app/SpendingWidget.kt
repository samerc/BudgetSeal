package com.budgetseal.app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

class SpendingWidget : AppWidgetProvider() {

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
            val views = RemoteViews(context.packageName, R.layout.spending_widget)

            // Written by HomeWidgetService (Dart) through shared_preferences,
            // which stores keys with a "flutter." prefix in this file.
            val prefs = context.getSharedPreferences(
                "FlutterSharedPreferences", Context.MODE_PRIVATE)
            views.setTextViewText(R.id.widget_title,
                prefs.getString("flutter.widget_title", "BudgetSeal"))
            views.setTextViewText(R.id.widget_spending,
                prefs.getString("flutter.widget_line", ""))

            // Tapping the widget opens the main activity
            val intent = Intent(context, MainActivity::class.java).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
            }
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
