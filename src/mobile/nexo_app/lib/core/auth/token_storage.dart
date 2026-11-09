import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'auth_tokens.dart';

/// Tokens en almacenamiento seguro (Keystore en Android). Nunca se guarda la
/// contraseña ni el código de verificación (spec 004).
class TokenStorage {
  TokenStorage([FlutterSecureStorage? storage])
      : _s = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _s;

  static const _kAccess = 'nexo.access';
  static const _kRefresh = 'nexo.refresh';
  static const _kExpires = 'nexo.expiresAt';
  static const _kName = 'nexo.name';
  static const _kMode = 'nexo.mode';
  static const _kDevice = 'nexo.deviceId';
  static const _kPushAsked = 'nexo.pushAsked';

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

  /// Ya se mostró la pantalla previa al permiso de notificaciones.
  Future<bool> readPushAsked() async => await _s.read(key: _kPushAsked) == '1';
  Future<void> writePushAsked() => _s.write(key: _kPushAsked, value: '1');

  /// Logout: borra todo lo de la cuenta en este dispositivo.
  Future<void> clear() => _s.deleteAll();
}

final tokenStorageProvider = Provider<TokenStorage>((ref) => TokenStorage());
