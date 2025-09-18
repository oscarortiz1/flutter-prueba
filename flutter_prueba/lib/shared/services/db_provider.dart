import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter/services.dart';
import '../models/movement.dart';

class DBProvider {
  static final DBProvider _instance = DBProvider._internal();
  factory DBProvider() => _instance;
  DBProvider._internal();

  Database? _db;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    // sqflite is not supported on web. Fail early with a clear message.
    if (kIsWeb) {
      throw UnsupportedError('sqflite no es compatible con Flutter Web. Ejecuta la app en Android o iOS, o usa una alternativa para web.');
    }

    try {
      final databasesPath = await getDatabasesPath();
      final path = join(databasesPath, 'movements.db');
      return await openDatabase(
        path,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
          CREATE TABLE movements(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            server_id TEXT,
            type TEXT NOT NULL,
            amount REAL NOT NULL,
            description TEXT,
            account_from TEXT NOT NULL,
            account_to TEXT NOT NULL,
            currency TEXT DEFAULT 'PEN',
            status TEXT DEFAULT 'pending',
            reference TEXT,
            value_date TEXT,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            sync_status TEXT DEFAULT 'pending'
          )
        ''');
        },
      );
    } on MissingPluginException catch (e) {
      // Provide a clearer error to help debugging when plugin isn't registered
      throw MissingPluginException('sqflite plugin no está registrado. Asegúrate de parar la app y reinstalarla (full restart). Detalle: ${e.message}');
    }
  }

  Future<int> insertMovement(Movement m) async {
    final db = await database;
    final map = m.toMap();
    // remove id if null to let sqlite autoincrement
    map.remove('id');
    return await db.insert('movements', map);
  }

  Future<List<Movement>> getMovements() async {
    final db = await database;
    final res = await db.query('movements', orderBy: 'created_at DESC');
    return res.map((e) => Movement.fromMap(e)).toList();
  }

  /// Paginated query with optional text filter. `query` will be matched using
  /// SQL LIKE against `description`, `account_from`, `account_to`, and `type`.
  Future<List<Movement>> getMovementsPage(int offset, int limit, {String? query}) async {
    final db = await database;
    if (query == null || query.isEmpty) {
      final res = await db.query('movements', orderBy: 'created_at DESC', limit: limit, offset: offset);
      return res.map((e) => Movement.fromMap(e)).toList();
    }

  final qLike = '%${query.replaceAll('%', '\%')}%';
  final whereClause = '(description LIKE ? OR account_from LIKE ? OR account_to LIKE ? OR type LIKE ?)';
  // args for the WHERE clause, then LIMIT and OFFSET
  final args = [qLike, qLike, qLike, qLike, limit.toString(), offset.toString()];

    // Note: sqflite doesn't support named parameters for limit/offset in the same way,
    // so use rawQuery to ensure limit/offset placement.
    final sql = 'SELECT * FROM movements WHERE $whereClause ORDER BY created_at DESC LIMIT ? OFFSET ?';
    final res = await db.rawQuery(sql, args);
    return res.map((e) => Movement.fromMap(e)).toList();
  }

  Future<List<Movement>> getPendingMovements() async {
    final db = await database;
    final res = await db.query('movements', where: "sync_status IN ('pending','pending_delete')", orderBy: 'created_at ASC');
    return res.map((e) => Movement.fromMap(e)).toList();
  }

  Future<int> updateMovement(Movement m) async {
    final db = await database;
    final map = m.toMap();
    final id = map['id'] as int?;
    if (id == null) throw ArgumentError('Movement id required for update');
    return db.update('movements', map, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> markSynced(int id, String serverId) async {
    final db = await database;
    return db.update('movements', {'sync_status': 'synced', 'server_id': serverId}, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteMovement(int id) async {
    final db = await database;
    return db.delete('movements', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getMovementById(int id) async {
    final db = await database;
    final res = await db.query('movements', where: 'id = ?', whereArgs: [id], limit: 1);
    if (res.isEmpty) return null;
    return res.first;
  }

  /// Mark a movement as pending_delete so the sync process will request deletion on server
  Future<int> markPendingDelete(int id) async {
    final db = await database;
    return db.update('movements', {'sync_status': 'pending_delete'}, where: 'id = ?', whereArgs: [id]);
  }

  /// Remove local movement row permanently
  Future<int> removeLocalMovement(int id) async {
    final db = await database;
    return db.delete('movements', where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getMovementByServerId(String serverId) async {
    final db = await database;
    final res = await db.query('movements', where: 'server_id = ?', whereArgs: [serverId], limit: 1);
    if (res.isEmpty) return null;
    return res.first;
  }

  Future<int> upsertMovement(Map<String, dynamic> map) async {
    final db = await database;
    // try find by server_id
    final serverId = map['server_id'] as String?;
    if (serverId != null) {
      final existing = await db.query('movements', where: 'server_id = ?', whereArgs: [serverId], limit: 1);
      if (existing.isNotEmpty) {
        final id = existing.first['id'] as int;
        map['updated_at'] = DateTime.now().toIso8601String();
        await db.update('movements', map, where: 'id = ?', whereArgs: [id]);
        return id;
      }
    }
    // insert
    return db.insert('movements', map);
  }

  /// Delete all rows from local tables. Used on logout to clear user data.
  Future<void> clearAll() async {
    final db = await database;
    // clear movements table
    await db.delete('movements');
  }

  /// Close and remove the database file from disk. Use with caution.
  Future<void> deleteDatabaseFile() async {
    if (_db != null) {
      await _db!.close();
      _db = null;
    }
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'movements.db');
    // ignore errors when deleting
    try {
      await deleteDatabase(path);
    } catch (e) {
      // ignore
    }
  }
}
