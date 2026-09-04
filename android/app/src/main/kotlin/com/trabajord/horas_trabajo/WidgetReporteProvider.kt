package com.trabajord.horas_trabajo

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Widget REPORTE: resumen rápido de horas de hoy y de la semana en chips
 * Material 3, más el estado de la jornada. Es de solo lectura — tocar el
 * widget abre la app.
 */
class WidgetReporteProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    appWidgetIds.forEach { widgetId ->
      val views = RemoteViews(context.packageName, R.layout.home_widget_reporte)

      views.setTextViewText(
          R.id.reporte_hoy_valor,
          widgetData.getString("hoy_horas", null) ?: "0.00 h",
      )
      views.setTextViewText(
          R.id.reporte_semana_valor,
          widgetData.getString("semana_horas", null) ?: "0.00 h",
      )
      views.setTextViewText(
          R.id.reporte_estado,
          WidgetAcciones.textoEstadoMarcador(widgetData),
      )

      views.setOnClickPendingIntent(
          R.id.reporte_container,
          WidgetAcciones.abrirAppPendingIntent(context),
      )

      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }
}