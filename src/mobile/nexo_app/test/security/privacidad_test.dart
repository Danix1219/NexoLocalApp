import 'dart:io';
import 'package:nexo_app/core/local/file_cache.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/services.dart';
import 'package:nexo_app/core/chat/chat_vault.dart';
import 'package:nexo_app/core/chat/signal_chat_crypto.dart';
import 'package:nexo_app/core/chat/encrypted_chat_transport.dart';
import 'dart:convert';
import 'package:libsignal/libsignal.dart';
import 'package:nexo_app/core/chat/signal_stores.dart';
import 'package:nexo_app/data/models.dart';
import 'package:dio/dio.dart';
import 'package:nexo_app/core/local/offline_interceptor.dart';
import 'package:nexo_app/core/widgets/ui.dart';
import 'package:nexo_app/data/nexo_api.dart';
import 'package:nexo_app/data/http_nexo_api.dart';
import 'package:nexo_app/core/network/api_exception.dart';
import '../support/mock_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/core/auth/session_controller.dart';
import 'package:nexo_app/core/auth/token_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../support/fake_api.dart';
import '../support/fixtures.dart';

const testIdempotencyKey = 'profile-test';

/// Spec 039/041/046 · H01/H02 y aislamiento por cuenta.
class AttachmentTestVault implements ChatVault {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class CachedHistoryVault implements ChatVault {
  final state = <String, String>{};
  @override
  Future<T> transaction<T>(Future<T> Function(Map<String, String>) operation) => operation(state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('cached private history accepts reordered JSON but rejects modified ciphertext', () async {
    final vault = CachedHistoryVault();
    final envelope = <String, dynamic>{
      'version': 1,
      'recipient': 'me',
      'recipientDevice': 1,
      'messageType': 2,
      'messageId': 'operation',
      'senderDevice': 1,
      'ciphertext': 'A' * 32,
    };
    vault.state['in:peer:operation'] = jsonEncode({
      'conversation': 'conversation',
      'wire': jsonEncode(envelope),
      'content': {'kind': 'text', 'text': 'Historial conservado'},
    });
    final crypto = SignalChatCrypto(vault, 'me', 1);
    final reordered = Map<String, dynamic>.fromEntries(envelope.entries.toList().reversed);
    expect(
      (await crypto.decrypt(conversation: 'conversation', sender: 'peer', envelope: reordered))['text'],
      'Historial conservado',
    );
    await expectLater(
      crypto.decrypt(conversation: 'conversation', sender: 'peer', envelope: {...reordered, 'ciphertext': 'B' * 32}),
      throwsStateError,
    );
    await expectLater(crypto.decrypt(conversation: 'other', sender: 'peer', envelope: reordered), throwsStateError);
  });
  test('vault recovers only empty initialization and preserves encrypted history without its key', () async {
    databaseFactory = databaseFactorySqflitePlugin;
    const dbChannel = MethodChannel('com.tekartik.sqflite');
    const markerChannel = MethodChannel('mx.nexolocal/chat-vault');
    final messenger = TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    messenger.setMockMethodCallHandler(markerChannel, (_) async => '12345678-1234-4234-8234-123456789012');
    var encryptedRows = 0;
    final calls = <String>[];
    messenger.setMockMethodCallHandler(dbChannel, (call) async {
      final args = call.arguments is Map ? call.arguments as Map : const {};
      final sql = args['sql']?.toString() ?? '';
      calls.add('${call.method}:$sql');
      if (call.method == 'getDatabasesPath') return '/vault-test';
      if (call.method == 'databaseExists') return true;
      if (call.method == 'openDatabase') return {'id': 71};
      if (call.method == 'query') {
        if (sql.contains('sqlite_master')) {
          return [
            {'name': 'state'},
          ];
        }
        if (sql.contains('COUNT(*)')) {
          return [
            {'total': encryptedRows},
          ];
        }
        if (sql.contains('user_version')) {
          return [
            {'user_version': 1},
          ];
        }
        return <Map<String, dynamic>>[];
      }
      return null;
    });
    addTearDown(() {
      messenger.setMockMethodCallHandler(dbChannel, null);
      messenger.setMockMethodCallHandler(markerChannel, null);
    });
    FlutterSecureStorage.setMockInitialValues({});
    final empty = await ChatVault.open('10000000-0000-4000-8000-000000000001');
    expect(await empty.transaction((state) async => state.length), 0);
    expect(calls.any((call) => call.startsWith('insert:')), isFalse);
    await empty.close();
    encryptedRows = 1;
    FlutterSecureStorage.setMockInitialValues({});
    await expectLater(ChatVault.open('10000000-0000-4000-8000-000000000002'), throwsStateError);
    expect(calls.where((c) => c.startsWith('deleteDatabase:') || c.contains('DELETE FROM')), isEmpty);
  });
  test(
    'private photo and voice attachments roundtrip as ciphertext and reject tampering or a different chat',
    () async {
      await LibSignal.init();
      Uint8List? stored;
      final adapter = MockAdapter();
      adapter.fallback = (request) {
        if (request.method == 'PUT') {
          stored = Uint8List.fromList(request.data as Uint8List);
          expect(request.contentType, 'application/octet-stream');
          return ResponseBody.fromString('', 204);
        }
        return ResponseBody.fromBytes(
          stored!,
          200,
          headers: {
            'content-type': ['application/octet-stream'],
          },
        );
      };
      final transport = EncryptedChatTransport(testDio(adapter), SignalChatCrypto(AttachmentTestVault(), 'account', 1));
      final bytes = Uint8List.fromList(List.generate(1024, (i) => i % 256));
      for (final type in ['image/jpeg', 'audio/wav']) {
        final file = await transport.uploadAttachment('conversation-a', bytes, type);
        expect(stored, isNot(bytes));
        expect(stored!.length, bytes.length + 16);
        expect(await transport.downloadAttachment('conversation-a', file), bytes);
        await expectLater(transport.downloadAttachment('conversation-b', file), throwsA(anything));
        stored![0] ^= 1;
        await expectLater(transport.downloadAttachment('conversation-a', file), throwsA(anything));
      }
    },
  );
  test('el adjunto guardado en el teléfono sigue cifrado y la segunda vez no usa la red', () async {
    await LibSignal.init();
    Uint8List? server;
    var downloads = 0;
    final adapter = MockAdapter();
    adapter.fallback = (request) {
      if (request.method == 'PUT') {
        server = Uint8List.fromList(request.data as Uint8List);
        return ResponseBody.fromString('', 204);
      }
      downloads++;
      return ResponseBody.fromBytes(server!, 200);
    };
    final root = await Directory.systemTemp.createTemp('nexo-adjuntos');
    addTearDown(() => root.delete(recursive: true));
    final files = FileCache('chat', root: () async => root);
    final transport = EncryptedChatTransport(
      testDio(adapter),
      SignalChatCrypto(AttachmentTestVault(), 'account', 1),
      files: files,
    );
    final photo = Uint8List.fromList(List.generate(2048, (i) => i % 251));
    final file = await transport.uploadAttachment('conversation', photo, 'image/jpeg');
    expect(await transport.downloadAttachment('conversation', file), photo);
    expect(await transport.downloadAttachment('conversation', file), photo);
    expect(downloads, 1);
    final stored = await files.read(file['id'] as String);
    expect(stored, server);
    expect(stored, isNot(photo));
    // Una copia dañada se descarta y se vuelve a pedir.
    await files.write(file['id'] as String, List.filled(stored!.length, 7));
    expect(await transport.downloadAttachment('conversation', file), photo);
    expect(downloads, 2);
    await expectLater(transport.downloadAttachment('otra', file), throwsA(anything));
  });
  test('long voice over one minute transfers as authenticated chunks and rejects corrupt blocks', () async {
    await LibSignal.init();
    final stored = <String, Uint8List>{};
    final adapter = MockAdapter();
    adapter.fallback = (request) {
      if (request.method == 'PUT') {
        final bytes = request.data as Uint8List;
        expect(bytes.length, lessThanOrEqualTo(1024 * 1024 + 16));
        stored[request.path] = Uint8List.fromList(bytes);
        return ResponseBody.fromString('', 204);
      }
      return ResponseBody.fromBytes(stored[request.path]!, 200);
    };
    final transport = EncryptedChatTransport(testDio(adapter), SignalChatCrypto(AttachmentTestVault(), 'account', 1));
    final voice = Uint8List.fromList(List.generate(44 + 32000 * 75, (index) => index % 251));
    final file = await transport.uploadAttachment('conversation', voice, 'audio/wav');
    expect(file['version'], 2);
    expect((file['chunks'] as List).length, 3);
    expect(await transport.downloadAttachment('conversation', file), voice);
    stored.values.last[0] ^= 1;
    await expectLater(transport.downloadAttachment('conversation', file), throwsA(anything));
    await expectLater(transport.downloadAttachment('other-conversation', file), throwsA(anything));
  });
  test('Signal exchanges authenticated messages and refuses tampering and identity replacement', () async {
    await LibSignal.init();
    final alice = SignalStores({});
    final bob = SignalStores({});
    for (final store in [alice, bob]) {
      store.state['identity'] = base64Encode(IdentityKeyPair.generate().serialize());
      store.state['registration'] = '1200';
    }
    final identity = await bob.getIdentityKeyPair();
    final signedPrivate = PrivateKey.generate();
    final signedPublic = signedPrivate.getPublicKey();
    final signature = identity.sign(message: signedPublic.serialize());
    await bob.storeSignedPreKey(
      1,
      SignedPreKeyRecord(
        id: 1,
        timestamp: BigInt.from(1),
        publicKey: signedPublic,
        privateKey: signedPrivate,
        signature: signature,
      ),
    );
    final oneTime = PrivateKey.generate();
    await bob.storePreKey(1, PreKeyRecord(id: 1, publicKey: oneTime.getPublicKey(), privateKey: oneTime));
    final kyber = KyberKeyPair.generate();
    final kyberSignature = identity.sign(message: kyber.getPublicKey().serialize());
    await bob.storeKyberPreKey(
      1,
      KyberPreKeyRecord.create(id: 1, timestamp: BigInt.from(1), keyPair: kyber, signature: kyberSignature),
    );
    final a = ProtocolAddress(name: 'alice', deviceId: 1);
    final b = ProtocolAddress(name: 'bob', deviceId: 1);
    await SessionBuilder(localAddress: a, sessionStore: alice, identityKeyStore: alice).processPreKeyBundle(
      b,
      PreKeyBundle(
        registrationId: 1200,
        deviceId: 1,
        preKeyId: 1,
        preKeyPublic: oneTime.getPublicKey().serialize(),
        signedPreKeyId: 1,
        signedPreKeyPublic: signedPublic.serialize(),
        signedPreKeySignature: signature,
        identityKey: identity.publicKey,
        kyberPreKeyId: 1,
        kyberPreKeyPublic: kyber.getPublicKey().serialize(),
        kyberPreKeySignature: kyberSignature,
      ),
    );
    SessionCipher cipher(SignalStores store, ProtocolAddress local) => SessionCipher(
      localAddress: local,
      sessionStore: store,
      identityKeyStore: store,
      preKeyStore: store,
      signedPreKeyStore: store,
      kyberPreKeyStore: store,
    );
    final sent = await cipher(alice, a).encrypt(b, Uint8List.fromList(utf8.encode('Mensaje privado')));
    final clear = await cipher(bob, b).decrypt(a, sent);
    expect(utf8.decode(clear), 'Mensaje privado');
    expect(await bob.containsPreKey(1), isFalse);
    expect(alice.state.keys.any((key) => key.startsWith('session:')), isTrue);
    final changed = Uint8List.fromList(sent.ciphertext)..[sent.ciphertext.length - 1] ^= 1;
    await expectLater(
      cipher(bob, b).decrypt(a, CiphertextMessage(type: sent.type, ciphertext: changed)),
      throwsA(anything),
    );
    final pinned = base64Encode((await alice.getIdentity(b))!.serialize());
    await alice.saveIdentity(b, PrivateKey.generate().getPublicKey());
    expect(base64Encode((await alice.getIdentity(b))!.serialize()), pinned);
    // Reload persisted ratchet records, then receive messages out of order.
    final restoredBob = SignalStores(Map<String, String>.from(bob.state));
    final next = await cipher(alice, a).encrypt(b, Uint8List.fromList(utf8.encode('Segundo')));
    final later = await cipher(alice, a).encrypt(b, Uint8List.fromList(utf8.encode('Tercero')));
    expect(utf8.decode(await cipher(restoredBob, b).decrypt(a, later)), 'Tercero');
    expect(utf8.decode(await cipher(restoredBob, b).decrypt(a, next)), 'Segundo');
    final key = Uint8List(32)..[0] = 17;
    final fileCipher = Aes256GcmSiv(key: key.toList());
    final nonce = Uint8List(12)..[0] = 11;
    final encryptedFile = fileCipher.encrypt(
      plaintext: [1, 2, 3],
      nonce: nonce.toList(),
      associatedData: utf8.encode('conversation:file'),
    );
    expect(
      fileCipher.decrypt(
        ciphertext: encryptedFile,
        nonce: nonce.toList(),
        associatedData: utf8.encode('conversation:file'),
      ),
      [1, 2, 3],
    );
    expect(
      () => fileCipher.decrypt(
        ciphertext: encryptedFile,
        nonce: nonce.toList(),
        associatedData: utf8.encode('other-conversation:file'),
      ),
      throwsA(anything),
    );
    fileCipher.dispose();
  });

  test('grupos publicados no usan demo ante red ni ruta ausente', () async {
    for (final offline in [false, true]) {
      final adapter = MockAdapter()..isOffline = offline;
      final api = HybridNexoApi(modes: const {}, http: HttpNexoApi(testDio(adapter)), fake: FakeSession().api);
      await expectLater(api.myRequests(), throwsA(isA<ApiException>()));
      await expectLater(api.providerWorks('p'), throwsA(isA<ApiException>()));
      await expectLater(api.categories(), throwsA(isA<ApiException>()));
      for (final group in [ApiGroup.solicitudes, ApiGroup.trabajos, ApiGroup.descubrimiento]) {
        expect(api.usingDemo(group), false);
      }
    }
  });

  test('proximamente solo sustituye rutas inexistentes, no autorizacion o errores de negocio', () {
    expect(isPendingFeature(const ApiException(code: 'http_404', status: 404)), isTrue);
    expect(isPendingFeature(const ApiException(code: 'auth.token_revoked', status: 401)), isFalse);
    expect(isPendingFeature(const ApiException(code: 'upload.not_found', status: 404)), isFalse);
    expect(isPendingFeature(const ApiException(code: 'server.dependency_unavailable', status: 503)), isFalse);
  });
  test('sin red, una baja real no puede convertirse en éxito simulado', () async {
    final adapter = MockAdapter()..offline();
    final api = HybridNexoApi(modes: const {}, http: HttpNexoApi(testDio(adapter)), fake: FakeSession().api);
    await expectLater(api.requestDeletion(password: testPasswordForFixture()), throwsA(isA<ApiException>()));
  });
  test('sin red, Cuenta no muestra la identidad de la maqueta', () async {
    final adapter = MockAdapter()..offline();
    final api = HybridNexoApi(modes: const {}, http: HttpNexoApi(testDio(adapter)), fake: FakeSession().api);
    await expectLater(api.accountScreen(), throwsA(isA<ApiException>()));
  });
  test('estado de cuenta nunca se autoriza desde caché local', () {
    expect(OfflineCacheInterceptor.cacheable(RequestOptions(path: '/v1/identity/me', method: 'GET')), isFalse);
  });
  test('H02: pedido pendiente no muestra domicilio exacto al prestador', () async {
    final s = FakeSession();
    await s.becomeProvider();
    final o = await s.api.order('m1');
    expect(o.status, 'pending');
    expect(o.address, isNull);
    expect(o.mapExact, isFalse);
    expect(o.counterpart.canCopyPhone, isFalse);
    final ok = await s.api.acceptOrder(o);
    expect(ok.address, isNotNull, reason: 'al aceptar ya puede llegar');
  });

  test('cerrar sesión borra credenciales, nombre y modo del teléfono', () async {
    final storage = MemoryTokenStorage();
    final c = ProviderContainer(overrides: [tokenStorageProvider.overrideWithValue(storage)]);
    addTearDown(c.dispose);
    c.read(sessionProvider);
    await Future<void>.delayed(Duration.zero);
    await c.read(sessionProvider.notifier).signIn(fakeTokens(sub: 'acc_a'), name: 'Ana');
    await c.read(sessionProvider.notifier).setMode('provider');
    await c.read(sessionProvider.notifier).signOutLocal();
    expect(storage.data, isEmpty);
    expect(c.read(sessionProvider).status, SessionStatus.signedOut);
  });

  test('una cuenta nueva no hereda el modo de la anterior', () async {
    final storage = MemoryTokenStorage();
    final c = ProviderContainer(overrides: [tokenStorageProvider.overrideWithValue(storage)]);
    addTearDown(c.dispose);
    c.read(sessionProvider);
    await Future<void>.delayed(Duration.zero);
    await c.read(sessionProvider.notifier).signIn(fakeTokens(sub: 'acc_a'));
    await c.read(sessionProvider.notifier).setMode('provider');
    await c.read(sessionProvider.notifier).signIn(fakeTokens(sub: 'acc_b'));
    expect(c.read(sessionProvider).mode, 'client');
    expect(c.read(sessionProvider).accountId, 'acc_b');
  });

  test('el celular se devuelve enmascarado', () async {
    final s = FakeSession();
    final m = await s.api.addPhone('+52 771 555 0123');
    expect(m, isNot(contains('555')));
  });
  test('perfiles nunca pasan a datos demo por caída de la red', () async {
    final adapter = MockAdapter()..offline();
    final api = HybridNexoApi(modes: const {}, http: HttpNexoApi(testDio(adapter)), fake: FakeSession().api);
    await expectLater(api.myProvider(), throwsA(isA<ApiException>()));
    await expectLater(
      api.createProvider(ProviderDraft(), idempotencyKey: testIdempotencyKey),
      throwsA(isA<ApiException>()),
    );

    await expectLater(api.patchProvider('basic', {'name': 'Nombre'}), throwsA(isA<ApiException>()));
    await expectLater(api.provider('perfil-real'), throwsA(isA<ApiException>()));
    await expectLater(api.compare(['a', 'b']), throwsA(isA<ApiException>()));
    await expectLater(api.feed(at: const GeoPoint(20, -99)), throwsA(isA<ApiException>()));
    expect(api.usingDemo(ApiGroup.perfil), isFalse);
    await expectLater(api.myProvider(), throwsA(isA<ApiException>()));
  });
  test('ubicación privada de perfiles no entra a caché ni cola local', () {
    for (final path in [
      '/v1/discovery/providers/me',
      '/v1/discovery/providers/compare',
      '/v1/discovery/providers/real',
    ]) {
      expect(OfflineCacheInterceptor.cacheable(RequestOptions(path: path, method: 'GET')), isFalse);
    }
    expect(OfflineCacheInterceptor.canQueue(RequestOptions(path: '/v1/discovery/providers', method: 'POST')), isFalse);
  });
}
