import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:horas_trabajo/core/navigation/fade_through_route.dart';
import 'package:horas_trabajo/core/widgets/animated_tap_scale.dart';
import 'package:horas_trabajo/core/widgets/staggered_fade_in.dart';
import 'package:horas_trabajo/data/models/employee_profile.dart';
import 'package:horas_trabajo/features/root/root_screen.dart';
import 'package:horas_trabajo/state/app_state.dart';
import 'package:provider/provider.dart';

/// Bienvenida inicial: se muestra una única vez, la primera vez que se abre
/// la app (ver [AppState.onboardingCompletado]). Presenta las funciones
/// principales y recoge lo mínimo indispensable — nombre, salario y
/// preferencia de GPS — para que el cálculo de nómina funcione desde la
/// primera jornada marcada.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _totalPaginas = 7;
  static const _indicePerfil = 4;
  static const _indiceUbicacion = 5;
  static const _indiceFinal = 6;

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
    return _controller.animateToPage(
      pagina,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
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
    Navigator.of(context).pushReplacement(
      FadeThroughRoute<void>(builder: (_) => const RootScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
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
                    const _PaginaIntro(
                      icono: null,
                      titulo: 'Horas Trabajo RD',
                      subtitulo:
                          'Marca tu entrada y salida, y deja que la app '
                          'calcule tu nómina exacta según las leyes '
                          'laborales dominicanas.',
                    ),
                    const _PaginaIntro(
                      icono: Icons.touch_app,
                      titulo: 'Marca con un solo toque',
                      subtitulo:
                          'Registra tu entrada y salida al instante. Con '
                          'GPS para verificar tu llegada, o en modo 100% '
                          'manual si prefieres no compartir tu ubicación.',
                    ),
                    const _PaginaIntro(
                      icono: Icons.calculate_outlined,
                      titulo: 'Tu pago, calculado al segundo',
                      subtitulo:
                          'Horas ordinarias, extras, nocturnas, feriados y '
                          'exceso semanal — todo desglosado en tiempo real, '
                          'según la Ley 16-92.',
                    ),
                    const _PaginaIntro(
                      icono: Icons.dashboard_customize_outlined,
                      titulo: 'Reportes, feriados y respaldo',
                      subtitulo:
                          'Reportes semanales y mensuales con gráficos, '
                          'exportación a PDF, y control de feriados RD, '
                          'vacaciones y permisos.',
                    ),
                    _PaginaPerfil(nombre: _nombre, salario: _salario),
                    _PaginaUbicacion(
                      seleccionUsarGps: _usarUbicacion,
                      onCambiar: (v) => setState(() => _usarUbicacion = v),
                    ),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < total; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            height: 8,
            width: i == actual ? 24 : 8,
            decoration: BoxDecoration(
              color: i == actual ? scheme.primary : scheme.outlineVariant,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

class _PaginaIntro extends StatelessWidget {
  const _PaginaIntro({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
  });

  /// `null` en la primera página: usa el logo de la app en vez de un ícono.
  final IconData? icono;
  final String titulo;
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StaggeredFadeIn(
            index: 0,
            child: icono == null
                ? ClipOval(
                    child: Image.asset(
                      'assets/logo.png',
                      height: 120,
                      width: 120,
                      fit: BoxFit.cover,
                    ),
                  )
                : Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icono, size: 56, color: scheme.onPrimaryContainer),
                  ),
          ),
          const SizedBox(height: 32),
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
          const SizedBox(height: 12),
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
            child: Container(
              height: 96,
              width: 96,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
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
          const SizedBox(height: 16),
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
            child: Container(
              height: 96,
              width: 96,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                shape: BoxShape.circle,
              ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: seleccionada ? scheme.primaryContainer : scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: seleccionada ? scheme.primary : scheme.outlineVariant,
            width: seleccionada ? 2 : 1,
          ),
        ),
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
    );
  }
}

class _PaginaFinal extends StatelessWidget {
  const _PaginaFinal();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          StaggeredFadeIn(
            index: 0,
            child: Container(
              height: 120,
              width: 120,
              decoration: BoxDecoration(color: scheme.tertiaryContainer, shape: BoxShape.circle),
              child: Icon(Icons.check_circle, size: 64, color: scheme.onTertiaryContainer),
            ),
          ),
          const SizedBox(height: 32),
          StaggeredFadeIn(
            index: 1,
            child: Text(
              '¡Todo listo!',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 12),
          StaggeredFadeIn(
            index: 2,
            child: Text(
              'Ya puedes empezar a marcar tu jornada. Bienvenido a '
              'Horas Trabajo RD.',
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
