package com.trabajord.horas_trabajo

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.os.SystemClock
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetLaunchIntent
import es.antonborri.home_widget.HomeWidgetPlugin
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Widget de pantalla de inicio: permite marcar entrada/salida sin abrir
 * la app. Los botones disparan MarcadorWidgetActionReceiver, que ejecuta
 * el callback Dart headless registrado desde
 * lib/services/home_widget_service.dart.
 *
 * Cambia de forma según el tamaño que el usuario le dé en su pantalla de
 * inicio: chico (solo marcar), mediano (suma un cronómetro nativo cuando
 * hay una jornada en curso) y grande (suma un reporte rápido de horas de
 * hoy y de la semana). El cronómetro usa el Chronometer nativo de
 * Android: tiquea solo una vez configurado, sin depender de que la app
 * refresque el widget cada segundo.
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

  /**
   * Elige el layout según el tamaño mínimo actual del widget (en dp). Los
   * umbrales siguen la fórmula estándar de Android para el ancho de N
   * celdas de un launcher (`70×N − 30`): ~110dp ≈ 2 celdas, ~180dp ≈ 3
   * filas, ~250dp ≈ 4 celdas.
   */
  private fun elegirLayout(opciones: Bundle): Int {
    val minWidthDp = opciones.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, 180)
    val minHeightDp = opciones.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT, 90)
    return when {
      minHeightDp >= 180 && minWidthDp >= 250 -> R.layout.home_widget_layout_large
      minHeightDp >= 140 -> R.layout.home_widget_layout_medium
      else -> R.layout.home_widget_layout
    }
  }

  private fun construirVista(
      context: Context,
      appWidgetManager: AppWidgetManager,
      widgetId: Int,
      widgetData: SharedPreferences,
  ): RemoteViews {
    val opciones = appWidgetManager.getAppWidgetOptions(widgetId)
    val views = RemoteViews(context.packageName, elegirLayout(opciones))

    // Setear un id que no existe en el layout elegido (p. ej. el
    // cronómetro en el layout chico) no falla: RemoteViews lo ignora en
    // silencio, así que no hace falta ramificar por tamaño acá.
    val inicioMillis = widgetData.getString("inicio_millis", null)?.toLongOrNull()
    if (inicioMillis != null) {
      views.setViewVisibility(R.id.widget_cronometro, View.VISIBLE)
      views.setViewVisibility(R.id.widget_estado, View.GONE)
      // Chronometer usa SystemClock.elapsedRealtime() como referencia, no
      // la hora de reloj — hay que convertir el inicio (wall-clock) a esa
      // base para que muestre el tiempo transcurrido real.
      val base = SystemClock.elapsedRealtime() - (System.currentTimeMillis() - inicioMillis)
      views.setChronometer(R.id.widget_cronometro, base, "%s", true)
    } else {
      views.setViewVisibility(R.id.widget_cronometro, View.GONE)
      views.setViewVisibility(R.id.widget_estado, View.VISIBLE)
      views.setTextViewText(
          R.id.widget_estado,
          widgetData.getString("estado", null) ?: "Fuera de la jornada",
      )
    }

    views.setTextViewText(R.id.widget_hoy_valor, widgetData.getString("hoy_horas", null) ?: "0.00 h")
    views.setTextViewText(
        R.id.widget_semana_valor,
        widgetData.getString("semana_horas", null) ?: "0.00 h",
    )

    views.setOnClickPendingIntent(
        R.id.widget_boton_entrada,
        accionPendingIntent(context, "horastrabajo://marcarEntrada"),
    )
    views.setOnClickPendingIntent(
        R.id.widget_boton_salida,
        accionPendingIntent(context, "horastrabajo://marcarSalida"),
    )
    views.setOnClickPendingIntent(
        R.id.widget_container,
        HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java),
    )
    return views
  }

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    appWidgetIds.forEach { widgetId ->
      val views = construirVista(context, appWidgetManager, widgetId, widgetData)
      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }

  /** Se llama cuando el usuario redimensiona el widget en su pantalla de
   * inicio — sin esto, cambiar el tamaño no cambiaría de layout hasta el
   * próximo refresco por otra causa (marcar, o el ciclo de 30 min). */
  override fun onAppWidgetOptionsChanged(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetId: Int,
      newOptions: Bundle,
  ) {
    super.onAppWidgetOptionsChanged(context, appWidgetManager, appWidgetId, newOptions)
    val widgetData = HomeWidgetPlugin.getData(context)
    val views = construirVista(context, appWidgetManager, appWidgetId, widgetData)
    appWidgetManager.updateAppWidget(appWidgetId, views)
  }
}
