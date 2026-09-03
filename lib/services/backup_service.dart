import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:csv/csv.dart' as csv_lib;
import 'package:horas_trabajo/core/utils/formatters.dart';
import 'package:horas_trabajo/data/models/employee_profile.dart';
import 'package:horas_trabajo/data/models/rd_pay_rules.dart';
import 'package:horas_trabajo/data/models/work_session.dart';
import 'package:horas_trabajo/data/models/workplace.dart';
import 'package:horas_trabajo/data/repositories/settings_repository.dart';
import 'package:horas_trabajo/data/repositories/work_session_repository.dart';
import 'package:horas_trabajo/data/repositories/workplace_repository.dart';
import 'package:horas_trabajo/domain/salary/salary_engine.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

/// Copia de seguridad, restauración y exportación de datos — todo 100% local
/// (el archivo resultante se comparte con el selector del sistema; no hay
/// backend ni nube propia).
class BackupService {
  BackupService({
    SettingsRepository? settings,
    WorkplaceRepository? workplaceRepo,
    WorkSessionRepository? sessions,
  })  : _settings = settings ?? SettingsRepository(),
        _workplaceRepo = workplaceRepo ?? WorkplaceRepository(),
        _sessions = sessions ?? WorkSessionRepository();

  /// Versión del formato de backup. Subir junto con cambios incompatibles
  /// en el esquema exportado.
  static const _version = 1;

  final SettingsRepository _settings;
  final WorkplaceRepository _workplaceRepo;
  final WorkSessionRepository _sessions;

  /// Arma el mapa completo de backup (perfil, reglas, workplace, historial).
  Future<Map<String, dynamic>> _armarBackup() async {
    final perfil = await _settings.cargarPerfil();
    final reglas = await _settings.cargarReglas();
    final usarUbicacion = await _settings.cargarUsarUbicacion();
    final workplace = await _workplaceRepo.getWorkplace();
    final sesiones = await _sessions.obtenerTodas();
    return {
      'version': _version,
      'exportadoEn': DateTime.now().toIso8601String(),
      'perfil': perfil.toJson(),
      'reglas': reglas.toJson(),
      'usarUbicacion': usarUbicacion,
      'workplace': workplace?.toJson(),
      'sesiones': sesiones.map((s) => s.toMap()).toList(),
    };
  }

  /// Exporta perfil + reglas + lugar de trabajo + historial completo a un
  /// `.json` y abre el selector de compartir del sistema.
  Future<void> exportarBackupJson() async {
    final data = await _armarBackup();
    final texto = const JsonEncoder.withIndent('  ').convert(data);
    await _compartirBytes(
      Uint8List.fromList(utf8.encode(texto)),
      _nombreArchivo('backup', 'json'),
    );
  }

