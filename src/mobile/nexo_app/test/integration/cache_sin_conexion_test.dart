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

  test('solicitudes no muestran estado privado obsoleto sin señal', () async {
    a.on('GET', '/v1/discovery/requests/mine', Fx.page([Fx.request(mine: true)]));
    final api = HttpNexoApi(dio);
    expect(await api.myRequests(), hasLength(1));
    a.offline();
    now = now.add(const Duration(minutes: 5));
    await expectLater(api.myRequests(), throwsA(isA<ApiException>()));
    expect(offline, isEmpty, reason: 'estado privado vigente, sin caché de solicitudes');
  });

  test('otra cuenta no ve la caché de la anterior', () async {
    a.on('GET', '/v1/discovery/requests/mine', Fx.page([Fx.request(mine: true)]));
    await HttpNexoApi(dio).myRequests();
    a.offline();
    account = 'acc_2';
    await expectLater(
        HttpNexoApi(dio).myRequests(), throwsA(isA<ApiException>().having((e) => e.isNetwork, 'red', isTrue)));
  });

  test('solicitudes no usan ETag de estado privado almacenado', () async {
    a.on('GET', '/v1/discovery/requests/mine', Fx.page([Fx.request(mine: true)]), headers: {
      'etag': ['"v7"'],
    });
    final api = HttpNexoApi(dio);
    await api.myRequests();
    a.onRaw('GET', '/v1/discovery/requests/mine', (_) => ResponseBody.fromString('', 304));
    await expectLater(api.myRequests(), throwsA(isA<ApiException>()));
    expect(a.last('GET', '/v1/discovery/requests/mine').header('If-None-Match'), isNull);
  });

  test('perfil propio no se almacena y no aparece sin conexión', () async {
    a.on('GET', '/v1/discovery/providers/me', {
      ...Fx.provider(),
      'location': {'lat': 20, 'lng': -99}
    });
    final api = HttpNexoApi(dio);
    expect((await api.myProvider())!.location!.lat, 20);
    a.offline();
    await expectLater(api.myProvider(), throwsA(isA<ApiException>().having((e) => e.isNetwork, 'red', isTrue)));
  });

  test('el catálogo se sirve del teléfono durante 1 h y luego se pide otra vez', () async {
    a.on('GET', '/v1/discovery/categories', {
      'categories': [
        {'slug': 'plomeria', 'name': 'Plomería'},
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
    await expectLater(hybrid.myRequests(), throwsA(isA<ApiException>()));
    expect(hybrid.usingDemo(ApiGroup.solicitudes), isFalse);
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
