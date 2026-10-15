package com.lumioapps.stamply

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/// Home-screen widget: the user's passport and how far it travels.
/// The texts come from the app (already translated) and are kept in
/// SharedPreferences, so the widget works with the app closed.
class PassportWidget : AppWidgetProvider() {
    override fun onUpdate(context: Context, manager: AppWidgetManager, ids: IntArray) {
        for (id in ids) manager.updateAppWidget(id, build(context))
    }

    companion object {
        private const val PREFS = "stamply_widget"

        fun save(context: Context, title: String, line1: String, line2: String) {
            context.getSharedPreferences(PREFS, Context.MODE_PRIVATE).edit()
                .putString("title", title)
                .putString("line1", line1)
                .putString("line2", line2)
                .apply()
            refresh(context)
        }

        fun refresh(context: Context) {
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(ComponentName(context, PassportWidget::class.java))
            for (id in ids) manager.updateAppWidget(id, build(context))
        }

        private fun build(context: Context): RemoteViews {
            val prefs = context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
            val views = RemoteViews(context.packageName, R.layout.widget_passport)
            views.setTextViewText(R.id.widget_title, prefs.getString("title", "Stamply"))
            views.setTextViewText(R.id.widget_line1, prefs.getString("line1", ""))
            views.setTextViewText(R.id.widget_line2, prefs.getString("line2", ""))
            val open = PendingIntent.getActivity(
                context, 0, Intent(context, MainActivity::class.java),
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, open)
            return views
        }
    }
}
