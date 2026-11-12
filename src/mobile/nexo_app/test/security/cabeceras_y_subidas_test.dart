import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/core/network/api_client.dart';
import 'package:nexo_app/data/http_nexo_api.dart';
import 'package:nexo_app/data/models.dart';
import 'package:nexo_app/data/nexo_api.dart';

import '../support/fixtures.dart';
import '../support/mock_adapter.dart';

/// Spec 046: protección contra repeticiones (Idempotency-Key), escrituras
/// concurrentes (If-Match) y fuga del Bearer al almacenamiento.
void main() {
  test('rechaza URL de subida HTTP antes de transferir bytes', () async {
    final a = MockAdapter()
      ..on('POST', '/v1/discovery/uploads', {'uploadId': 'u', 'uploadUrl': 'http://storage.test/u?sig=1'});
    final blob = MockAdapter();
    final api = HttpNexoApi(testDio(a), uploadDio: Dio()..httpClientAdapter = blob);
    await expectLater(
        api.upload(PickedImage(path: 'x.png', bytes: Uint8List(10), contentType: 'image/png'), purpose: 'avatar'),
        throwsA(isA<Exception>()));
    expect(blob.calls, isEmpty);
  });

  late MockAdapter a;
  late HttpNexoApi api;

  setUp(() {
    a = MockAdapter()..fallback = (_) => jsonBody({'ok': true, 'orderId': 'ord_1', 'status': 'pending', 'version': 3});
    final dio = testDio(a);
    // Simula el AuthInterceptor: Bearer solo en peticiones marcadas.
    dio.interceptors.add(InterceptorsWrapper(onRequest: (o, h) {
      if (o.extra[kAuth] == true) o.headers['Authorization'] = 'Bearer token-de-prueba';
      h.next(o);
    }));
    api = HttpNexoApi(dio, uploadDio: Dio()..httpClientAdapter = a);
  });

  test('cada alta lleva Idempotency-Key distinta', () async {
    await api.createWork(category: 'plomeria', title: 'Trabajo', text: 'x' * 25, location: const GeoPoint(1, 1));
    await api.createWork(category: 'plomeria', title: 'Trabajo', text: 'x' * 25, location: const GeoPoint(1, 1));
    await api.openConversation(providerId: 'prv_1');
    await api.sendMessage('cnv_1', text: 'hola');
    await api.report(targetType: 'work', targetId: 'w', category: 'scam', reason: 'x' * 12);
    await api.review(orderId: 'o', stars: 5, text: '', recommend: true);
    final keys = a.calls.where((c) => c.method == 'POST').map((c) => c.header('Idempotency-Key')).toList();
    expect(keys.every((k) => k != null && k.length >= 16), isTrue);
    expect(keys.toSet().length, keys.length, reason: 'sin claves repetidas');
  });

  test('las acciones del pedido llevan If-Match con la versión vista', () async {
    final o = Order.fromJson(Fx.order(version: 7));
    await api.acceptOrder(o);
    await api.rejectOrder(o, reason: 'other');
    await api.cancelOrder(o, reason: 'x');
    await api.resolveOrder(o);
    await api.updateAddress(o, address: 'Calle 1');
    final writes = a.calls.where((c) => c.method != 'GET').toList();
    expect(writes, hasLength(5));
    expect(writes.every((c) => c.header('If-Match') == '"7"'), isTrue);
  });

  test('todas las llamadas a Nexo llevan Bearer; la URL firmada nunca', () async {
    a.on('POST', '/v1/discovery/uploads', {
      'uploadId': 'upl_1',
      'uploadUrl': 'https://storage.nexo.test/b/upl_1?sig=1',
      'headers': {'Content-Type': 'image/jpeg'},
    });
    a.on('POST', '/v1/discovery/uploads/upl_1/complete', {'status': 'approved'});
    await api.upload(PickedImage(path: '/x.jpg', bytes: Uint8List(10), contentType: 'image/jpeg'), purpose: 'avatar');
    final storage = a.calls.where((c) => c.host == 'storage.nexo.test').toList();
    final nexo = a.calls.where((c) => c.host == 'api.nexo.test').toList();
    expect(storage, hasLength(1));
    expect(storage.single.header('Authorization'), isNull);
    expect(nexo, isNotEmpty);
    expect(nexo.every((c) => c.header('Authorization') == 'Bearer token-de-prueba'), isTrue);
  });
}
