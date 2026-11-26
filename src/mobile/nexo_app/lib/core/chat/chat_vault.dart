import 'package:flutter/foundation.dart' show kDebugMode, debugPrint, mapEquals;
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:libsignal/libsignal.dart';
import 'package:path/path.dart' as paths;
import 'package:sqflite/sqflite.dart';

/// Separate from HTTP cache: a transaction durably commits the complete ratchet
/// and consumed prekeys before any ciphertext or plaintext may leave its scope.
class ChatVault {
  ChatVault._(this._db, this._key, this._account);
  final Database _db;
  final Uint8List _key;
  final String _account;
  static const _marker = MethodChannel('mx.nexolocal/chat-vault');
  static const _secrets = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true, sharedPreferencesName: 'nexo_chat_keys'),
    iOptions: IOSOptions(accountName: 'nexo_chat_keys', accessibility: KeychainAccessibility.first_unlock_this_device),
  );
  static Uint8List randomBytes(int length) {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
  }

  static Future<ChatVault> open(String account) async {
    if (!RegExp(r'^[a-fA-F0-9-]{36}$').hasMatch(account)) throw StateError('Cuenta inv\u00e1lida');
    await LibSignal.init();
    if (kDebugMode) debugPrint('[CHAT] native crypto initialized');
    // Android no_backup marker. Unsupported platforms fail closed until native support is implemented.
    String? marker;
    try {
      marker = await _marker.invokeMethod<String>('installationMarker');
    } on MissingPluginException {
      // Background FCM engine has no Activity. Read only the existing no-backup
      // marker; never create a replacement or reset keys from a push callback.
      if (!Platform.isAndroid) rethrow;
      final support = await getApplicationSupportDirectory();
      final file = File(paths.join(support.parent.path, 'no_backup', 'chat-installation-v1'));
      if (await file.exists()) marker = await file.readAsString();
    }
    if (kDebugMode) debugPrint('[CHAT] installation marker checked');
    if (marker == null) throw StateError('Almacenamiento seguro no disponible');
    final name = 'chat_v1_$account';
    var saved = await _secrets.read(key: name);
    final path = paths.join(await getDatabasesPath(), '$name.db');
    if (saved == null) {
      if (await databaseExists(path)) {
        // A previous failure during onConfigure can leave an empty SQLite file.
        // Reinitialize only if there is no encrypted state to lose.
        final probe = await openDatabase(path, readOnly: true, singleInstance: false);
        var containsState = false;
        try {
          final table = await probe.rawQuery("SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'state'");
          if (table.isNotEmpty) {
            final rows = await probe.rawQuery('SELECT COUNT(*) AS total FROM state');
            containsState = (rows.first['total'] as num) > 0;
          }
        } finally {
          await probe.close();
        }
        if (containsState) {
          if (kDebugMode) debugPrint('[CHAT] encrypted history requires key recovery');
          throw StateError('No se pueden recuperar las claves de este chat');
        }
        if (kDebugMode) debugPrint('[CHAT] recovering empty initialization');
      }
      saved = '$marker:${base64Encode(randomBytes(32))}';
      await _secrets.write(key: name, value: saved);
    }
    final parts = saved.split(':');
    if (parts.length != 2 || parts[0] != marker) {
      if (kDebugMode) debugPrint('[CHAT] installation marker mismatch');
      throw StateError('El almacenamiento del chat fue restaurado; requiere recuperaci\u00f3n');
    }
    final key = base64Decode(parts[1]);
    if (key.length != 32) throw StateError('Clave local inv\u00e1lida');
    final db = await openDatabase(
      path,
      version: 1,
      singleInstance: false,
      onConfigure: (db) async {
        await db.execute('PRAGMA synchronous = FULL');
        await db.rawQuery('PRAGMA journal_mode = DELETE');
        await db.rawQuery('PRAGMA secure_delete = ON');
      },
      onCreate: (db, _) async {
        await db.execute(
          'CREATE TABLE state (id INTEGER PRIMARY KEY CHECK(id = 1), nonce BLOB NOT NULL, ciphertext BLOB NOT NULL)',
        );
      },
    );
    return ChatVault._(db, key, account);
  }

  Future<T> transaction<T>(Future<T> Function(Map<String, String> state) operation) => _db.transaction((tx) async {
    final cipher = Aes256GcmSiv(key: _key.toList());
    final aad = utf8.encode('nexo-chat-vault-v1:$_account');
    try {
      final rows = await tx.query('state', where: 'id = 1');
      Map<String, String> state = {};
      if (rows.isNotEmpty) {
        final row = rows.single;
        final plain = cipher.decrypt(
          ciphertext: (row['ciphertext'] as Uint8List).toList(),
          nonce: (row['nonce'] as Uint8List).toList(),
          associatedData: aad,
        );
        try {
          state = Map<String, String>.from(jsonDecode(utf8.decode(plain)) as Map);
        } finally {
          plain.fillRange(0, plain.length, 0);
        }
      }
      final initial = Map<String, String>.from(state);
      final result = await operation(state);
      if (mapEquals(initial, state)) return result;
      final nonce = randomBytes(12);
      final plain = Uint8List.fromList(utf8.encode(jsonEncode(state)));
      try {
        final ciphertext = cipher.encrypt(plaintext: plain.toList(), nonce: nonce.toList(), associatedData: aad);
        await tx.insert('state', {
          'id': 1,
          'nonce': nonce,
          'ciphertext': ciphertext,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      } finally {
        plain.fillRange(0, plain.length, 0);
      }
      return result;
    } finally {
      cipher.dispose();
    }
  }, exclusive: true);

  Future<void> close() async {
    await _db.close();
    _key.fillRange(0, _key.length, 0);
  }
}
