package com.trabajord.horas_trabajo

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.FlutterInjector
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import io.flutter.view.FlutterCallbackInformation

/**
 * Receptor propio para los botones del widget de pantalla de inicio.
 *
 * El mecanismo por defecto del paquete home_widget (HomeWidgetBackgroundReceiver
 * + WorkManager) resultó poco confiable en pruebas reales: con la app en
 * segundo plano, el proceso se recicla antes de que el FlutterEngine headless
 * termine de inicializarse y ejecute el callback Dart, así que el toque del
 * botón no llegaba a tener efecto.
 *
 * Esta versión usa goAsync() para mantener vivo el receiver mientras el
 * engine headless arranca y corre el callback ya registrado con
 * HomeWidget.registerInteractivityCallback (reutiliza el mismo handle
 * guardado por el paquete en InternalHomeWidgetPreferences), igual de
 * explícito que el isolate de background_service.dart.
 */
class MarcadorWidgetActionReceiver : BroadcastReceiver() {

  companion object {
    private const val TAG = "MarcadorWidget"
    private const val PREFS = "InternalHomeWidgetPreferences"
    private const val KEY_DISPATCHER = "callbackDispatcherHandle"
    private const val KEY_CALLBACK = "callbackHandle"
    private const val CHANNEL_NAME = "home_widget/background"
    private const val ENGINE_KEEPALIVE_MS = 4000L
  }

  override fun onReceive(context: Context, intent: Intent) {
    val prefs: SharedPreferences =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
    val dispatcherHandle = prefs.getLong(KEY_DISPATCHER, 0)
    val callbackHandle = prefs.getLong(KEY_CALLBACK, 0)
    if (dispatcherHandle == 0L || callbackHandle == 0L) return

    val pendingResult = goAsync()
    val appContext = context.applicationContext
    val uriString = intent.data?.toString() ?: ""
    val mainHandler = Handler(Looper.getMainLooper())

    mainHandler.post {
      try {
        val flutterLoader = FlutterInjector.instance().flutterLoader()
        flutterLoader.startInitialization(appContext)
        flutterLoader.ensureInitializationComplete(appContext, null)

        val callbackInfo = FlutterCallbackInformation.lookupCallbackInformation(dispatcherHandle)
        if (callbackInfo == null) {
          pendingResult.finish()
          return@post
        }

        val engine = FlutterEngine(appContext)
        val dartCallback =
            DartExecutor.DartCallback(
                appContext.assets,
                flutterLoader.findAppBundlePath(),
                callbackInfo,
            )
        engine.dartExecutor.executeDartCallback(dartCallback)

        lateinit var channel: MethodChannel
        channel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        channel.setMethodCallHandler { call, result ->
          if (call.method == "HomeWidget.backgroundInitialized") {
            channel.invokeMethod("", listOf(callbackHandle, uriString))
            result.success(null)
            // Deja el engine vivo un momento para que termine el trabajo
            // async (DB + refresco del widget) antes de liberarlo.
            mainHandler.postDelayed({
              engine.destroy()
              pendingResult.finish()
            }, ENGINE_KEEPALIVE_MS)
          } else {
            result.notImplemented()
          }
        }
      } catch (e: Exception) {
        Log.e(TAG, "Fallo al ejecutar el callback headless del widget", e)
        pendingResult.finish()
      }
    }
  }
}
