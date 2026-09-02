import 'package:horas_trabajo/data/models/rd_pay_rules.dart';
import 'package:horas_trabajo/data/models/work_session.dart';

/// Categorías de pago que la app separa en el desglose.
enum PayCategory {
  ordinaria,
  ordinariaNocturna,
  extra,
  extraNocturna,
  exceso,
  excesoNocturna,
  feriada,
  descanso;

  String get etiqueta => switch (this) {
        ordinaria => 'Ordinaria',
        ordinariaNocturna => 'Ordinaria nocturna',
        extra => 'Extra +35%',
        extraNocturna => 'Extra nocturna',
        exceso => 'Exceso +100%',
        excesoNocturna => 'Exceso nocturno',
        feriada => 'Feriado (doble)',
        descanso => 'Descanso semanal (doble)',
      };

  bool get esNocturna => switch (this) {
        ordinariaNocturna || extraNocturna || excesoNocturna => true,
        _ => false,
      };

  bool get esExtraordinaria => switch (this) {
        extra || extraNocturna || exceso || excesoNocturna => true,
        _ => false,
      };
}

/// Una línea del desglose de pago (facturable).
class PayLine {
  const PayLine({
    required this.categoria,
    required this.horas,
    required this.factor,
    required this.importe,
  });

  final PayCategory categoria;
  final double horas;
  final double factor;
  final double importe;
}

/// Resultado de cálculo de una única sesión.
class SessionPayReport {
  const SessionPayReport({
    required this.sesion,
    required this.lineas,
  });

  final WorkSession sesion;
  final List<PayLine> lineas;

  double get totalHoras => lineas.fold(0, (acc, l) => acc + l.horas);
  double get importeTotal => lineas.fold(0, (acc, l) => acc + l.importe);
}

/// Resultado consolidado de un período (semana, mes, rango).
class PeriodPayReport {
  const PeriodPayReport({
    required this.sesiones,
    required this.totalHoras,
    required this.importeTotal,
    required this.ordinarias,
    required this.extra,
    required this.exceso,
    required this.nocturnas,
    required this.feriadas,
  });

  final List<SessionPayReport> sesiones;
  final double totalHoras;
  final double importeTotal;
  final double ordinarias;
  final double extra;
  final double exceso;
  final double nocturnas;
  final double feriadas;

  List<PayLine> get lineasConsolidadas {
    final importes = <PayCategory, double>{};
    final horas = <PayCategory, double>{};
    final factor = <PayCategory, double>{};
    for (final s in sesiones) {
      for (final l in s.lineas) {
        importes[l.categoria] = (importes[l.categoria] ?? 0) + l.importe;
        horas[l.categoria] = (horas[l.categoria] ?? 0) + l.horas;
        factor[l.categoria] = l.factor;
      }
    }
    return [
      for (final e in importes.entries)
        PayLine(
          categoria: e.key,
          horas: horas[e.key] ?? 0,
          factor: factor[e.key] ?? 1,
          importe: e.value,
        ),
    ];
  }
}

/// Motor de cálculo salarial con las reglas del Código de Trabajo de RD.
///
/// Clasifica cada minuto: jornada ordinaria (8 h/d · 44 h/sem), extraordinarias
/// (+35% hasta 68 h/sem), exceso (+100% sobre 68 h/sem), recargo nocturno
/// (+15%, 9pm–7am) y feriado/descanso (+100%). Es una guía; los porcentajes
/// son editables y el resultado no constituye asesoría legal.
class SalaryEngine {
  const SalaryEngine({required this.salarioMensual, required this.reglas});

  final double salarioMensual;
  final RdPayRules reglas;

  double get valorHoraOrdinaria => reglas.valorHoraOrdinaria(salarioMensual);

  /// Calcula el pago de las [sesiones] (opcionalmente filtradas por rango de
  /// inicio), procesadas en orden cronológico para acumular jornada de semana.
  PeriodPayReport calcularRango(
    List<WorkSession> sesiones, {
    DateTime? desde,
    DateTime? hasta,
  }) {
    var list = [...sesiones];
    if (desde != null) list = list.where((s) => !s.inicio.isBefore(desde)).toList();
    if (hasta != null) list = list.where((s) => s.inicio.isBefore(hasta)).toList();
    list.sort((a, b) => a.inicio.compareTo(b.inicio));

    final reports = <SessionPayReport>[];
    var acumSemana = 0;
    DateTime? trackDia;
    var acumDia = 0;

    for (final s in list) {
      final diaInicio = DateTime(s.inicio.year, s.inicio.month, s.inicio.day);
      if (trackDia != diaInicio) {
        trackDia = diaInicio;
        acumDia = 0;
      }

      final r = _calcularSesion(s, minSemanaAcum: acumSemana, minDiaAcum: acumDia);
      reports.add(r);

      final totalMin = s.duracion.inMinutes;
      acumSemana += totalMin;
      acumDia += _minutosEnDia(s.inicio, s.fin, diaInicio);
    }

    return PeriodPayReport(
      sesiones: reports,
      totalHoras: reports.fold(0, (a, r) => a + r.totalHoras),
      importeTotal: reports.fold(0, (a, r) => a + r.importeTotal),
      ordinarias: _horas(reports, {PayCategory.ordinaria, PayCategory.ordinariaNocturna}),
      extra: _horas(reports, {PayCategory.extra, PayCategory.extraNocturna}),
      exceso: _horas(reports, {PayCategory.exceso, PayCategory.excesoNocturna}),
      nocturnas: _horasNocturnas(reports),
      feriadas: _horas(reports, {PayCategory.feriada, PayCategory.descanso}),
    );
  }

