# Horas Trabajo RD — Beta v0.2.0

## Novedades en esta versión
- **Marcado de entrada/salida** con hora actual y ubicación (GPS).
- **Lugar de trabajo (geocerca):** en tu primera entrada se pide permiso de GPS
  y puedes guardar la ubicación como tu lugar de trabajo.
- **Vigilancia de llegada/salida** con notificaciones:
  - Al **llegar** al área del trabajo → "¿Marcar la entrada?"
  - Al **salir** del área → "¿Marcar la salida?"
  - Acción rápida **"Marcar ahora"** desde la propia notificación.
- Motor de cálculo RD (ordinarias, extras +35%, exceso +100%, nocturnas +15%,
  feriado/descanso +100%) — porcentajes editables en Ajustes.
- Reportes semanales y mensuales.
- Almacenamiento 100% local (SQLite).
- Tema Material 3 (claro/oscuro/sistema + color primario).

> ⚠️ La vigilancia de geocerca funciona en segundo plano con un *foreground
> service*; el intervalo de revisión es de 30 s y consume batería. Prueba el
> comportamiento en tu dispositivo (Android versiones variables).