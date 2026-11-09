import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import 'local_store.dart';

/// SQLite en el almacenamiento privado de la app (no se respalda:
/// `allowBackup=false`). Dos tablas: caché de lecturas y cola de salida.
class SqfliteLocalStore implements LocalStore {
  SqfliteLocalStore._(this._db);
  final Database _db;

  static const _version = 1;

  static Future<SqfliteLocalStore> open({String name = 'nexo_local.db'}) async {
    final db = await openDatabase(
      p.join(await getDatabasesPath(), name),
      version: _version,
      onCreate: (db, v) async {
        await db.execute('''
          CREATE TABLE http_cache(
            account TEXT NOT NULL,
            key TEXT NOT NULL,
            body TEXT NOT NULL,
            etag TEXT,
            saved_at INTEGER NOT NULL,
            PRIMARY KEY(account, key)
          )''');
        await db.execute('CREATE INDEX ix_cache_saved ON http_cache(account, saved_at)');
        await db.execute('''
          CREATE TABLE outbox(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            account TEXT NOT NULL,
            method TEXT NOT NULL,
            path TEXT NOT NULL,
            body TEXT NOT NULL,
            idem TEXT NOT NULL UNIQUE,
            created_at INTEGER NOT NULL,
            attempts INTEGER NOT NULL DEFAULT 0
          )''');
      },
    );
    return SqfliteLocalStore._(db);
  }

  @override
  Future<CachedResponse?> read(String account, String key) async {
    final r = await _db.query('http_cache', where: 'account = ? AND key = ?', whereArgs: [account, key], limit: 1);
    if (r.isEmpty) return null;
    return CachedResponse(
      body: r.first['body']! as String,
      etag: r.first['etag'] as String?,
      savedAt: DateTime.fromMillisecondsSinceEpoch(r.first['saved_at']! as int),
    );
  }

  @override
  Future<void> write(String account, String key, CachedResponse r) async {
    if (r.body.length > LocalStore.maxBodyBytes) return;
    await _db.insert(
      'http_cache',
      {'account': account, 'key': key, 'body': r.body, 'etag': r.etag, 'saved_at': r.savedAt.millisecondsSinceEpoch},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await _db.rawDelete('''
      DELETE FROM http_cache WHERE account = ? AND key NOT IN (
        SELECT key FROM http_cache WHERE account = ? ORDER BY saved_at DESC LIMIT ?
      )''', [account, account, LocalStore.maxEntries]);
  }

  @override
  Future<int> enqueue(OutboxItem item) async {
    final existing = await _db.query('outbox', columns: ['id'], where: 'idem = ?', whereArgs: [item.idempotencyKey]);
    if (existing.isNotEmpty) return existing.first['id']! as int;
    return _db.insert('outbox', {
      'account': item.account,
      'method': item.method,
      'path': item.path,
      'body': item.body,
      'idem': item.idempotencyKey,
      'created_at': item.createdAt.millisecondsSinceEpoch,
      'attempts': item.attempts,
    });
  }

  @override
  Future<List<OutboxItem>> pending(String account) async {
    final rows = await _db.query('outbox', where: 'account = ?', whereArgs: [account], orderBy: 'id');
    return [
      for (final r in rows)
        OutboxItem(
          id: r['id']! as int,
          account: r['account']! as String,
          method: r['method']! as String,
          path: r['path']! as String,
          body: r['body']! as String,
          idempotencyKey: r['idem']! as String,
          createdAt: DateTime.fromMillisecondsSinceEpoch(r['created_at']! as int),
          attempts: r['attempts']! as int,
        ),
    ];
  }

  @override
  Future<void> removeOutbox(int id) => _db.delete('outbox', where: 'id = ?', whereArgs: [id]);

  @override
  Future<void> bumpAttempt(int id) => _db.rawUpdate('UPDATE outbox SET attempts = attempts + 1 WHERE id = ?', [id]);

  @override
  Future<void> purgeAccount(String account) async {
    await _db.delete('http_cache', where: 'account = ?', whereArgs: [account]);
    await _db.delete('outbox', where: 'account = ?', whereArgs: [account]);
  }
}
