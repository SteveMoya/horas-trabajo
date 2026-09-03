package com.trabajord.horas_trabajo

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Widget de pantalla de inicio: permite marcar entrada/salida sin abrir
 * la app. Los botones disparan MarcadorWidgetActionReceiver, que ejecuta
 * el callback Dart headless registrado desde
 * lib/services/home_widget_service.dart.
 */
class MarcadorWidgetProvider : HomeWidgetProvider() {

  private fun accionPendingIntent(context: Context, uri: String): PendingIntent {
    val intent = Intent(context, MarcadorWidgetActionReceiver::class.java).apply {
      data = Uri.parse(uri)
    }
    var flags = PendingIntent.FLAG_UPDATE_CURRENT
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      flags = flags or PendingIntent.FLAG_IMMUTABLE
    }
    return PendingIntent.getBroadcast(context, uri.hashCode(), intent, flags)
  }

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    appWidgetIds.forEach { widgetId ->
      val views =
          RemoteViews(context.packageName, R.layout.home_widget_layout).apply {
            setTextViewText(
                R.id.widget_estado,
                widgetData.getString("estado", null) ?: "Horas Trabajo",
            )

            setOnClickPendingIntent(
                R.id.widget_boton_entrada,
                accionPendingIntent(context, "horastrabajo://marcarEntrada"),
            )
            setOnClickPendingIntent(
                R.id.widget_boton_salida,
                accionPendingIntent(context, "horastrabajo://marcarSalida"),
            )
            setOnClickPendingIntent(
                R.id.widget_container,
                HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
            )
          }

      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }
}