  /// Desglose de una sola sesión con contexto fresco (vista rápida).
  SessionPayReport calcularSesionUnica(WorkSession sesion) =>
      _calcularSesion(sesion, minSemanaAcum: 0, minDiaAcum: 0);

  SessionPayReport _calcularSesion(
    WorkSession s, {
    required int minSemanaAcum,
    required int minDiaAcum,
  }) {
    final lineas = <PayLine>[];
    if (s.fin == null || s.duracion.inSeconds <= 0) {
      return SessionPayReport(sesion: s, lineas: lineas);
    }

    final minutos = <PayCategory, int>{};
    var cursor = s.inicio;
    final fin = s.fin!;
    DateTime calendarioDia = DateTime(cursor.year, cursor.month, cursor.day);
    var acumDia = minDiaAcum;
    var acumSemana = minSemanaAcum;

    while (cursor.isBefore(fin)) {
      final proximo = cursor.add(const Duration(minutes: 1));
      if (!_mismoDia(cursor, calendarioDia)) {
        calendarioDia = DateTime(cursor.year, cursor.month, cursor.day);
        acumDia = 0;
      }

      final cat = _clasificarMinuto(
        cursor,
        acumDia: acumDia,
        acumSemana: acumSemana,
        feriado: s.esFeriado,
        descanso: s.esDescansoSemanal,
      );
      minutos[cat] = (minutos[cat] ?? 0) + 1;

      acumDia++;
      acumSemana++;
      cursor = proximo.isAfter(fin) ? fin : proximo;
    }

    for (final e in minutos.entries) {
      final horas = e.value / 60;
      final factor = _factorDe(e.key);
      lineas.add(PayLine(
        categoria: e.key,
        horas: horas,
        factor: factor,
        importe: valorHoraOrdinaria * horas * factor,
      ));
    }
    return SessionPayReport(sesion: s, lineas: lineas);
  }

  PayCategory _clasificarMinuto(
    DateTime minuto, {
    required int acumDia,
    required int acumSemana,
    required bool feriado,
    required bool descanso,
  }) {
    if (feriado && !descanso) return PayCategory.feriada;
    if (descanso) return PayCategory.descanso;

    final esNoche = reglas.esHoraNocturna(minuto.hour);
    final limiteDia = reglas.ordinariaDiaHoras * 60;
    final limiteSemana = reglas.ordinariaSemanaHoras * 60;
    final topeExceso = reglas.excesoTopeHoras * 60;

    final extraordinaria = acumDia >= limiteDia || acumSemana >= limiteSemana;
    if (!extraordinaria) {
      return esNoche ? PayCategory.ordinariaNocturna : PayCategory.ordinaria;
    }
    final sobreExceso = acumSemana >= topeExceso;
    if (sobreExceso) {
      return esNoche ? PayCategory.excesoNocturna : PayCategory.exceso;
    }
    return esNoche ? PayCategory.extraNocturna : PayCategory.extra;
  }

  double _factorDe(PayCategory cat) => switch (cat) {
        PayCategory.ordinaria => 1.0,
        PayCategory.ordinariaNocturna => reglas.factorNocturno,
        PayCategory.extra => reglas.factorExtra,
        PayCategory.extraNocturna => reglas.factorExtra * reglas.factorNocturno,
        PayCategory.exceso => reglas.factorExceso,
        PayCategory.excesoNocturna => reglas.factorExceso * reglas.factorNocturno,
        PayCategory.feriada => reglas.factorFeriado,
        PayCategory.descanso => reglas.factorDescanso,
      };

  double _horas(List<SessionPayReport> reports, Set<PayCategory> cats) =>
      reports.fold(0.0, (acc, r) => acc +
          r.lineas
              .where((l) => cats.contains(l.categoria))
              .fold(0.0, (a, l) => a + l.horas));

  double _horasNocturnas(List<SessionPayReport> reports) =>
      reports.fold(0.0, (acc, r) => acc +
          r.lineas
              .where((l) => l.categoria.esNocturna)
              .fold(0.0, (a, l) => a + l.horas));

  /// Minutos de la sesión que ocurren en el día calendario [dia].
  int _minutosEnDia(DateTime inicio, DateTime? fin, DateTime dia) {
    final finDia = dia
        .add(const Duration(days: 1));
    final hasta = (fin == null || fin.isAfter(finDia)) ? finDia : fin;
    final desde = inicio.isBefore(dia) ? dia : inicio;
    if (!hasta.isAfter(desde)) return 0;
    return hasta.difference(desde).inMinutes;
  }

  bool _mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}