import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/core/auth/session_controller.dart';
import 'package:nexo_app/core/auth/token_storage.dart';
import 'package:nexo_app/core/local/local_store.dart';
import 'package:nexo_app/core/local/offline_interceptor.dart';
import 'package:nexo_app/core/local/snapshot_cipher.dart';
import 'package:nexo_app/core/local/sync_controller.dart';

import '../support/fixtures.dart';
import '../support/mock_adapter.dart';

/// Spec 051 · Constitución §4/§6: lo guardado en el teléfono es mínimo, por
/// cuenta, y se borra al salir. Nunca se sirve caché ante un certificado
/// inválido.
void main() {
  RequestOptions req(String method, String path) =>
      RequestOptions(method: method, path: path, baseUrl: 'https://api.nexo.test');

  test('nunca se guardan contacto, subidas, dispositivos, correo, contraseña ni reportes', () {
    for (final p in [
      '/v1/engagement/contacts/phone',
      '/v1/discovery/uploads/u1',
      '/v1/identity/devices',
      '/v1/identity/email/verification',
      '/v1/identity/password/reset',
      '/v1/engagement/reports',
    ]) {
      expect(OfflineCacheInterceptor.cacheable(req('GET', p)), isFalse, reason: p);
    }
    expect(OfflineCacheInterceptor.cacheable(req('GET', '/v1/discovery/feed')), isTrue);
    expect(OfflineCacheInterceptor.cacheable(req('POST', '/v1/discovery/feed')), isFalse);
    expect(OfflineCacheInterceptor.cacheable(req('GET', '/connect/token')), isFalse);
  });

  test('solo se encola publicar solicitud; pedidos, contacto y chat no', () {
    expect(OfflineCacheInterceptor.canQueue(req('POST', '/v1/discovery/requests')), isTrue);
    for (final p in [
      '/v1/engagement/orders',
      '/v1/engagement/contacts/phone',
      '/v1/engagement/conversations/c1/messages',
    ]) {
      expect(OfflineCacheInterceptor.canQueue(req('POST', p)), isFalse, reason: p);
    }
    final replay = req('POST', '/v1/discovery/requests')..extra[kReplay] = true;
    expect(OfflineCacheInterceptor.canQueue(replay), isFalse, reason: 'el reenvío no se vuelve a encolar');
  });

  test('respuestas que no son JSON no se guardan', () async {
    final a = MockAdapter()..onRaw('GET', '/v1/discovery/feed', (_) => ResponseBody.fromString('<html>', 200));
    final store = MemoryLocalStore();
    final dio = testDio(a)..interceptors.add(OfflineCacheInterceptor(store: () async => store, account: () => 'acc_1'));
    await dio.get<dynamic>('/v1/discovery/feed');
    expect(await store.read('acc_1', '/v1/discovery/feed'), isNull);
  });

  test('certificado inválido: no se responde con lo guardado', () async {
    final store = MemoryLocalStore();
    await store.write('acc_1', '/v1/discovery/feed', CachedResponse(body: '{"items":[]}', savedAt: DateTime(2026)));
    final a = MockAdapter()
      ..onRaw(
        'GET',
        '/v1/discovery/feed',
        (o) => throw DioException(requestOptions: o, type: DioExceptionType.badCertificate),
      );
    final dio = testDio(a)..interceptors.add(OfflineCacheInterceptor(store: () async => store, account: () => 'acc_1'));
    await expectLater(
      dio.get<dynamic>('/v1/discovery/feed'),
      throwsA(isA<DioException>().having((e) => e.type, 'tipo', DioExceptionType.badCertificate)),
    );
  });

  test('cerrar sesión borra la caché y la cola de esa cuenta', () async {
    final store = MemoryLocalStore();
    await store.write('acc_1', '/v1/screens/account', CachedResponse(body: '{}', savedAt: DateTime(2026)));
    await store.write('acc_2', '/v1/screens/account', CachedResponse(body: '{}', savedAt: DateTime(2026)));
    await store.enqueue(
      OutboxItem(
        account: 'acc_1',
        method: 'POST',
        path: '/v1/discovery/requests',
        body: '{}',
        idempotencyKey: 'i',
        createdAt: DateTime(2026),
      ),
    );
    final storage = MemoryTokenStorage();
    await storage.write(fakeTokens(sub: 'acc_1'));
    final c = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
        localStoreProvider.overrideWithValue(Future.value(store)),
      ],
    );
    addTearDown(c.dispose);
    c.read(sessionProvider);
    await pumpEventQueue();
    expect(c.read(sessionProvider).accountId, 'acc_1');
    await c.read(sessionProvider.notifier).signOutLocal();
    expect(await store.read('acc_1', '/v1/screens/account'), isNull);
    expect(await store.pending('acc_1'), isEmpty);
    expect(await store.read('acc_2', '/v1/screens/account'), isNotNull, reason: 'otra cuenta del teléfono no se toca');
    expect(storage.data, isEmpty);
  });

  group('copia cifrada para ver contenido sin conexión', () {
    const path = '/v1/discovery/requests/mine';

    Dio client(MockAdapter a, LocalStore store, String Function() account) =>
        testDio(a)
          ..interceptors.add(OfflineCacheInterceptor(store: () async => store, account: account, vault: _FakeCipher()));

    test('solo entra lo necesario para ver la app; contacto, lugares, claves e hilos no', () {
      for (final p in [
        '/v1/identity/me',
        '/v1/discovery/me/location',
        '/v1/discovery/providers/me',
        path,
        '/v1/engagement/conversations',
      ]) {
        expect(OfflineCacheInterceptor.snapshotable(req('GET', p)), isTrue, reason: p);
        expect(OfflineCacheInterceptor.cacheable(req('GET', p)), isFalse, reason: 'nunca sin cifrar: $p');
      }
      for (final p in [
        '/v1/engagement/contacts/phone',
        '/v1/engagement/conversations/c1/messages',
        '/v1/engagement/chat-keys/devices',
        '/v1/discovery/places/search',
        '/v1/discovery/uploads/u1',
        '/v1/identity/devices',
        '/v1/identity/password/reset',
      ]) {
        expect(OfflineCacheInterceptor.snapshotable(req('GET', p)), isFalse, reason: p);
      }
      expect(OfflineCacheInterceptor.snapshotable(req('POST', path)), isFalse);
    });

    test('se guarda cifrada y solo responde cuando no hay señal', () async {
      final store = _SpyStore();
      final online = MockAdapter()..on('GET', path, {'items': <Object>[], 'secreto': 'Calle Privada 123'});
      await client(online, store, () => 'acc_1').get<dynamic>(path);
      await pumpEventQueue();
      expect(store.written, hasLength(1));
      final (key, body) = store.written.single;
      expect(key, startsWith('sealed:'));
      expect(key, isNot(contains('requests')));
      expect(body, isNot(contains('Calle Privada')));

      final offline = MockAdapter()..offline();
      final copy = await client(offline, store, () => 'acc_1').get<dynamic>(path);
      expect((copy.data as Map)['secreto'], 'Calle Privada 123');
      expect(copy.headers.value(kCacheHeader), 'offline');
      await expectLater(client(offline, store, () => 'acc_2').get<dynamic>(path), throwsA(isA<DioException>()));
    });

    test('ni visitantes ni respuestas que llegan tras salir guardan copia', () async {
      final store = _SpyStore();
      final a = MockAdapter()..on('GET', path, {'items': <Object>[]});
      await client(a, store, () => 'guest').get<dynamic>(path);
      var calls = 0;
      await client(a, store, () => calls++ == 0 ? 'acc_1' : 'guest').get<dynamic>(path);
      await pumpEventQueue();
      expect(store.written, isEmpty);
    });
  });
}

/// Cifrado de mentira reversible: basta para comprobar qué llega al disco.
class _FakeCipher implements SnapshotCipher {
  String _hide(String text) => base64Url.encode(utf8.encode(text).map((b) => b ^ 0x5a).toList());
  @override
  Future<String> label(String key, String account) async => _hide('$account|$key');
  @override
  Future<String> seal(String plain, String aad) async => _hide(plain);
  @override
  Future<String> open(String sealed, String aad) async =>
      utf8.decode(base64Url.decode(sealed).map((b) => b ^ 0x5a).toList());
}

class _SpyStore extends MemoryLocalStore {
  final written = <(String, String)>[];
  @override
  Future<void> write(String account, String key, CachedResponse r) {
    written.add((key, r.body));
    return super.write(account, key, r);
  }
}
