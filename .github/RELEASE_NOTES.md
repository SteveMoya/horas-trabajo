# Horas Trabajo RD — Beta v0.4.1

## Corrección importante
- **La app ya no se cierra al activar "Vigilar llegada y salida".**

### Causa
Al arrancar el servicio en segundo plano (foreground service de geocerca) podía
lanzar una excepción de plataforma que no se capturaba (p. ej. Android 13+
exige el permiso de notificaciones para publicar el aviso persistente del
servicio). Esa excepción salía del toggle y cerraba la app.

### Qué cambió
- `activarMonitor` ahora **nunca lanza**: cualquier fallo devuelve un estado de
  "no se pudo activar" y la app sigue abierta con un aviso.
- Antes de iniciar el servicio se pide el **permiso de notificaciones**
  (`POST_NOTIFICATIONS`), necesario para el aviso en segundo plano.
- El aislado de la geocerca envuelve todo su ciclo en `try/catch`, de modo que
  un error puntual (sin GPS, fallo de BD) **no tumba** el servicio ni la app.
- Mensajes claros en el interruptor si no se puede activar (permite notificaciones,
  activa GPS, ajustes de ubicación).

## Sigue incluido
- v0.4.0: UI alineada a la marca (azul #1565C0, nuevo ícono, logo en Inicio).
- v0.3.0: fix de la ventana "Marcar" vacía.
- Marcado entrada/salida con GPS, lugar de trabajo/geocerca, notificaciones con
  "Marcar ahora", motor de cálculo RD, reportes y tema Material 3 — 100% local.