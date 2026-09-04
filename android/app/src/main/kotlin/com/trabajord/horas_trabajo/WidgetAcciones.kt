package com.trabajord.horas_trabajo

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import es.antonborri.home_widget.HomeWidgetLaunchIntent

/** Utilidades compartidas por los 3 proveedores de widgets. */
object WidgetAcciones {

  /** Acción de marcado hacia MarcadorWidgetActionReceiver (callback Dart
   *  headless): URI `horastrabajo://marcarAlternar` para el botón único. */
  fun marcarPendingIntent(context: Context, uri: String): PendingIntent {
    val intent = Intent(context, MarcadorWidgetActionReceiver::class.java).apply {
      data = Uri.parse(uri)
    }
    var flags = PendingIntent.FLAG_UPDATE_CURRENT
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
      flags = flags or PendingIntent.FLAG_IMMUTABLE
    }
    return PendingIntent.getBroadcast(context, uri.hashCode(), intent, flags)
  }

  /** Abre la app al tocar el widget. */
  fun abrirAppPendingIntent(context: Context): PendingIntent =
    HomeWidgetLaunchIntent.getActivity(context, MainActivity::class.java)

  /** `true` si hay una jornada en curso (clave `en_curso` == "1"). */
  fun hayJornadaActiva(data: android.content.SharedPreferences): Boolean =
    data.getString("en_curso", "0") == "1"

  private fun estadoDe(data: android.content.SharedPreferences): String {
    val inicio = data.getString("inicio_millis", "")?.toLongOrNull()
    if (inicio != null) {
      return "En curso desde ${horaCorta(inicio)}"
    }
    return data.getString("estado", null) ?: "Fuera de la jornada"
  }

  fun horaCorta(millis: Long): String {
    val df = java.text.SimpleDateFormat("h:mm a", java.util.Locale.getDefault())
    return df.format(java.util.Date(millis))
  }

  fun textoEstadoMarcador(data: android.content.SharedPreferences): String =
    estadoDe(data)
}