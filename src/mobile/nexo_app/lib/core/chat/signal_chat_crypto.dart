import 'dart:convert';
import 'package:flutter/foundation.dart' show mapEquals;
import 'dart:math';
import 'dart:typed_data';
import 'package:libsignal/libsignal.dart';
import 'chat_vault.dart';
import 'signal_stores.dart';

class SignalChatCrypto {
  SignalChatCrypto(this.vault, this.account, this.deviceId);
  final ChatVault vault;
  final String account;
  final int deviceId;
  ProtocolAddress get address => ProtocolAddress(name: account, deviceId: deviceId);
  Future<Map<int, String>> securityNumbers(String peerAccount) => vault.transaction((state) async {
    final stores = SignalStores(state);
    final identity = await stores.getIdentityKeyPair();
    final result = <int, String>{};
    for (final entry in state.entries.where((e) => e.key.startsWith('peer:$peerAccount:'))) {
      final device = int.parse(entry.key.split(':').last);
      final fingerprint = Fingerprint(
        iterations: 5200,
        version: 1,
        localIdentifier: utf8.encode('$account:$deviceId'),
        localPublicKey: identity.publicKey.toList(),
        remoteIdentifier: utf8.encode('$peerAccount:$device'),
        remotePublicKey: base64Decode(entry.value).toList(),
      );
      result[device] = fingerprint.displayString();
    }
    return result;
  });

