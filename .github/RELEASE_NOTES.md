# Horas Trabajo RD — Beta v0.6.0

## Bienvenida y experiencia pulida

- **Onboarding inicial**: la primera vez que abres la app, un recorrido de
  bienvenida presenta las funciones principales y recoge tu nombre, salario
  mensual y preferencia de GPS — así el cálculo de nómina funciona desde tu
  primera jornada marcada. Se muestra una única vez.
- **Micro-animaciones** en toda la app: los botones dan feedback de escala al
  presionarlos, las tarjetas del Inicio y el Historial aparecen con un
  fundido escalonado, el ícono del micrófono pulsa mientras escucha, y el
  cambio entre pestañas y pantallas usa transiciones suaves (crossfade y
  "fade through") en vez de saltos secos.

## 7 features nuevas (v0.5.0)

### Marcado
- **Modo sin GPS**: toggle en Ajustes para marcar entrada/salida 100% manual,
  sin pedir permiso de ubicación (la vigilancia de geocerca queda desactivada
  al usarlo, ya que depende de la posición).
- **Ingreso en vivo**: tarjeta en la pantalla Marcar que muestra cuánto vas
  ganando en la jornada activa, actualizada cada segundo con el desglose por
  categoría (ordinaria/nocturna/extra/feriado).
- **Marcado por voz**: botón de micrófono que reconoce "marcar entrada" /
  "marcar salida" habladas (reconocimiento local del dispositivo).

### Datos
- **Copia de seguridad y exportación**: backup completo a `.json` (perfil,
  reglas, lugar de trabajo, historial) para restaurar ante reinstalación o
  cambio de móvil, exportación del historial a `.csv`, todo 100% local.
- **Reportes con gráficos**: barras de horas por día y dona de proporción por
  tipo de jornada en la pantalla Reporte, más exportación de nómina a PDF por
  semana o mes.

### Calendario y recordatorios
- **Feriados de RD**: calendario según la Ley 139-97 (fijos y trasladados al
  lunes), con aviso automático al marcar entrada en un día feriado.
- **Vacaciones y permisos**: registro manual con fecha de inicio/fin y tipo.
- **Recordatorios inteligentes**: notificaciones "¿olvidaste marcar?" según
  tu horario habitual, calculado del historial reciente.

### Android nativo
- **Widget de pantalla de inicio**: marca entrada/salida sin abrir la app.
- **Atajos del ícono**: long-press para marcar entrada/salida al instante.

## Para que la vigilancia funcione
1. Permite las **notificaciones** de la app (Ajustes del sistema).
2. Ubicación: **"Permitir todo el tiempo"**.
3. GPS activado.

## Sigue incluido
- v0.4.x: estabilidad de la vigilancia (no más cierres inesperados),
  identidad de marca (azul #1565C0, ícono, logo circular).
- Marcado entrada/salida con GPS, geocerca, motor de cálculo RD, 100% local.
