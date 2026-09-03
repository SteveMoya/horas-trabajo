# Horas Trabajo RD — Beta v0.4.3

## Corrección de estabilidad (vigilancia)
- **La app ya no se cierra al activar "Vigilar llegada y salida"** (root cause distinto
  al de v0.4.1/v0.4.2, reproducido y verificado en emulador Android).

### Qué cambió
- **Canal de notificaciones creado antes de arrancar el servicio**: el foreground
  service (`flutter_background_service`) publica su notificación persistente en el
  canal `geofence`, pero solo lo crea automáticamente si la app no le indica un
  canal propio. Como este canal se pasaba explícito y nunca se creaba con
  antelación (solo de forma perezosa al mostrar el primer aviso de llegada/salida,
  es decir, después de activar la vigilancia), Android rechazaba la notificación al
  iniciar el servicio con `CannotPostForegroundServiceNotificationException` y
  mataba la app.
- Se agrega `NotificationsService.crearCanalGeofence()`, llamado al iniciar la app
  y también justo antes de `activarMonitor()` arrancar el servicio, para que el
  canal exista siempre a tiempo.

### Para que la vigilancia funcione
1. Permite las **notificaciones** de la app (Ajustes del sistema).
2. Ubicación: **"Permitir todo el tiempo"**.
3. GPS activado.

## Sigue incluido
- v0.4.2: bloqueo de notificaciones + `activarMonitor` a prueba de excepciones.
- v0.4.1: fix de cierre al activar (endurecimiento Dart).
- v0.4.0: UI alineada a la marca (azul #1565C0, nuevo ícono, logo en Inicio).
- Marcado entrada/salida con GPS, geocerca, motor de cálculo RD, reportes, 100% local.
