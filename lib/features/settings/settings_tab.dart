import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:horas_trabajo/core/theme/app_theme.dart';
import 'package:horas_trabajo/core/theme/theme_manager.dart';
import 'package:horas_trabajo/data/models/employee_profile.dart';
import 'package:horas_trabajo/data/models/rd_pay_rules.dart';
import 'package:horas_trabajo/features/backup/backup_screen.dart';
import 'package:horas_trabajo/state/app_state.dart';
import 'package:provider/provider.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  TextEditingController? _nombre;
  TextEditingController? _salario;
  RdPayRules _reglas = const RdPayRules();
  bool _usarUbicacion = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final app = context.read<AppState>();
    _nombre ??= TextEditingController(text: app.perfil.nombre);
    _salario ??= TextEditingController(
      text: app.perfil.salarioMensual > 0
          ? app.perfil.salarioMensual.toStringAsFixed(2)
          : '',
    );
    _reglas = app.reglas;
    _usarUbicacion = app.usarUbicacion;
  }

  @override
  void dispose() {
    _nombre?.dispose();
    _salario?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.read<AppState>();
    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const _SeccionTitulo('Perfil'),
          _CardPerfil(
            nombre: _nombre!,
            salario: _salario!,
            onGuardar: () => _guardarPerfil(app),
          ),
          const SizedBox(height: 24),
          const _SeccionTitulo('Ubicación'),
          _CardUbicacion(
            usarUbicacion: _usarUbicacion,
            onChanged: _setUsarUbicacion,
          ),
          const SizedBox(height: 24),
          const _SeccionTitulo('Apariencia'),
          const _CardTema(),
          const SizedBox(height: 24),
          const _SeccionTitulo('Reglas laborales (RD)'),
          _CardReglas(reglas: _reglas, onChanged: _setReglas),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _setReglas(const RdPayRules()),
            icon: const Icon(Icons.restart_alt),
            label: const Text('Restaurar valores por defecto'),
          ),
          const SizedBox(height: 24),
          const _SeccionTitulo('Datos'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.save_alt),
              title: const Text('Copia de seguridad y exportación'),
              subtitle: const Text('Backup JSON, CSV y restaurar'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const BackupScreen()),
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Future<void> _guardarPerfil(AppState app) async {
    final messenger = ScaffoldMessenger.of(context);
    final salario = double.tryParse(_salario!.text.replaceAll(',', '.'));
    if (salario == null || salario <= 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Ingresa un salario mensual válido.')),
      );
      return;
    }
    await app.guardarPerfil(EmployeeProfile(
      nombre: _nombre!.text.trim(),
      salarioMensual: salario,
    ));
    messenger.showSnackBar(const SnackBar(content: Text('Perfil guardado ✅')));
  }

  Future<void> _setReglas(RdPayRules reglas) async {
    setState(() => _reglas = reglas);
    await context.read<AppState>().guardarReglas(reglas);
  }

  Future<void> _setUsarUbicacion(bool valor) async {
    setState(() => _usarUbicacion = valor);
    await context.read<AppState>().guardarUsarUbicacion(valor);
  }
}

class _SeccionTitulo extends StatelessWidget {
  const _SeccionTitulo(this.texto);
  final String texto;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(texto.toUpperCase(),
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              )),
    );
  }
}

class _CardPerfil extends StatelessWidget {
  const _CardPerfil({
    required this.nombre,
    required this.salario,
    required this.onGuardar,
  });

  final TextEditingController nombre;
  final TextEditingController salario;
  final VoidCallback onGuardar;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: nombre,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: salario,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Salario mensual',
                prefixIcon: Icon(Icons.payments),
                suffixText: 'RD\$',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                  onPressed: onGuardar, child: const Text('Guardar perfil')),
            ),
          ],
        ),
      ),
    );
  }
}

class _CardUbicacion extends StatelessWidget {
  const _CardUbicacion({required this.usarUbicacion, required this.onChanged});

  final bool usarUbicacion;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SwitchListTile(
        value: usarUbicacion,
        onChanged: onChanged,
        title: const Text('Usar GPS al marcar'),
        subtitle: Text(
          usarUbicacion
              ? 'Se pide ubicación al marcar entrada y se puede vigilar geocerca'
              : 'Modo 100% manual: no se pide GPS ni permisos. '
                  'La vigilancia de llegada/salida queda desactivada.',
        ),
        secondary: Icon(
          usarUbicacion ? Icons.location_on : Icons.location_off,
        ),
      ),
    );
  }
}

