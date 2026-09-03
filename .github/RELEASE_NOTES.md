# Horas Trabajo RD — Beta v0.4.2

## Corrección de estabilidad (vigilancia)
- **La app ya no se cierra al activar "Vigilar llegada y salida".**

### Qué cambió
- **Bloqueo de notificaciones**: en Android 13+ el servicio en segundo plano
  necesita publicar una notificación persistente. Si las notificaciones están
  denegadas, la app **ya no arranca el servicio y no se cierra**: te lo avisa y
  te pide activarlas (Ajustes → Notificaciones). Esto evita el *crash nativo*
  (`SecurityException`) que cerraba la app.
- **`activarMonitor` nunca lanza**: cualquier fallo devuelve un estado de
  "no se pudo activar" y la app sigue abierta con un mensaje claro.
- **Aislado de la geocerca blindado**: todo su arranque y su ciclo van en
  `try/catch`, de modo que un error puntual (sin GPS, fallo de base de datos,
  de zona horaria) **no tira** el servicio ni la aplicación.
- Se pide el permiso **POST_NOTIFICATIONS** antes de iniciar el servicio.

### Para que la vigilancia funcione
1. Permite las **notificaciones** de la app (Ajustes del sistema).
2. Ubicación: **"Permitir todo el tiempo"**.
3. GPS activado.

## Sigue incluido
- v0.4.1: fix de cierre al activar (endurecimiento Dart).
- v0.4.0: UI alineada a la marca (azul #1565C0, nuevo ícono, logo en Inicio).
- Marcado entrada/salida con GPS, geocerca, motor de cálculo RD, reportes, 100% local.