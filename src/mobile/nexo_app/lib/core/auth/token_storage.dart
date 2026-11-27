import 'package:sqflite/sqflite.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_tokens.dart';

/// Tokens en almacenamiento seguro (Keystore en Android). Nunca se guarda la
/// contraseña ni el código de verificación (spec 004).
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
    : _s =
          storage ??
          const FlutterSecureStorage(aOptions: AndroidOptions(sharedPreferencesName: 'FlutterSecureStorage'));

  final FlutterSecureStorage _s;

  static const _kAccess = 'nexo.access';
  static const _kRefresh = 'nexo.refresh';
  static const _kExpires = 'nexo.expiresAt';
  static const _kName = 'nexo.name';
  static const _kMode = 'nexo.mode';
  static const _kDevice = 'nexo.deviceId';
  static const _kPushAsked = 'nexo.pushAsked';
  static const _kPushOff = 'nexo.pushOff';

  Future<AuthTokens?> read() async {
    final a = await _s.read(key: _kAccess);
    final r = await _s.read(key: _kRefresh);
    if (a == null || r == null || r.isEmpty) return null;
    final e = int.tryParse(await _s.read(key: _kExpires) ?? '');
    return AuthTokens(
      accessToken: a,
      refreshToken: r,
      expiresAt: e == null ? DateTime.now() : DateTime.fromMillisecondsSinceEpoch(e),
    );
  }

  Future<void> write(AuthTokens t) async {
    await _s.write(key: _kAccess, value: t.accessToken);
    await _s.write(key: _kRefresh, value: t.refreshToken);
    await _s.write(key: _kExpires, value: '${t.expiresAt.millisecondsSinceEpoch}');
  }

  /// Serializes rotating refresh tokens across the UI and FCM isolates.
  /// Re-read after acquiring the lock: a previous request may already have
  /// rotated credentials, signed out or changed accounts.
  Future<AuthTokens?> refreshCoordinated(
    AuthTokens expected,
    Future<AuthTokens?> Function(String refreshToken) refresh,
  ) async {
    final directory = await getDatabasesPath();
    final database = await openDatabase(
      '$directory/session-refresh-lock.db',
      singleInstance: false,
      onConfigure: (db) async {
        await db.rawQuery('PRAGMA busy_timeout = 25000');
      },
    );
    try {
      return await database.transaction((transaction) async {
        final current = await read();
        if (current == null) return null;
        if (current.accessToken != expected.accessToken) return current;
        final fresh = await refresh(current.refreshToken);
        final latest = await read();
        if (latest == null || latest.accessToken != current.accessToken) return latest;
        if (fresh != null) await write(fresh);
        return fresh;
      }, exclusive: true);
    } finally {
      await database.close();
    }
  }

  Future<String?> readName() => _s.read(key: _kName);

  Future<void> writeName(String? name) async {
    if (name == null || name.isEmpty) {
      await _s.delete(key: _kName);
    } else {
      await _s.write(key: _kName, value: name);
    }
  }

  /// Modo elegido en la app cuando el backend aún no emite tokens con el
  /// claim nuevo (grupo `cuenta` en datos de prueba).
  Future<String?> readMode() => _s.read(key: _kMode);

  Future<void> writeMode(String? mode) async {
    if (mode == null) {
      await _s.delete(key: _kMode);
    } else {
      await _s.write(key: _kMode, value: mode);
    }
  }

  /// Id del teléfono registrado para push (`POST /v1/identity/devices`).
  /// Se usa al cerrar sesión para dar de baja los avisos. Nunca el token FCM.
  Future<String?> readDeviceId() => _s.read(key: _kDevice);

  Future<void> writeDeviceId(String? id) async {
    if (id == null || id.isEmpty) {
      await _s.delete(key: _kDevice);
    } else {
      await _s.write(key: _kDevice, value: id);
    }
  }

  /// Ya se mostró la pantalla previa al permiso de notificaciones. Es una
  /// decisión del teléfono: no se borra al cerrar sesión.
  Future<bool> readPushAsked() async => await _s.read(key: _kPushAsked) == '1';
  Future<void> writePushAsked() => _s.write(key: _kPushAsked, value: '1');

  /// La persona apagó los avisos desde Cuenta. También se conserva.
  Future<bool> readPushOff() async => await _s.read(key: _kPushOff) == '1';
  Future<void> writePushOff(bool off) => off ? _s.write(key: _kPushOff, value: '1') : _s.delete(key: _kPushOff);

  Future<String?> readChatStyle(String account, String conversation) =>
      _s.read(key: 'nexo.chatStyle.$account.$conversation');
  Future<void> writeChatStyle(String account, String conversation, String style) =>
      _s.write(key: 'nexo.chatStyle.$account.$conversation', value: style);

  Future<String?> readChatRead(String account, String conversation) =>
      _s.read(key: 'nexo.chatRead.$account.$conversation');

  Future<void> writeChatRead(String account, String conversation, String message) =>
      _s.write(key: 'nexo.chatRead.$account.$conversation', value: message);

  /// Logout: borra todo lo de la cuenta en este dispositivo.
  Future<void> clear() async {
    final keys = await _s.readAll();
    for (final key
        in keys.keys.where((key) => key.startsWith('nexo.chatRead.') || key.startsWith('nexo.chatStyle.')).toList()) {
      await _s.delete(key: key);
    }
    for (final key in [_kAccess, _kRefresh, _kExpires, _kName, _kMode, _kDevice]) {
      await _s.delete(key: key);
    }
  }
}

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());