class _CardTema extends StatelessWidget {
  const _CardTema();

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeManager>();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Modo', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                    value: ThemeMode.light,
                    label: Text('Claro'),
                    icon: Icon(Icons.light_mode)),
                ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text('Oscuro'),
                    icon: Icon(Icons.dark_mode)),
                ButtonSegment(
                    value: ThemeMode.system,
                    label: Text('Sistema'),
                    icon: Icon(Icons.settings_brightness)),
              ],
              selected: {theme.mode},
              onSelectionChanged: (s) => theme.setMode(s.first),
            ),
            const SizedBox(height: 20),
            Text('Color primario', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (var i = 0; i < ThemePalettes.seeds.length; i++)
                  _BolaColor(
                    color: ThemePalettes.seeds[i],
                    nombre: ThemePalettes.nombre(i),
                    seleccionada: theme.seedIndex == i,
                    onTap: () => theme.setSeed(i),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BolaColor extends StatelessWidget {
  const _BolaColor({
    required this.color,
    required this.nombre,
    required this.seleccionada,
    required this.onTap,
  });

  final Color color;
  final String nombre;
  final bool seleccionada;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: nombre,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: seleccionada
                ? Border.all(
                    color: Theme.of(context).colorScheme.onSurface, width: 3)
                : null,
          ),
          child: seleccionada ? const Icon(Icons.check, color: Colors.white) : null,
        ),
      ),
    );
  }
}

class _CardReglas extends StatelessWidget {
  const _CardReglas({required this.reglas, required this.onChanged});

  final RdPayRules reglas;
  final ValueChanged<RdPayRules> onChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _CampoNumero(
              etiqueta: 'Jornada diaria (h)',
              valor: reglas.ordinariaDiaHoras.toDouble(),
              onCambio: (v) =>
                  onChanged(reglas.copyWith(ordinariaDiaHoras: v.round())),
            ),
            _CampoNumero(
              etiqueta: 'Jornada semanal (h)',
              valor: reglas.ordinariaSemanaHoras.toDouble(),
              onCambio: (v) =>
                  onChanged(reglas.copyWith(ordinariaSemanaHoras: v.round())),
            ),
            _CampoNumero(
              etiqueta: 'Tope exceso semanal (h)',
              valor: reglas.excesoTopeHoras.toDouble(),
              onCambio: (v) => onChanged(reglas.copyWith(excesoTopeHoras: v.round())),
            ),
            _CampoNumero(
              etiqueta: 'Recargo hora extra (%)',
              valor: reglas.recargoExtraPct,
              onCambio: (v) => onChanged(reglas.copyWith(recargoExtraPct: v)),
            ),
            _CampoNumero(
              etiqueta: 'Recargo exceso > tope (%)',
              valor: reglas.recargoExcesoPct,
              onCambio: (v) => onChanged(reglas.copyWith(recargoExcesoPct: v)),
            ),
            _CampoNumero(
              etiqueta: 'Recargo nocturno (%)',
              valor: reglas.recargoNocturnoPct,
              onCambio: (v) => onChanged(reglas.copyWith(recargoNocturnoPct: v)),
            ),
            _CampoNumero(
              etiqueta: 'Recargo feriado/descanso (%)',
              valor: reglas.recargoFeriadoPct,
              onCambio: (v) => onChanged(reglas.copyWith(recargoFeriadoPct: v)),
            ),
            Row(
              children: [
                Expanded(
                  child: _CampoNumero(
                    etiqueta: 'Nocturno inicia (h)',
                    valor: reglas.nocturnoInicioHora.toDouble(),
                    onCambio: (v) =>
                        onChanged(reglas.copyWith(nocturnoInicioHora: v.round())),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _CampoNumero(
                    etiqueta: 'Nocturno termina (h)',
                    valor: reglas.nocturnoFinHora.toDouble(),
                    onCambio: (v) =>
                        onChanged(reglas.copyWith(nocturnoFinHora: v.round())),
                  ),
                ),
              ],
            ),
            _CampoNumero(
              etiqueta: 'Divisor salario diario',
              valor: reglas.diasPorMes,
              onCambio: (v) => onChanged(reglas.copyWith(diasPorMes: v)),
            ),
          ],
        ),
      ),
    );
  }
}

class _CampoNumero extends StatefulWidget {
  const _CampoNumero({
    required this.etiqueta,
    required this.valor,
    required this.onCambio,
  });

  final String etiqueta;
  final double valor;
  final ValueChanged<double> onCambio;

  @override
  State<_CampoNumero> createState() => _CampoNumeroState();
}

class _CampoNumeroState extends State<_CampoNumero> {
  late final TextEditingController _ctrl;

  bool get _entero =>
      (widget.valor == widget.valor.roundToDouble()) && widget.valor < 100;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: _texto(widget.valor));
  }

  String _texto(double v) =>
      (_entero) ? v.round().toString() : v.toStringAsFixed(1);

  @override
  void didUpdateWidget(_CampoNumero old) {
    super.didUpdateWidget(old);
    if (old.valor != widget.valor && _ctrl.text != _texto(widget.valor)) {
      _ctrl.text = _texto(widget.valor);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _aplicar() {
    final v = double.tryParse(_ctrl.text.replaceAll(',', '.'));
    if (v != null) widget.onCambio(v);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextField(
        controller: _ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onSubmitted: (_) => _aplicar(),
        onEditingComplete: _aplicar,
        decoration: InputDecoration(
          labelText: widget.etiqueta,
          suffixIcon: IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Aplicar',
            onPressed: _aplicar,
          ),
        ),
      ),
    );
  }
}