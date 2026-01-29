package com.trustguard.trustguard

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

class BalanceWidgetProvider : HomeWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
        widgetData: SharedPreferences
    ) {
        for (appWidgetId in appWidgetIds) {
            val views = RemoteViews(context.packageName, R.layout.balance_widget).apply {
                // Get data from SharedPreferences
                // These keys should match the ones used in Flutter
                val netBalance = widgetData.getString("widget_net_balance", "$0.00")
                val owed = widgetData.getString("widget_owed", "Owed: $0.00")
                val owing = widgetData.getString("widget_owing", "Owing: $0.00")

                setTextViewText(R.id.widget_net_balance, netBalance)
                setTextViewText(R.id.widget_owed, owed)
                setTextViewText(R.id.widget_owing, owing)
            }

            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
