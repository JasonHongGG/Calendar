package com.calendar.app.calendar_app

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.graphics.BitmapFactory
import android.widget.RemoteViews
import java.time.YearMonth
import java.time.format.DateTimeFormatter
import java.util.Locale
import es.antonborri.home_widget.HomeWidgetProvider

class CalendarMonthWidgetProvider : HomeWidgetProvider() {
    companion object {
        private const val PREFS_NAME = "HomeWidgetPreferences"
        private const val PREF_MONTH_KEY = "widget_month_key"
        private const val PREF_IMAGE_PREFIX = "month_image_path_"
        private const val PREF_FALLBACK_IMAGE = "month_image_path"
        private const val ACTION_PREV_MONTH = "com.calendar.app.calendar_app.ACTION_PREV_MONTH"
        private const val ACTION_NEXT_MONTH = "com.calendar.app.calendar_app.ACTION_NEXT_MONTH"
        private val MONTH_LABEL_FORMATTER = DateTimeFormatter.ofPattern("yyyy/MM", Locale.getDefault())
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        val monthKey = widgetData.getString(PREF_MONTH_KEY, null) ?: currentMonthKey()
        val imagePath = widgetData.getString("$PREF_IMAGE_PREFIX$monthKey", null)
            ?: widgetData.getString(PREF_FALLBACK_IMAGE, null)
        val monthLabel = formatMonthLabel(monthKey)

        for (widgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.calendar_month_widget)

            if (imagePath != null) {
                val bitmap = BitmapFactory.decodeFile(imagePath)
                if (bitmap != null) {
                    views.setImageViewBitmap(R.id.widget_image, bitmap)
                }
            }

            views.setTextViewText(R.id.widget_month_label, monthLabel)

            val prevIntent = Intent(context, CalendarMonthWidgetProvider::class.java).apply {
                action = ACTION_PREV_MONTH
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
            }
            val nextIntent = Intent(context, CalendarMonthWidgetProvider::class.java).apply {
                action = ACTION_NEXT_MONTH
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, widgetId)
            }
            val prevPending = PendingIntent.getBroadcast(
                context,
                widgetId,
                prevIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            val nextPending = PendingIntent.getBroadcast(
                context,
                widgetId + 10000,
                nextIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_prev, prevPending)
            views.setOnClickPendingIntent(R.id.widget_next, nextPending)

            val intent = Intent(context, MainActivity::class.java)
            val pendingIntent = PendingIntent.getActivity(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_root, pendingIntent)

            appWidgetManager.updateAppWidget(widgetId, views)
        }
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        if (intent.action != ACTION_PREV_MONTH && intent.action != ACTION_NEXT_MONTH) return

        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val currentKey = prefs.getString(PREF_MONTH_KEY, null) ?: currentMonthKey()
        val currentMonth = parseMonthKey(currentKey)
        val targetMonth = if (intent.action == ACTION_PREV_MONTH) {
            currentMonth.minusMonths(1)
        } else {
            currentMonth.plusMonths(1)
        }
        val targetKey = formatMonthKey(targetMonth)
        val hasImage = prefs.getString("$PREF_IMAGE_PREFIX$targetKey", null) != null
        if (hasImage) {
            prefs.edit().putString(PREF_MONTH_KEY, targetKey).apply()
        }

        val manager = AppWidgetManager.getInstance(context)
        val component = ComponentName(context, CalendarMonthWidgetProvider::class.java)
        val ids = manager.getAppWidgetIds(component)
        onUpdate(context, manager, ids, prefs)
    }

    private fun currentMonthKey(): String = formatMonthKey(YearMonth.now())

    private fun formatMonthKey(month: YearMonth): String = month.toString()

    private fun parseMonthKey(key: String): YearMonth {
        return try {
            YearMonth.parse(key)
        } catch (_: Exception) {
            YearMonth.now()
        }
    }

    private fun formatMonthLabel(key: String): String {
        val month = parseMonthKey(key)
        return month.format(MONTH_LABEL_FORMATTER)
    }
}