  /// Restaura desde los bytes de un `.json` exportado con [exportarBackupJson].
  /// **Reemplaza por completo** perfil, reglas, lugar de trabajo e historial
  /// actuales. Devuelve `false` si el archivo no es un backup válido/
  /// compatible (no se modifica nada en ese caso).
  Future<bool> restaurarBackupJson(Uint8List bytes) async {
    final Map<String, dynamic> data;
    try {
      data = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
    } catch (_) {
      return false;
    }
    if (data['version'] != _version) return false;

    try {
      final perfil =
          EmployeeProfile.fromJson(data['perfil'] as Map<String, dynamic>);
      final reglas =
          RdPayRules.fromJson(data['reglas'] as Map<String, dynamic>);
      final usarUbicacion = data['usarUbicacion'] as bool? ?? true;
      final wpJson = data['workplace'] as Map<String, dynamic>?;
      final sesiones = (data['sesiones'] as List)
          .cast<Map<String, dynamic>>()
          .map(WorkSession.fromMap)
          .toList();

      await _settings.guardarPerfil(perfil);
      await _settings.guardarReglas(reglas);
      await _settings.guardarUsarUbicacion(usarUbicacion);
      if (wpJson != null) {
        await _workplaceRepo.setWorkplace(Workplace.fromJson(wpJson));
      } else {
        await _workplaceRepo.clearWorkplace();
      }
      await _sessions.reemplazarTodas(sesiones);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Exporta todo el historial a CSV (una fila por sesión, con el desglose
  /// de horas por categoría calculado con [motor]).
  Future<void> exportarCsv(SalaryEngine motor) async {
    final sesiones = await _sessions.obtenerTodas();
    final filas = <List<dynamic>>[
      [
        'Fecha',
        'Entrada',
        'Salida',
        'Duración',
        'Ordinarias (h)',
        'Extra (h)',
        'Nocturnas (h)',
        'Feriado/Descanso (h)',
        'Importe',
        'Nota',
      ],
    ];
    for (final s in sesiones) {
      final r = motor.calcularSesionUnica(s);
      String horasDe(bool Function(PayCategory) pred) => r.lineas
          .where((l) => pred(l.categoria))
          .fold(0.0, (acc, l) => acc + l.horas)
          .toStringAsFixed(2);

      filas.add([
        Fmt.fechaCorta(s.inicio),
        Fmt.horaCorta(s.inicio),
        s.fin == null ? '' : Fmt.horaCorta(s.fin!),
        Fmt.duracion(s.duracion),
        horasDe((c) =>
            c == PayCategory.ordinaria || c == PayCategory.ordinariaNocturna),
        horasDe((c) => c.esExtraordinaria),
        horasDe((c) => c.esNocturna),
        horasDe(
            (c) => c == PayCategory.feriada || c == PayCategory.descanso),
        r.importeTotal.toStringAsFixed(2),
        s.nota,
      ]);
    }
    final texto = csv_lib.csv.encode(filas);
    await _compartirBytes(
      Uint8List.fromList(utf8.encode(texto)),
      _nombreArchivo('historial', 'csv'),
    );
  }

  /// Genera un PDF de nómina para [report] (historial completo o un período
  /// específico) y abre el selector de compartir.
  Future<void> exportarPdf(PeriodPayReport report, {required String titulo}) async {
    final doc = pw.Document();
    doc.addPage(
      pw.MultiPage(
        build: (context) => [
          pw.Text(
            titulo,
            style: const pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Generado el ${Fmt.fechaExacta(DateTime.now())}',
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 16),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Horas totales: ${Fmt.horas(report.totalHoras)}'),
              pw.Text(
                'Total a pagar: ${Fmt.moneda(report.importeTotal)}',
                style: const pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text('Desglose por concepto',
              style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: const ['Concepto', 'Horas', 'Importe'],
            data: [
              for (final l in report.lineasConsolidadas)
                [l.categoria.etiqueta, Fmt.horas(l.horas), Fmt.moneda(l.importe)],
            ],
          ),
          pw.SizedBox(height: 16),
          pw.Text('Detalle por jornada',
              style: const pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: const ['Fecha', 'Entrada', 'Salida', 'Horas', 'Importe'],
            data: [
              for (final s in report.sesiones)
                [
                  Fmt.fechaCorta(s.sesion.inicio),
                  Fmt.horaCorta(s.sesion.inicio),
                  s.sesion.fin == null ? 'en curso' : Fmt.horaCorta(s.sesion.fin!),
                  Fmt.horas(s.totalHoras),
                  Fmt.moneda(s.importeTotal),
                ],
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text(
            'Cálculo referencial según el Código de Trabajo de la República '
            'Dominicana (Ley 16-92) con las reglas configuradas en la app. '
            'No sustituye la nómina oficial ni constituye asesoría legal.',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
          ),
        ],
      ),
    );
    await _compartirBytes(await doc.save(), _nombreArchivo('nomina', 'pdf'));
  }

  Future<void> _compartirBytes(Uint8List bytes, String nombre) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$nombre');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], subject: nombre),
    );
  }

  String _nombreArchivo(String base, String ext) {
    final ahora = DateTime.now();
    String p2(int n) => n.toString().padLeft(2, '0');
    final marca =
        '${ahora.year}${p2(ahora.month)}${p2(ahora.day)}_${p2(ahora.hour)}${p2(ahora.minute)}';
    return 'horas_trabajo_${base}_$marca.$ext';
  }
}
