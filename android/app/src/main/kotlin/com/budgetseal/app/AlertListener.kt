package com.budgetseal.app

import android.app.Notification
import android.content.Context
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import org.json.JSONArray
import org.json.JSONObject

/// Bank alerts (roadmap #2): with the user's permission (system settings),
/// reads notifications. Of every app it only notes the name, so the user
/// can pick their bank apps; the text is kept only for the picked ones, on
/// the phone, until the app takes it (MainActivity "budgetseal/alerts").
class AlertListener : NotificationListenerService() {

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val pkg = sbn.packageName ?: return
        if (pkg == packageName) return
        val n = sbn.notification ?: return
        if (n.flags and Notification.FLAG_GROUP_SUMMARY != 0) return
        val prefs = getSharedPreferences(PREFS, Context.MODE_PRIVATE)

        // The app's name, for the picker (no content).
        val seen = JSONObject(prefs.getString(KEY_SEEN, "{}") ?: "{}")
        if (!seen.has(pkg)) {
            val label = try {
                packageManager.getApplicationLabel(
                    packageManager.getApplicationInfo(pkg, 0)).toString()
            } catch (e: Exception) {
                pkg
            }
            seen.put(pkg, label)
            prefs.edit().putString(KEY_SEEN, seen.toString()).apply()
        }

        val picked = JSONArray(prefs.getString(KEY_APPS, "[]") ?: "[]")
        if ((0 until picked.length()).none { picked.optString(it) == pkg }) return

        val extras = n.extras
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString() ?: ""
        val text = (extras.getCharSequence(Notification.EXTRA_BIG_TEXT)
            ?: extras.getCharSequence(Notification.EXTRA_TEXT))?.toString() ?: ""
        if (text.isBlank()) return

        // An update of the same notification with the same text isn't new.
        val id = "${sbn.key}|${text.hashCode()}"
        val queue = JSONArray(prefs.getString(KEY_QUEUE, "[]") ?: "[]")
        for (i in 0 until queue.length()) {
            if (queue.optJSONObject(i)?.optString("id") == id) return
        }
        queue.put(JSONObject().apply {
            put("id", id)
            put("app", pkg)
            put("appName", seen.optString(pkg, pkg))
            put("title", title)
            put("text", text)
            put("at", sbn.postTime)
        })
        // Never more than the last 200 waiting.
        while (queue.length() > 200) queue.remove(0)
        prefs.edit().putString(KEY_QUEUE, queue.toString()).apply()
    }

    companion object {
        const val PREFS = "budgetseal_alerts"
        const val KEY_SEEN = "seen_apps"
        const val KEY_APPS = "apps"
        const val KEY_QUEUE = "queue"
    }
}