  Future<Map<String, dynamic>> publicBundle() => vault.transaction((state) async {
    final store = SignalStores(state);
    if (!state.containsKey('identity')) {
      final identity = IdentityKeyPair.generate();
      state['identity'] = base64Encode(identity.serialize());
      state['registration'] = '${1 + Random.secure().nextInt(16380)}';
      final signed = PrivateKey.generate();
      final pub = signed.getPublicKey();
      await store.storeSignedPreKey(
        1,
        SignedPreKeyRecord(
          id: 1,
          timestamp: BigInt.from(DateTime.now().millisecondsSinceEpoch),
          publicKey: pub,
          privateKey: signed,
          signature: identity.sign(message: pub.serialize().toList()),
        ),
      );
      final kyber = KyberKeyPair.generate();
      await store.storeKyberPreKey(
        1,
        KyberPreKeyRecord.create(
          id: 1,
          timestamp: BigInt.from(DateTime.now().millisecondsSinceEpoch),
          keyPair: kyber,
          signature: identity.sign(message: kyber.getPublicKey().serialize().toList()),
        ),
      );
      for (var i = 1; i <= 100; i++) {
        final private = PrivateKey.generate();
        await store.storePreKey(i, PreKeyRecord(id: i, publicKey: private.getPublicKey(), privateKey: private));
      }
    }
    final identity = await store.getIdentityKeyPair();
    final signed = (await store.loadSignedPreKey(1))!;
    final kyber = (await store.loadKyberPreKey(1))!;
    return {
      'deviceId': deviceId,
      'registrationId': await store.getLocalRegistrationId(),
      'identityKey': base64Encode(identity.publicKey),
      'signedPreKeyId': 1,
      'signedPreKey': base64Encode(signed.publicKey()),
      'signature': base64Encode(signed.signature()),
      'kyberPreKeyId': 1,
      'kyberPreKey': base64Encode(kyber.getPublicKey().serialize()),
      'kyberSignature': base64Encode(kyber.signature()),
      'oneTimeKeys': [
        for (final id in await store.getAllPreKeyIds())
          {'id': id, 'publicKey': base64Encode((await store.loadPreKey(id))!.publicKey())},
      ],
    };
  });
  Future<Map<String, dynamic>> encrypt({
    required String conversation,
    required String messageId,
    required String recipient,
    required int recipientDevice,
    required Map<String, dynamic> content,
    Map<String, dynamic>? bundle,
  }) => vault.transaction((state) async {
    final pending = 'out:$messageId:$recipient:$recipientDevice';
    if (state[pending] case final String saved) {
      final old = jsonDecode(saved) as Map<String, dynamic>;
      if (old['conversation'] != conversation || old['content'] != jsonEncode(content)) {
        throw StateError('Identificador reutilizado');
      }
      return Map<String, dynamic>.from(old['envelope'] as Map);
    }
    final stores = SignalStores(state);
    final peer = ProtocolAddress(name: recipient, deviceId: recipientDevice);
    if (!await stores.containsSession(peer)) {
      if (bundle == null || bundle['deviceId'] != recipientDevice) throw StateError('Faltan claves del destinatario');
      final key = bundle['oneTimeKey'] as Map;
      await SessionBuilder(localAddress: address, sessionStore: stores, identityKeyStore: stores).processPreKeyBundle(
        peer,
        PreKeyBundle(
          registrationId: bundle['registrationId'] as int,
          deviceId: recipientDevice,
          preKeyId: key['id'] as int,
          preKeyPublic: base64Decode(key['publicKey'] as String),
          signedPreKeyId: bundle['signedPreKeyId'] as int,
          signedPreKeyPublic: base64Decode(bundle['signedPreKey'] as String),
          signedPreKeySignature: base64Decode(bundle['signature'] as String),
          identityKey: base64Decode(bundle['identityKey'] as String),
          kyberPreKeyId: bundle['kyberPreKeyId'] as int,
          kyberPreKeyPublic: base64Decode(bundle['kyberPreKey'] as String),
          kyberPreKeySignature: base64Decode(bundle['kyberSignature'] as String),
        ),
      );
    }
    final plain = Uint8List.fromList(
      utf8.encode(
        jsonEncode({
          'v': 1,
          'conversation': conversation,
          'messageId': messageId,
          'sender': account,
          'senderDevice': deviceId,
          'recipient': recipient,
          'recipientDevice': recipientDevice,
          'content': content,
        }),
      ),
    );
    try {
      final encrypted = await cipher(stores).encrypt(peer, plain);
      final envelope = <String, dynamic>{
        'version': 1,
        'messageId': messageId,
        'senderDevice': deviceId,
        'recipient': recipient,
        'recipientDevice': recipientDevice,
        'messageType': encrypted.type.value,
        'ciphertext': base64Encode(encrypted.ciphertext),
      };
      state[pending] = jsonEncode({'conversation': conversation, 'content': jsonEncode(content), 'envelope': envelope});
      return envelope;
    } finally {
      plain.fillRange(0, plain.length, 0);
    }
  });
  Future<Map<String, dynamic>> decrypt({
    required String conversation,
    required String sender,
    required Map<String, dynamic> envelope,
  }) => vault.transaction((state) async {
    if (envelope['version'] != 1 ||
        envelope['recipient'] != account ||
        envelope['recipientDevice'] != deviceId ||
        ![2, 3].contains(envelope['messageType'])) {
      throw StateError('Sobre cifrado invalido');
    }
    final raw = envelope['ciphertext'];
    if (raw is! String || raw.length < 32 || raw.length > 65536) throw StateError('Mensaje privado invalido');
    final id = envelope['messageId'] as String;
    final cached = 'in:$sender:$id';
    final wire = jsonEncode(envelope);
    if (state[cached] case final String saved) {
      final old = jsonDecode(saved) as Map<String, dynamic>;
      if (old['conversation'] != conversation ||
          !mapEquals(jsonDecode(old['wire'] as String) as Map<String, dynamic>, envelope)) {
        throw StateError('Mensaje repetido alterado');
      }
      return Map<String, dynamic>.from(old['content'] as Map);
    }
    final stores = SignalStores(state);
    final plain = await cipher(stores).decrypt(
      ProtocolAddress(name: sender, deviceId: envelope['senderDevice'] as int),
      CiphertextMessage.fromRaw(
        messageType: envelope['messageType'] as int,
        ciphertext: base64Decode(envelope['ciphertext'] as String),
      ),
    );
    try {
      final body = jsonDecode(utf8.decode(plain)) as Map<String, dynamic>;
      if (body['v'] != 1 ||
          body['conversation'] != conversation ||
          body['messageId'] != id ||
          body['sender'] != sender ||
          body['senderDevice'] != envelope['senderDevice'] ||
          body['recipient'] != account ||
          body['recipientDevice'] != deviceId) {
        throw StateError('La identidad o conversacion no coincide');
      }
      final content = Map<String, dynamic>.from(body['content'] as Map);
      if (!['text', 'image', 'audio'].contains(content['kind']) ||
          (content['kind'] == 'text' && content['text'] is! String) ||
          (content['text'] != null && (content['text'] is! String || (content['text'] as String).length > 1000))) {
        throw StateError('Contenido privado no compatible');
      }
      state[cached] = jsonEncode({'conversation': conversation, 'wire': wire, 'content': content});
      return content;
    } finally {
      plain.fillRange(0, plain.length, 0);
    }
  });
  SessionCipher cipher(SignalStores stores) => SessionCipher(
    localAddress: address,
    sessionStore: stores,
    identityKeyStore: stores,
    preKeyStore: stores,
    signedPreKeyStore: stores,
    kyberPreKeyStore: stores,
  );
}
