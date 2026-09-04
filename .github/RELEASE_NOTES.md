# Horas Trabajo RD — Beta v0.8.1

## Corrección: la descarga de actualizaciones fallaba 🛠️

- **Bug arreglado**: al actualizar, la descarga del APK podía fallar con
  `FileSystemException: An async operation is currently pending` y nunca
  completarse. La escritura del archivo no esperaba a que cada bloque
  terminara de guardarse antes de recibir el siguiente — ahora la
  descarga se completa de forma confiable.

## v0.8.0 — Ilustraciones, animaciones y onboarding rediseñado 🎨

- **Sistema de ilustraciones propio**: 10 ilustraciones SVG (café, libros,
  escritorio, gráficos, personas en estilo minimalista) que se adaptan
  automáticamente a cualquier color de tema elegido — coherentes en toda la
  app, en vez de íconos sueltos.
- **Estados ilustrados**: Historial, Calendario y Reporte ahora muestran una
  ilustración animada (en vez de un ícono genérico) cuando no hay nada que
  mostrar todavía.
- **Onboarding completamente rediseñado** (9 pantallas): bienvenida,
  funciones principales explicadas paso a paso (Marca → Calcula → Organiza),
  características destacadas, y una nueva pantalla **"Apoya este
  proyecto"** — el botón de donación queda marcado como "Próximamente"
  hasta conectar un método de pago real, sin fingir un cobro.
- Las ilustraciones tienen una animación de entrada suave y respetan
  "Quitar animaciones" del sistema en Accesibilidad.

## v0.7.4 — Instalación sin re-descargar y con resultado visible ✅

- Al actualizar, la app **instala el archivo que ya bajó**: si cancelas o
  concedes el permiso y vuelves a pulsar actualizar, no vuelve a descargar los
  60 MB (reutiliza el APK en caché).
- Ahora la app te **muestra el resultado de la instalación**: si la actualización
  se instaló ("✅ instalada") o si la cancelaste ("Instalación cancelada"),
  dentro del propio diálogo, con opción de reintentar.

## v0.7.3 — Instalación de la actualización corregida 🛠️

- La descarga terminaba pero la **instalación podía no arrancar** sin avisar.
  Ahora:
  - Se detecta el permiso de **"Instalar apps desconocidas"** de Android. Si no
    está concedido, se explica y se ofrece un botón **"Permitir instalación"**
    que abre directamente los ajustes.
  - Se instaló un instalador nativo propio (FileProvider + PackageInstaller),
    más fiable que el genérico.
  - Los errores de instalación ya **se muestran** en el diálogo (antes quedaban
    ocultos y parecía que "no pasaba nada").

## Inicio sin hora duplicada

- Se quita la **hora actual** de la tarjeta principal: los datos de tiempo ya
  viven en el **cronómetro circular**, y la pantalla queda más limpia.

## v0.7.2 — Aviso de actualización más fiable 🚀

- La app ahora **revisa si hay versión nueva también cada vez que vuelves a
  primer plano** (minimizarla y reabrirla), no solo al arrancar desde cero.
  Antes, si dejabas la app abierta, no detectaba un release recién publicado
  hasta cerrarla del todo.
- Se revisa la API una vez cada 3 minutos como máximo para no gastar datos.

## v0.7.1 — Gráfico "Horas por día" (Reporte) más claro

- El eje Y ahora **se entiende**: paso en horas enteras y redondas (0, 4, 8, 12…)
  en vez de decimales arbitrarios, con **líneas guía horizontales** para leer la
  altura de cada barra contra la escala.
- Se indica la **unidad ("Horas")** en el eje izquierdo.
- El techo del gráfico se redondea al múltiplo del paso (sin números feos).

## Inicio menos redundante

- Quité la píldora de duración que se repetía encima del botón de marcar: los
  datos de horas ya viven en el **cronómetro circular**, así la pantalla queda
  más limpia y sin información duplicada.

## v0.7.0 — Cronómetro circular de jornada (Inicio) + Actualizaciones automáticas 🚀

- Al marcar la **entrada**, la tarjeta principal muestra un **cronómetro
  circular** que se llena segundo a segundo y **cambia de color según la
  fase** de tu jornada:
  - 🔵 **Azul (marca)** mientras completas la jornada ordinaria (8 h,
    configurable).
  - 🟠 **Naranja** al superar las 8 h: el anillo sigue girando acumulando
    **horas extra**.
  - 🟣 **Violeta** al entrar en la **tanda nocturna** (9pm–7am).
- Animaciones pulidas: relleno con transición suave, brillo/glow en el arco,
  punto luminoso que avanza con el tiempo y cambio de color de fase animado.
- El centro muestra el tiempo `HH:MM:SS` en vivo y un subtítulo contextual
  ("Te faltan X de la jornada" / "Has ganado X en extra" / "Franja nocturna
  activa").

## Actualizaciones automáticas desde GitHub 🚀

- Al abrir la app se **revisa si hay una versión nueva** en GitHub.
- Si existe, llega una **notificación** con la versión disponible; al tocarla
  se abre el diálogo de actualización.
- El diálogo muestra las **novedades** de la versión y permite **descargar el
  APK e instalarlo** directamente desde la app (con barra de progreso).
- Se avisa una sola vez por versión para no molestar en cada arranque.

## v0.6.2 — Corrección: no se podía guardar el lugar de trabajo

- **Bug arreglado**: guardar el lugar de trabajo solo era posible como
  efecto colateral de marcar la primera entrada con GPS activo. Si
  declinabas ese diálogo, el GPS fallaba, o tenías activo el modo sin
  GPS, no quedaba ninguna forma de configurarlo — y sin lugar de
  trabajo guardado, la vigilancia de llegada y salida no se podía
  activar. Ahora la fila "Sin lugar de trabajo" (tarjeta Trabajo, en
  Inicio) guarda tu ubicación actual al tocarla.

## v0.6.1 — Consistencia visual y feedback táctil

- **Formas Pixel en toda la app**: las esquinas continuas ("squircle",
  la seña visual de Material You / Pixel) que ya tenían las tarjetas y
  botones ahora se extienden a diálogos, el botón flotante, los chips
  y la tarjeta de opción del onboarding — antes caían al shape circular
  por defecto de Material, rompiendo la consistencia.
- **Feedback háptico**: la app ahora vibra al presionar los botones
  principales, al avanzar/retroceder en el onboarding, al elegir una
  opción, y al completar la bienvenida inicial — hasta ahora no había
  ningún haptic en toda la app.

## v0.6.0 — Bienvenida y experiencia pulida

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
