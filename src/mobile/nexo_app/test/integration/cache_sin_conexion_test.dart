import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/core/local/local_store.dart';
import 'package:nexo_app/core/local/offline_interceptor.dart';
import 'package:nexo_app/core/network/api_exception.dart';
import 'package:nexo_app/data/http_nexo_api.dart';
import 'package:nexo_app/data/nexo_api.dart';

import '../support/fake_api.dart';
import '../support/fixtures.dart';
import '../support/mock_adapter.dart';

/// Spec 051: caché del cliente (ETag, sin señal, catálogo) y cola de
/// publicaciones sin conexión, con el cliente HTTP real.
void main() {
  late MockAdapter a;
  late MemoryLocalStore store;
  late Dio dio;
  late DateTime now;
  var account = 'acc_1';
  final offline = <DateTime>[];
  var online = 0;
  var queued = 0;

  setUp(() {
    a = MockAdapter();
    store = MemoryLocalStore();
    now = DateTime(2026, 11, 8, 12);
    account = 'acc_1';
    offline.clear();
    online = 0;
    queued = 0;
    dio = testDio(a)
      ..interceptors.add(OfflineCacheInterceptor(
        store: () async => store,
        account: () => account,
        onOffline: offline.add,
        onOnline: () => online++,
        onQueued: () => queued++,
        clock: () => now,
      ));
  });

  test('sin señal se muestra lo último guardado de esa cuenta', () async {
    a.on('GET', '/v1/discovery/requests/mine', Fx.page([Fx.request(mine: true)]));
    final api = HttpNexoApi(dio);
    expect(await api.myRequests(), hasLength(1));
    a.offline();
    now = now.add(const Duration(minutes: 5));
    final again = await api.myRequests();
    expect(again.single.id, 'req_1');
    expect(offline.single, DateTime(2026, 11, 8, 12), reason: 'avisa la hora de lo guardado');
  });

  test('otra cuenta no ve la caché de la anterior', () async {
    a.on('GET', '/v1/discovery/requests/mine', Fx.page([Fx.request(mine: true)]));
    await HttpNexoApi(dio).myRequests();
    a.offline();
    account = 'acc_2';
    await expectLater(HttpNexoApi(dio).myRequests(), throwsA(isA<ApiException>().having((e) => e.isNetwork, 'red', isTrue)));
  });

  test('revalida con ETag: If-None-Match y 304 devuelve lo guardado', () async {
    a.on('GET', '/v1/discovery/providers/prv_1', Fx.provider(), headers: {
      'etag': ['"v7"'],
    });
    final api = HttpNexoApi(dio);
    await api.provider('prv_1');
    a.onRaw('GET', '/v1/discovery/providers/prv_1', (_) => ResponseBody.fromString('', 304));
    final p = await api.provider('prv_1');
    expect(p.name, 'Hernández Plomería');
    expect(a.last('GET', '/v1/discovery/providers/prv_1').header('If-None-Match'), '"v7"');
  });

  test('el catálogo se sirve del teléfono durante 1 h y luego se pide otra vez', () async {
    a.on('GET', '/v1/discovery/categories', {
      'items': [
        {'id': 'plomeria', 'name': 'Plomería'},
      ],
    });
    final api = HttpNexoApi(dio);
    await api.categories();
    await api.categories();
    expect(a.calls.where((c) => c.path == '/v1/discovery/categories'), hasLength(1));
    now = now.add(const Duration(hours: 2));
    await api.categories();
    expect(a.calls.where((c) => c.path == '/v1/discovery/categories'), hasLength(2));
  });

  test('publicar una solicitud sin señal la deja en la cola con su Idempotency-Key', () async {
    a.offline();
    await expectLater(
      HttpNexoApi(dio).createRequest(
        category: 'plomeria',
        title: 'Fuga',
        description: 'Fuga debajo del lavabo',
        urgency: 'today',
        contact: 'chat',
        location: centro,
        idempotencyKey: 'idem-77',
      ),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', kQueuedOffline)),
    );
    final q = await store.pending('acc_1');
    expect(q.single.idempotencyKey, 'idem-77');
    expect(q.single.path, '/v1/discovery/requests');
    expect((jsonDecode(q.single.body) as Map)['category'], 'plomeria');
    expect(queued, 1);
  });

  test('otras escrituras sin señal no se encolan (pedidos y contacto no son offline)', () async {
    a.offline();
    await expectLater(
      HttpNexoApi(dio).createOrder(
        providerId: 'prv_1',
        category: 'plomeria',
        description: 'x',
        attention: 'home',
        idempotencyKey: 'idem-o',
      ),
      throwsA(isA<ApiException>().having((e) => e.isNetwork, 'red', isTrue)),
    );
    expect(await store.pending('acc_1'), isEmpty);
  });

  test('con el grupo en espera, publicar intenta el backend y encola (no publica en la maqueta)', () async {
    final s = FakeSession();
    final hybrid = HybridNexoApi(
      modes: {for (final g in ApiGroup.values) g: GroupMode.auto},
      http: HttpNexoApi(dio),
      fake: s.api,
      clock: () => now,
    );
    a.offline();
    await hybrid.myRequests(); // deja el grupo en espera (datos de ejemplo)
    expect(hybrid.usingDemo(ApiGroup.solicitudes), isTrue);
    await expectLater(
      hybrid.createRequest(
        category: 'plomeria',
        title: 'Fuga',
        description: 'Fuga debajo del lavabo',
        urgency: 'today',
        contact: 'chat',
        location: centro,
        idempotencyKey: 'idem-88',
      ),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', kQueuedOffline)),
    );
    expect(await store.pending('acc_1'), hasLength(1));
  });

  test('respuesta en línea avisa que hay conexión', () async {
    a.on('GET', '/v1/discovery/requests/mine', Fx.page(const []));
    await HttpNexoApi(dio).myRequests();
    expect(online, 1);
  });
}
