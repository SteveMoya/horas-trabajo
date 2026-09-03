import 'package:horas_trabajo/data/database/app_database.dart';
import 'package:horas_trabajo/data/models/ausencia.dart';

/// Repositorio de vacaciones/permisos/licencias sobre SQLite.
class AusenciasRepository {
  final AppDatabase _database = AppDatabase.instance;

  Future<List<Ausencia>> obtenerTodas() async {
    final db = await _database.database;
    final rows = await db.query('ausencias', orderBy: 'fechaInicio DESC');
    return rows.map(Ausencia.fromMap).toList();
  }

  Future<Ausencia> insertar(Ausencia ausencia) async {
    final db = await _database.database;
    final map = ausencia.toMap()..remove('id');
    final id = await db.insert('ausencias', map);
    return ausencia.copyWith(id: id);
  }

  Future<void> eliminar(int id) async {
    final db = await _database.database;
    await db.delete('ausencias', where: 'id = ?', whereArgs: [id]);
  }
}
