# Horas Trabajo (RD)

App móvil **100% local** para registrar horas trabajadas y calcular el pago
aplicando las reglas del **Código de Trabajo de República Dominicana (Ley 16-92)**.

> Flutter · Material 3 · SQLite local · GPS · sin backend.

## ✨ Funcionalidades

- **Marcado de entrada/salida** con registro de ubicación (GPS opcional) y hora actual.
- **Sesión en curso** con reloj en vivo.
- **Lugar de trabajo (geocerca):** al marcar tu primera entrada se pide permiso de GPS
  y puedes guardar la ubicación como tu lugar de trabajo.
- **Vigilancia de llegada/salida:** al activar el toggle, la app detecta cuando entras
  o sales del área del trabajo y te envía una notificación **"¿Marcar la entrada/salida?"**
  (con acción rápida "Marcar ahora").
- **Historial** de jornadas, con nota y marcas de *día feriado* / *descanso semanal*.
- **Cálculo salarial RD**: desglose por concepto (ordinarias, extras, exceso,
  nocturnas, feriadas).
- **Reportes** semanales y mensuales con total de horas e importe a pagar.
- **Almacenamiento 100% local** (SQLite + preferencias) — sin cuentas ni nube.
- **Material 3** pulido, con **modo claro/oscuro/sistema** y **color primario
  personalizable**.

## 📐 Motor laboral (Código de Trabajo RD)

| Concepto | Valor por defecto |
|---|---|
| Jornada ordinaria | 8 h/día · 44 h/semana |
| Hora extra (hasta 68 h/sem) | +35% |
| Exceso (>68 h/semana) | +100% |
| Jornada nocturna (9pm–7am) | +15% |
| Feriado / descanso semanal | +100% |
| Valor hora ordinaria | salario mensual ÷ 23.83 ÷ 8 |

> Todos los porcentajes y límites son **editables en Ajustes**. El resultado es
> una **guía** y no constituye asesoría legal.

## 🧱 Stack

- **Flutter** (Dart 3) + Material 3 (`ColorScheme.fromSeed`)
- **sqflite** (SQLite local) · **shared_preferences** (ajustes)
- **provider** (estado) · **geolocator** + **permission_handler** (GPS)
- **intl** (fechas/horas/moneda es-DO, RD$) · **google_fonts**

## 🚀 Cómo ejecutar

```bash
# Asegúrate de tener Flutter estable instalado
flutter pub get
flutter run            # en un emulador/dispositivo
# o build APK
flutter build apk --release
```

## 📦 Releases / Beta

Los APK firmados se generan automáticamente con **GitHub Actions** (workflow en
`.github/workflows/build-apk.yml`) al publicar la etiqueta `v*`, y se adjuntan
como **GitHub Release** en la sección *Releases* de este repositorio.

Para construir una **Beta**: ejecuta el workflow manualmente (Dispatch) o crea
la etiqueta `v0.x` → CI firma con el keystore (guardado en secrets) y sube el
`.apk`.

## 🛠️ Configuración de firma (CI)

Secrets requeridos en el repo (Settings → Secrets and variables → Actions):

| Secret | Descripción |
|---|---|
| `KEYSTORE_BASE64` | Keystore `.jks` en base64 |
| `KEYSTORE_PASSWORD` | Contraseña del keystore |
| `KEYSTORE_ALIAS` | Alias de la clave |
| `KEYSTORE_ALIAS_PASSWORD` | Contraseña del alias |

## 📄 Licencia

MIT.