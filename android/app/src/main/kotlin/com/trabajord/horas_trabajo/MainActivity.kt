package com.trabajord.horas_trabajo

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    private val canal = "horas_trabajo/instalador"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, canal).setMethodCallHandler { call, result ->
            when (call.method) {
                "puedeInstalar" -> result.success(puedeInstalarAppsDesconocidas())
                "abrirAjustesInstalacion" -> {
                    abrirAjustesInstalacion()
                    result.success(null)
                }
                "instalar" -> {
                    val ruta = call.argument<String>("ruta")
                    if (ruta == null) {
                        result.error("SIN_RUTA", "La ruta del APK es nula", null)
                    } else {
                        val res = instalarApk(ruta)
                        when (res) {
                            "permiso" -> result.success("permiso")
                            "ok" -> result.success("ok")
                            else -> result.success("error:$res")
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    /// Android 8+ exige que la app tenga permitido instalar desde este origen
    /// ("Instalar apps desconocidas") para poder lanzar el PackageInstaller.
    private fun puedeInstalarAppsDesconocidas(): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return true
        return try {
            packageManager.canRequestPackageInstalls()
        } catch (e: Exception) {
            true
        }
    }

    private fun abrirAjustesInstalacion() {
        try {
            val intent = Intent(
                Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                Uri.parse("package:$packageName")
            )
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            startActivity(intent)
        } catch (_: Exception) {
            // En algunos launcher no hay activity para ese ajuste; caemos a
            // la lista general de apps de mi app.
            try {
                startActivity(
                    Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS,
                        Uri.parse("package:$packageName"))
                )
            } catch (_: Exception) {
                // sin ajustes accesibles
            }
        }
    }

    private fun instalarApk(ruta: String): String {
        if (!puedeInstalarAppsDesconocidas()) return "permiso"

        val archivo = File(ruta)
        if (!archivo.exists()) return "noExiste"

        return try {
            val uri = FileProvider.getUriForFile(
                this,
                "$packageName.fileprovider",
                archivo
            )
            val intent = Intent(Intent.ACTION_VIEW)
            intent.setDataAndType(uri, "application/vnd.android.package-archive")
            intent.addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK
            )
            startActivity(intent)
            "ok"
        } catch (e: Exception) {
            "lanzamientoError:${e.message ?: e.javaClass.simpleName}"
        }
    }
}