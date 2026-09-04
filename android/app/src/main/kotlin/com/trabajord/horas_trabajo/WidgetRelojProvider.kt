package com.trabajord.horas_trabajo

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Widget RELOJ: muestra un reloj en vivo (TextClock tiquea solo), la fecha y
 * el estado de la jornada. Es informativo — tocar el widget abre la app.
 * Se registra en el manifest como widget independiente (widget_reloj_info).
 */
class WidgetRelojProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    appWidgetIds.forEach { widgetId ->
      val views = RemoteViews(context.packageName, R.layout.home_widget_reloj)

      views.setTextViewText(
          R.id.reloj_estado,
          WidgetAcciones.textoEstadoMarcador(widgetData),
      )

      // La fecha se formatea en español desde Dart (garantiza es-419 y que se
      // mantenga fresca en cada refresco); si no hay dato, se calcula local.
      val fecha = widgetData.getString("fecha", null)
      if (fecha != null) {
        views.setTextViewText(R.id.reloj_fecha, fecha)
      }

      views.setOnClickPendingIntent(
          R.id.reloj_container,
          WidgetAcciones.abrirAppPendingIntent(context),
      )

      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }
}