import 'package:logging/logging.dart';
import 'package:sqflite/sqflite.dart';

import './schema.dart';

class DatabaseService {
  DatabaseService();

  // late final Database _db;
  Database? _db;
  final _log = Logger('DatabaseService');

  Future<Database> getDatabase() async {
    return _db ??= await openDatabase(
      dbname,
      version: dbversion,
      onCreate: (db, version) async {
        _log.fine('onCreate:$db, $version');
        // foreign keys not recognized
        await db.execute(fgkeyPragma);
        await db.execute(channelSchema);
        await db.execute(episodeSchema);
        await db.execute(settingsSchema);
        await db.execute(defaultSettings);
      },
    );
  }

  Future<void> execute(String sql, [List<Object?>? args]) async {
    try {
      final db = await getDatabase();
      return await db.execute(sql, args);
    } on Exception catch (e) {
      _log.info(e.toString());
      rethrow;
    }
  }

  Future<List<Map<String, Object?>>> queryAll(
    String sql, [
    List<Object?>? args,
  ]) async {
    try {
      final db = await getDatabase();
      return await db.rawQuery(sql, args);
    } on Exception catch (e) {
      _log.info(e.toString());
      rethrow;
    }
  }

  Future<Map<String, Object?>?> query(String sql, [List<Object?>? args]) async {
    try {
      final db = await getDatabase();
      final res = await db.rawQuery(sql, args);
      return res.isNotEmpty ? res.first : null;
    } on Exception catch (e) {
      _log.info(e.toString());
      rethrow;
    }
  }

  Future<int> insert(String sql, [List<Object?>? args]) async {
    try {
      final db = await getDatabase();
      return await db.rawInsert(sql, args);
    } on Exception catch (e) {
      _log.info(e.toString());
      rethrow;
    }
  }

  Future<int> update(String sql, [List<Object?>? args]) async {
    try {
      final db = await getDatabase();
      return await db.rawUpdate(sql, args);
    } on Exception catch (e) {
      _log.info(e.toString());
      rethrow;
    }
  }

  Future<int> delete(String sql, [List<Object?>? args]) async {
    try {
      final db = await getDatabase();
      return await db.rawDelete(sql, args);
    } on Exception catch (e) {
      _log.info(e.toString());
      rethrow;
    }
  }
}
