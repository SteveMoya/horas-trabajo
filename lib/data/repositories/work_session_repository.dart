import 'package:horas_trabajo/data/database/app_database.dart';
import 'package:horas_trabajo/data/models/work_session.dart';

/// Repositorio de sesiones de trabajo sobre SQLite.
class WorkSessionRepository {
  final AppDatabase _database = AppDatabase.instance;

  Future<List<WorkSession>> obtenerTodas() async {
    final db = await _database.database;
    final rows = await db.query('sesiones', orderBy: 'inicio DESC');
    return rows.map(WorkSession.fromMap).toList();
  }

  /// Sesiones dentro del rango [desde, hasta] (incluyendo por solapamiento
  /// con el inicio de la sesión).
  Future<List<WorkSession>> obtenerEnRango(
    DateTime desde,
    DateTime hasta,
  ) async {
    final db = await _database.database;
    final rows = await db.query(
      'sesiones',
      where: 'inicio >= ? AND inicio < ?',
      whereArgs: [desde.toIso8601String(), hasta.toIso8601String()],
      orderBy: 'inicio ASC',
    );
    return rows.map(WorkSession.fromMap).toList();
  }

  Future<WorkSession?> obtenerEnProgreso() async {
    final db = await _database.database;
    final rows = await db.query(
      'sesiones',
      where: 'fin IS NULL',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return WorkSession.fromMap(rows.first);
  }

  Future<WorkSession> insertar(WorkSession sesion) async {
    final db = await _database.database;
    final id = await db.insert('sesiones', sesion.toMap());
    return sesion.copyWith(id: id);
  }

  Future<void> actualizar(WorkSession sesion) async {
    final db = await _database.database;
    await db.update(
      'sesiones',
      sesion.toMap(),
      where: 'id = ?',
      whereArgs: [sesion.id],
    );
  }

  Future<void> eliminar(int id) async {
    final db = await _database.database;
    await db.delete('sesiones', where: 'id = ?', whereArgs: [id]);
  }
}