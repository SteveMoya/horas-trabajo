# Horas Trabajo RD — Beta v0.3.0

## Corrección importante
- **Arreglada la ventana "Marcar" en blanco/vacía.**

### Causa
La app no inicializaba la localización de las fechas en español. `intl` solo
trae `en_US` por defecto, así que los formatos `DateFormat(..., 'es')` lanzaban
una excepción (`LocaleDataException`) en el primer frame y la vista no dibujaba
nada.

### Qué cambió
- `main()` ahora inicializa `initializeDateFormatting('es')` antes de arrancar.
- El arranque ya **no se bloquea** con la inicialización de notificaciones /
  vigilancia: esos servicios se configuran al final y en segundo plano, de modo
  que la interfaz **siempre se dibuja**, aunque un servicio falle.

## Sigue incluido (v0.2.0 + v0.1.0)
- Marcado de entrada/salida con hora y ubicación (GPS).
- Lugar de trabajo (geocerca) y vigilancia de llegada/salida con notificaciones
  y acción "Marcar ahora".
- Motor de cálculo RD y reportes. Tema Material 3. 100% local.