import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:libsignal/libsignal.dart';

/// Cifra la copia que permite ver contenido sin conexión (spec 051). La llave
/// vive en el almacenamiento seguro del teléfono.
abstract class SnapshotCipher {
  /// Nombre estable e ilegible para una consulta (puede llevar coordenadas).
  Future<String> label(String key, String account);
  Future<String> seal(String plain, String aad);
  Future<String> open(String sealed, String aad);
}

class DeviceSnapshotCipher implements SnapshotCipher {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true, sharedPreferencesName: 'nexo_snapshot_key'),
  );
  Future<Uint8List>? _key;

  Future<Uint8List> _loadKey() => _key ??= () async {
    try {
      await LibSignal.init();
      var saved = await _storage.read(key: 'snapshot_v1');
      if (saved == null) {
        saved = base64Encode(_random(32));
        await _storage.write(key: 'snapshot_v1', value: saved);
      }
      return base64Decode(saved);
    } catch (_) {
      _key = null;
      rethrow;
    }
  }();

  static Uint8List _random(int length) {
    final random = Random.secure();
    return Uint8List.fromList(List.generate(length, (_) => random.nextInt(256)));
  }

  Future<Uint8List> _encrypt(String plain, List<int> nonce, String aad) async {
    final cipher = Aes256GcmSiv(key: (await _loadKey()).toList());
    try {
      return Uint8List.fromList(
        cipher.encrypt(plaintext: utf8.encode(plain), nonce: nonce, associatedData: utf8.encode(aad)),
      );
    } finally {
      cipher.dispose();
    }
  }

  // AES-GCM-SIV tolera un nonce fijo cuando se quiere un resultado repetible:
  // solo revela si dos consultas son iguales.
  @override
  Future<String> label(String key, String account) async =>
      base64Url.encode(await _encrypt(key, List.filled(12, 0), 'nexo-snapshot-label:$account'));

  @override
  Future<String> seal(String plain, String aad) async {
    final nonce = _random(12);
    return base64Encode([...nonce, ...await _encrypt(plain, nonce, 'nexo-snapshot:$aad')]);
  }

  @override
  Future<String> open(String sealed, String aad) async {
    final bytes = base64Decode(sealed);
    final cipher = Aes256GcmSiv(key: (await _loadKey()).toList());
    try {
      return utf8.decode(
        cipher.decrypt(
          ciphertext: bytes.sublist(12),
          nonce: bytes.sublist(0, 12),
          associatedData: utf8.encode('nexo-snapshot:$aad'),
        ),
      );
    } finally {
      cipher.dispose();
    }
  }
}
