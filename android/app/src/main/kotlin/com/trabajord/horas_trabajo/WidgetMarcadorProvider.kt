package com.trabajord.horas_trabajo

import android.appwidget.AppWidgetManager
import android.content.Context
import android.content.SharedPreferences
import android.graphics.Color
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetProvider

/**
 * Widget MARCAR: un único botón grande que alterna entrada/salida según el
 * estado en curso (Material 3: píldora blanca "Marcar entrada" o roja
 * "Marcar salida"). Al tocarlo dispara MarcadorWidgetActionReceiver, cuyo
 * callback Dart headless hace el marcado sin abrir la app.
 */
class WidgetMarcadorProvider : HomeWidgetProvider() {

  override fun onUpdate(
      context: Context,
      appWidgetManager: AppWidgetManager,
      appWidgetIds: IntArray,
      widgetData: SharedPreferences,
  ) {
    val enCurso = WidgetAcciones.hayJornadaActiva(widgetData)
    val estado = WidgetAcciones.textoEstadoMarcador(widgetData)

    appWidgetIds.forEach { widgetId ->
      val views = RemoteViews(context.packageName, R.layout.home_widget_marcador)

      views.setTextViewText(R.id.marcador_estado, estado)

      if (enCurso) {
        views.setTextViewText(R.id.widget_boton_marcar, "■  MARCAR SALIDA")
        views.setTextColor(R.id.widget_boton_marcar, Color.WHITE)
        views.setInt(
            R.id.widget_boton_marcar,
            "setBackgroundResource",
            R.drawable.widget_btn_marcar_salida,
        )
      } else {
        views.setTextViewText(R.id.widget_boton_marcar, "▶  MARCAR ENTRADA")
        views.setTextColor(R.id.widget_boton_marcar, Color.rgb(0x15, 0x65, 0xC0))
        views.setInt(
            R.id.widget_boton_marcar,
            "setBackgroundResource",
            R.drawable.widget_btn_marcar_entrada,
        )
      }

      // Un solo botón: el callback Dart decide entrada o salida según la
      // jornada en curso (acción "marcarAlternar").
      views.setOnClickPendingIntent(
          R.id.widget_boton_marcar,
          WidgetAcciones.marcarPendingIntent(
              context,
              "horastrabajo://marcarAlternar",
          ),
      )
      views.setOnClickPendingIntent(
          R.id.marcador_container,
          WidgetAcciones.abrirAppPendingIntent(context),
      )

      appWidgetManager.updateAppWidget(widgetId, views)
    }
  }
}