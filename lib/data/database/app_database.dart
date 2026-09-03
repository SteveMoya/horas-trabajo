import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Base de datos SQLite local (almacenamiento 100% en el dispositivo).
class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  static const _nombreDb = 'horas_trabajo.db';
  static const _version = 2;

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _abrir();
    return _db!;
  }

  Future<Database> _abrir() async {
    final dir = await getDatabasesPath();
    final path = join(dir, _nombreDb);
    return openDatabase(
      path,
      version: _version,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE sesiones (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            inicio TEXT NOT NULL,
            fin TEXT,
            latitud REAL,
            longitud REAL,
            nota TEXT NOT NULL DEFAULT '',
            esFeriado INTEGER NOT NULL DEFAULT 0,
            esDescansoSemanal INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_sesiones_inicio ON sesiones(inicio)',
        );
        await _crearTablaAusencias(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await _crearTablaAusencias(db);
        }
      },
    );
  }

  Future<void> _crearTablaAusencias(Database db) async {
    await db.execute('''
      CREATE TABLE ausencias (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fechaInicio TEXT NOT NULL,
        fechaFin TEXT NOT NULL,
        tipo TEXT NOT NULL,
        nota TEXT NOT NULL DEFAULT ''
      )
    ''');
    await db.execute(
      'CREATE INDEX idx_ausencias_fechaInicio ON ausencias(fechaInicio)',
    );
  }
}