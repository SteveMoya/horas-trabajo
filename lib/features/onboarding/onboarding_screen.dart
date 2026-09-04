import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:horas_trabajo/core/illustrations/app_illustrations.dart';
import 'package:horas_trabajo/core/navigation/fade_through_route.dart';
import 'package:horas_trabajo/core/theme/app_motion.dart';
import 'package:horas_trabajo/core/theme/app_spacing.dart';
import 'package:horas_trabajo/core/theme/pixel_shapes.dart';
import 'package:horas_trabajo/core/widgets/animated_illustration.dart';
import 'package:horas_trabajo/core/widgets/animated_tap_scale.dart';
import 'package:horas_trabajo/core/widgets/morphing_blob.dart';
import 'package:horas_trabajo/core/widgets/staggered_fade_in.dart';
import 'package:horas_trabajo/core/widgets/state_views.dart';
import 'package:horas_trabajo/data/models/employee_profile.dart';
import 'package:horas_trabajo/features/root/root_screen.dart';
import 'package:horas_trabajo/state/app_state.dart';
import 'package:provider/provider.dart';

/// Bienvenida inicial: se muestra una única vez, la primera vez que se abre
/// la app (ver [AppState.onboardingCompletado]). Introduce la app en 4
/// pasos breves (bienvenida, qué puedes hacer, características, apoyo),
/// y recoge lo mínimo indispensable — nombre, salario y preferencia de
/// GPS — para que el cálculo de nómina funcione desde la primera jornada.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _totalPaginas = 9;
  static const _indicePerfil = 5;
  static const _indiceUbicacion = 6;
  static const _indiceDonacion = 7;
  static const _indiceFinal = 8;

  final _controller = PageController();
  final _nombre = TextEditingController();
  final _salario = TextEditingController();
  int _pagina = 0;
  bool _usarUbicacion = true;
  bool _enviando = false;

  @override
  void initState() {
    super.initState();
    // El botón "Continuar" depende de _perfilValido (lee ambos controllers):
    // sin este listener, escribir en los campos no reconstruye la pantalla
    // y el botón se queda deshabilitado aunque el perfil ya sea válido.
    _nombre.addListener(_onCambioPerfil);
    _salario.addListener(_onCambioPerfil);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final perfil = context.read<AppState>().perfil;
    if (_nombre.text.isEmpty) _nombre.text = perfil.nombre;
    if (_salario.text.isEmpty && perfil.salarioMensual > 0) {
      _salario.text = perfil.salarioMensual.toStringAsFixed(2);
    }
  }

  void _onCambioPerfil() => setState(() {});

  @override
  void dispose() {
    _nombre.removeListener(_onCambioPerfil);
    _salario.removeListener(_onCambioPerfil);
    _controller.dispose();
    _nombre.dispose();
    _salario.dispose();
    super.dispose();
  }

  bool get _perfilValido {
    final salario = double.tryParse(_salario.text.replaceAll(',', '.'));
    return _nombre.text.trim().isNotEmpty && salario != null && salario > 0;
  }

  Future<void> _irA(int pagina) {
    HapticFeedback.selectionClick();
    // Todo el onboarding comparte un único Scaffold: sin esto, un SnackBar
    // mostrado en una página (p. ej. "Donar ahora" pendiente) queda
    // flotando encima del botón de la página siguiente.
    ScaffoldMessenger.maybeOf(context)?.clearSnackBars();
    return _controller.animateToPage(
      pagina,
      duration: AppMotion.page,
      curve: AppMotion.emphasized,
    );
  }

  void _siguiente() {
    if (_pagina == _indicePerfil && !_perfilValido) return;
    if (_pagina == _indiceFinal) {
      _finalizar();
      return;
    }
    _irA(_pagina + 1);
  }

  void _atras() => _irA(_pagina - 1);

  void _saltarIntro() => _irA(_indicePerfil);

  Future<void> _finalizar() async {
    if (_enviando) return;
    setState(() => _enviando = true);
    final app = context.read<AppState>();
    final salario = double.tryParse(_salario.text.replaceAll(',', '.')) ?? 0;
    if (_nombre.text.trim().isNotEmpty && salario > 0) {
      await app.guardarPerfil(EmployeeProfile(
        nombre: _nombre.text.trim(),
        salarioMensual: salario,
      ));
    }
    await app.guardarUsarUbicacion(_usarUbicacion);
    await app.completarOnboarding();
    if (!mounted) return;
    HapticFeedback.mediumImpact();
    Navigator.of(context).pushReplacement(
      FadeThroughRoute<void>(builder: (_) => const RootScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    // "Saltar" solo tiene sentido durante la introducción (bienvenida,
    // funciones, características): a partir del perfil, cada pantalla
    // pide algo puntual y ya no es contenido introductorio para saltear.
    final esIntro = _pagina < _indicePerfil;
    return PopScope(
      canPop: _pagina == 0,
      onPopInvokedWithResult: (did, _) {
        if (!did && _pagina > 0) _atras();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 16, 4),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Atrás',
                      onPressed: _pagina > 0 ? _atras : null,
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const Spacer(),
                    if (esIntro)
                      TextButton(
                        onPressed: _saltarIntro,
                        child: const Text('Saltar'),
                      ),
                  ],
                ),
              ),
              _PuntosProgreso(total: _totalPaginas, actual: _pagina),
              Expanded(
                child: PageView(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _pagina = i),
                  children: [
                    const _PaginaBienvenida(),
                    const _PaginaIntro(
                      illustration: AppIllustrationAsset.track,
                      paso: 'Paso 1 de 3 · Marca',
                      titulo: 'Marca con un solo toque',
                      subtitulo:
                          'Registra tu entrada y salida al instante. Con '
                          'GPS para verificar tu llegada, o en modo 100% '
                          'manual si prefieres no compartir tu ubicación.',
                    ),
                    const _PaginaIntro(
                      illustration: AppIllustrationAsset.calculate,
                      paso: 'Paso 2 de 3 · Calcula',
                      titulo: 'Tu pago, calculado al segundo',
                      subtitulo:
                          'Horas ordinarias, extras, nocturnas, feriados y '
                          'exceso semanal — todo desglosado en tiempo real, '
                          'según la Ley 16-92.',
                    ),
                    const _PaginaIntro(
                      illustration: AppIllustrationAsset.reports,
                      paso: 'Paso 3 de 3 · Organiza',
                      titulo: 'Reportes, feriados y respaldo',
                      subtitulo:
                          'Reportes semanales y mensuales con gráficos, '
                          'exportación a PDF, y control de feriados RD, '
                          'vacaciones y permisos.',
                    ),
                    const _PaginaCaracteristicas(),
                    _PaginaPerfil(nombre: _nombre, salario: _salario),
                    _PaginaUbicacion(
                      seleccionUsarGps: _usarUbicacion,
                      onCambiar: (v) => setState(() => _usarUbicacion = v),
                    ),
                    const _PaginaDonacion(),
                    const _PaginaFinal(),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: AnimatedTapScale(
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed:
                          (_pagina == _indicePerfil && !_perfilValido) ||
                                  _enviando
                              ? null
                              : _siguiente,
                      child: Text(_textoBoton),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _textoBoton {
    switch (_pagina) {
      case 0:
        return 'Comenzar';
      case _indicePerfil:
      case _indiceUbicacion:
        return 'Continuar';
      case _indiceDonacion:
        return 'Continuar sin donar';
      case _indiceFinal:
        return _enviando ? 'Preparando…' : 'Empezar a trabajar';
      default:
        return 'Siguiente';
    }
  }
}

class _PuntosProgreso extends StatelessWidget {
  const _PuntosProgreso({required this.total, required this.actual});

  final int total;
  final int actual;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Página ${actual + 1} de $total',
      liveRegion: true,
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < total; i++)
              AnimatedContainer(
                duration: AppMotion.base,
                curve: AppMotion.standard,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                height: 8,
                width: i == actual ? 24 : 8,
                decoration: BoxDecoration(
                  color: i == actual ? scheme.primary : scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Página 1: presenta la app con su ilustración principal, nombre y una
/// propuesta de valor breve — antes de entrar en el detalle de cada función.
class _PaginaBienvenida extends StatelessWidget {
  const _PaginaBienvenida();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // SingleChildScrollView (no solo Padding+Column): la ilustración de
    // bienvenida es la más grande del onboarding y en una pantalla chica
    // u horizontal podría desbordar en vez de simplemente hacer scroll.
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AnimatedIllustration(
            AppIllustrationAsset.welcome,
            size: 220,
            ambient: true,
          ),
          const SizedBox(height: 28),
          StaggeredFadeIn(
            index: 0,
            child: Text(
              'Horas Trabajo RD',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          StaggeredFadeIn(
            index: 1,
            child: Text(
              'Marca tu entrada y salida, y deja que la app calcule tu '
              'nómina exacta según las leyes laborales dominicanas.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Páginas 2-4 ("¿Qué puedes hacer?" / "¿Cómo funciona?"): una ilustración
/// animada por función real de la app, con una etiqueta de paso que deja
/// claro el flujo Marca → Calcula → Organiza.
class _PaginaIntro extends StatelessWidget {
  const _PaginaIntro({
    required this.illustration,
    required this.paso,
    required this.titulo,
    required this.subtitulo,
  });

  final AppIllustrationAsset illustration;
  final String paso;
  final String titulo;
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedIllustration(illustration, size: 160, semanticLabel: titulo),
          const SizedBox(height: AppSpacing.lg),
          StaggeredFadeIn(
            index: 0,
            child: Text(
              paso.toUpperCase(),
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          StaggeredFadeIn(
            index: 1,
            child: Text(
              titulo,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          StaggeredFadeIn(
            index: 2,
            child: Text(
              subtitulo,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Página 5 ("Características principales"): resume en una grilla las
/// funciones que no entraron en el flujo de 3 pasos, cada una con su
/// propio icono y aparición escalonada.
class _PaginaCaracteristicas extends StatelessWidget {
  const _PaginaCaracteristicas();

  static const _items = [
    (
      icono: Icons.location_on_outlined,
      titulo: 'Geocerca inteligente',
      texto: 'Guarda tu lugar de trabajo y recibe avisos al llegar o salir.',
    ),
    (
      icono: Icons.calculate_outlined,
      titulo: 'Cálculo RD certero',
      texto: 'Ordinarias, extras, nocturnas y feriados según la Ley 16-92.',
    ),
    (
      icono: Icons.picture_as_pdf_outlined,
      titulo: 'Reportes y PDF',
      texto: 'Exporta tu nómina semanal o mensual en PDF o CSV.',
    ),
    (
      icono: Icons.lock_outline,
      titulo: '100% local y privado',
      texto: 'Sin cuentas ni nube: tus datos quedan en tu teléfono.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StaggeredFadeIn(
            index: 0,
            child: Text(
              'Todo lo que necesitas',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          for (var i = 0; i < _items.length; i++)
            StaggeredFadeIn(
              index: i + 1,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _Caracteristica(
                  icono: _items[i].icono,
                  titulo: _items[i].titulo,
                  texto: _items[i].texto,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Caracteristica extends StatelessWidget {
  const _Caracteristica({
    required this.icono,
    required this.titulo,
    required this.texto,
  });

  final IconData icono;
  final String titulo;
  final String texto;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(icono, color: scheme.onPrimaryContainer),
        ),
        const SizedBox(width: AppSpacing.lg),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(
                texto,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PaginaPerfil extends StatelessWidget {
  const _PaginaPerfil({required this.nombre, required this.salario});

  final TextEditingController nombre;
  final TextEditingController salario;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StaggeredFadeIn(
            index: 0,
            child: MorphingBlob(
              size: 104,
              color: scheme.primaryContainer,
              child: Icon(Icons.badge_outlined, size: 44, color: scheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(height: 28),
          StaggeredFadeIn(
            index: 1,
            child: Text(
              'Cuéntanos sobre ti',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          StaggeredFadeIn(
            index: 2,
            child: Text(
              'Necesitamos tu nombre y salario mensual para calcular tu '
              'pago con precisión.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 28),
          StaggeredFadeIn(
            index: 3,
            child: TextField(
              controller: nombre,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
          ),
          const SizedBox(height: 20),
          StaggeredFadeIn(
            index: 4,
            child: TextField(
              controller: salario,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Salario mensual',
                prefixIcon: Icon(Icons.payments_outlined),
                suffixText: 'RD\$',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginaUbicacion extends StatelessWidget {
  const _PaginaUbicacion({
    required this.seleccionUsarGps,
    required this.onCambiar,
  });

  final bool seleccionUsarGps;
  final ValueChanged<bool> onCambiar;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StaggeredFadeIn(
            index: 0,
            child: MorphingBlob(
              size: 104,
              color: scheme.primaryContainer,
              blobA: PixelBlobs.media,
              blobB: PixelBlobs.marcada,
              child: Icon(Icons.my_location, size: 44, color: scheme.onPrimaryContainer),
            ),
          ),
          const SizedBox(height: 28),
          StaggeredFadeIn(
            index: 1,
            child: Text(
              '¿Cómo prefieres marcar?',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          StaggeredFadeIn(
            index: 2,
            child: Text(
              'Puedes cambiar esto luego en Ajustes.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: 28),
          StaggeredFadeIn(
            index: 3,
            child: _TarjetaOpcion(
              icono: Icons.location_on,
              titulo: 'Con GPS',
              subtitulo: 'Verifica tu llegada automáticamente y permite '
                  'vigilar tu geocerca del trabajo.',
              seleccionada: seleccionUsarGps,
              onTap: () => onCambiar(true),
            ),
          ),
          const SizedBox(height: 12),
          StaggeredFadeIn(
            index: 4,
            child: _TarjetaOpcion(
              icono: Icons.location_off,
              titulo: 'Manual, sin GPS',
              subtitulo: 'No se pide ubicación ni permisos. Marcado 100% '
                  'manual.',
              seleccionada: !seleccionUsarGps,
              onTap: () => onCambiar(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaOpcion extends StatelessWidget {
  const _TarjetaOpcion({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.seleccionada,
    required this.onTap,
  });

  final IconData icono;
  final String titulo;
  final String subtitulo;
  final bool seleccionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: seleccionada,
      label: '$titulo. $subtitulo',
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        customBorder: const SquircleBorder(radius: PixelRadii.medium),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          padding: const EdgeInsets.all(16),
          decoration: ShapeDecoration(
            color: seleccionada ? scheme.primaryContainer : scheme.surfaceContainerLow,
            shape: SquircleBorder(
              radius: PixelRadii.medium,
              side: BorderSide(
                color: seleccionada ? scheme.primary : scheme.outlineVariant,
                width: seleccionada ? 2 : 1,
              ),
            ),
          ),
          child: ExcludeSemantics(
            child: Row(
              children: [
                Icon(icono, color: seleccionada ? scheme.primary : scheme.onSurfaceVariant),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(
                        subtitulo,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 150),
                  child: seleccionada
                      ? Icon(Icons.check_circle, key: const ValueKey(true), color: scheme.primary)
                      : const SizedBox(key: ValueKey(false), width: 24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Página 8 ("Apoya este proyecto"): explica de forma breve y humana cómo
/// las donaciones ayudan al mantenimiento de la app. El pago todavía no
/// está conectado — "Donar ahora" lo avisa en vez de simular un cobro — y
/// "Continuar sin donar" (el botón inferior normal) nunca hace sentir mal
/// a quien no dona.
class _PaginaDonacion extends StatelessWidget {
  const _PaginaDonacion();

  void _avisarPendiente(BuildContext context) {
    HapticFeedback.selectionClick();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Muy pronto vas a poder apoyar el proyecto desde acá 💛'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AnimatedIllustration(
            AppIllustrationAsset.support,
            size: 150,
            ambient: true,
          ),
          const SizedBox(height: AppSpacing.xxl),
          StaggeredFadeIn(
            index: 0,
            child: Text(
              'Apoya este proyecto',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          StaggeredFadeIn(
            index: 1,
            child: Text(
              'Horas Trabajo RD es gratis y 100% local — sin publicidad ni '
              'venta de datos. Si te sirve, tu aporte ayuda a sostener el '
              'tiempo de mantenimiento y las próximas mejoras.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
          const SizedBox(height: AppSpacing.xxl),
          StaggeredFadeIn(
            index: 2,
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _avisarPendiente(context),
                icon: const Icon(Icons.favorite_outline),
                label: const Text('Donar ahora'),
              ),
            ),
          ),
          const SizedBox(height: 6),
          StaggeredFadeIn(
            index: 3,
            child: Text(
              'Próximamente',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaginaFinal extends StatelessWidget {
  const _PaginaFinal();

  @override
  Widget build(BuildContext context) => const SuccessState(
        titulo: '¡Todo listo!',
        mensaje:
            'Ya puedes empezar a marcar tu jornada. Bienvenido a Horas '
            'Trabajo RD.',
      );
}
