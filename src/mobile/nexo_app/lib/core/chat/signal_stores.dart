import 'dart:convert';
import 'dart:typed_data';
import 'package:libsignal/libsignal.dart';

/// Only instantiate inside ChatVault.transaction; all callback writes commit together.
class SignalStores implements SessionStore, IdentityKeyStore, PreKeyStore, SignedPreKeyStore, KyberPreKeyStore {
  SignalStores(this.state);
  final Map<String, String> state;
  String address(ProtocolAddress a) => '${a.name()}:${a.deviceId()}';
  List<int> ids(String prefix) =>
      state.keys.where((k) => k.startsWith('$prefix:')).map((k) => int.parse(k.substring(prefix.length + 1))).toList();
  Uint8List? read(String key) => state[key] == null ? null : base64Decode(state[key]!);
  Future<void> write(String key, List<int> bytes) async {
    state[key] = base64Encode(bytes);
  }

  @override
  Future<IdentityKeyPair> getIdentityKeyPair() async => IdentityKeyPair.deserialize(bytes: read('identity')!);
  @override
  Future<int> getLocalRegistrationId() async => int.parse(state['registration']!);
  @override
  Future<PublicKey?> getIdentity(ProtocolAddress a) async => switch (read('peer:${address(a)}')) {
    final Uint8List b => PublicKey.deserialize(bytes: b),
    _ => null,
  };
  @override
  Future<bool> saveIdentity(ProtocolAddress a, PublicKey key) async {
    final k = 'peer:${address(a)}';
    final value = base64Encode(key.serialize());
    final old = state[k];
    if (old != null && old != value) {
      return false; // Keep the pinned key; libsignal enforces trust through getIdentity.
    }
    state[k] = value;
    return old == null;
  }

  @override
  Future<bool> isTrustedIdentity(ProtocolAddress a, PublicKey key, Direction direction) async =>
      state['peer:${address(a)}'] == null || state['peer:${address(a)}'] == base64Encode(key.serialize());
  @override
  Future<SessionRecord?> loadSession(ProtocolAddress a) async => switch (read('session:${address(a)}')) {
    final Uint8List b => SessionRecord.deserialize(bytes: b),
    _ => null,
  };
  @override
  Future<void> storeSession(ProtocolAddress a, SessionRecord record) =>
      write('session:${address(a)}', record.serialize());
  @override
  Future<bool> containsSession(ProtocolAddress a) async => state.containsKey('session:${address(a)}');
  @override
  Future<void> deleteSession(ProtocolAddress a) async {
    state.remove('session:${address(a)}');
  }

  @override
  Future<void> deleteAllSessions(String name) async {
    state.removeWhere((k, v) => k.startsWith('session:$name:'));
  }

  @override
  Future<List<int>> getSubDeviceSessions(String name) async => ids('session:$name');

  @override
  Future<PreKeyRecord?> loadPreKey(int id) async => switch (read('pre:$id')) {
    final Uint8List b => PreKeyRecord.deserialize(bytes: b),
    _ => null,
  };
  @override
  Future<void> storePreKey(int id, PreKeyRecord record) => write('pre:$id', record.serialize());
  @override
  Future<bool> containsPreKey(int id) async => state.containsKey('pre:$id');
  @override
  Future<void> removePreKey(int id) async {
    state.remove('pre:$id');
  }

  @override
  Future<List<int>> getAllPreKeyIds() async => ids('pre');

  @override
  Future<SignedPreKeyRecord?> loadSignedPreKey(int id) async => switch (read('signed:$id')) {
    final Uint8List b => SignedPreKeyRecord.deserialize(bytes: b),
    _ => null,
  };
  @override
  Future<void> storeSignedPreKey(int id, SignedPreKeyRecord record) => write('signed:$id', record.serialize());
  @override
  Future<bool> containsSignedPreKey(int id) async => state.containsKey('signed:$id');
  @override
  Future<void> removeSignedPreKey(int id) async {
    state.remove('signed:$id');
  }

  @override
  Future<List<int>> getAllSignedPreKeyIds() async => ids('signed');

  @override
  Future<KyberPreKeyRecord?> loadKyberPreKey(int id) async => switch (read('kyber:$id')) {
    final Uint8List b => KyberPreKeyRecord.deserialize(bytes: b),
    _ => null,
  };
  @override
  Future<void> storeKyberPreKey(int id, KyberPreKeyRecord record) => write('kyber:$id', record.serialize());
  @override
  Future<bool> containsKyberPreKey(int id) async => state.containsKey('kyber:$id');
  @override
  Future<void> removeKyberPreKey(int id) async {
    state.remove('kyber:$id');
  }

  @override
  Future<List<int>> getAllKyberPreKeyIds() async => ids('kyber');

  @override
  Future<bool> markKyberPreKeyUsed(int kyber, int signed, PublicKey base) async {
    final key = 'agreement:$kyber:$signed:${base64Encode(base.serialize())}';
    if (state.containsKey(key)) return false;
    state[key] = '1';
    return true; // Last-resort Kyber key; consumed agreement remains durable.
  }
}
