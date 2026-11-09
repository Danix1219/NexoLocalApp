import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/core/network/api_exception.dart';
import 'package:nexo_app/data/http_nexo_api.dart';
import 'package:nexo_app/data/models.dart';

import '../support/fixtures.dart';
import '../support/mock_adapter.dart';

/// Specs 039/037 · grupos `pedidos` y `opiniones`.
void main() {
  late MockAdapter a;
  late HttpNexoApi api;
  final pend = Order.fromJson(Fx.order(version: 3));
  setUp(() {
    a = MockAdapter();
    api = HttpNexoApi(testDio(a));
    a.on('GET', '/v1/engagement/orders/ord_1', Fx.order(status: 'accepted', version: 4));
  });

  test('crear pedido directo sin category en el cuerpo', () async {
    a.on('POST', '/v1/engagement/orders', Fx.order(role: 'client'), status: 201);
    await api.createOrder(
      providerId: 'prv_1',
      category: 'plomeria',
      description: 'Revisar la fuga del calentador por favor',
      attention: 'home',
      address: 'Hidalgo 24',
      idempotencyKey: 'idem-ord',
    );
    final c = a.last('POST', '/v1/engagement/orders');
    expect(c.header('Idempotency-Key'), 'idem-ord');
    final b = c.body as Map;
    expect(b['origin'], 'direct');
    expect(b.containsKey('category'), isFalse);
    expect(b.containsKey('requestId'), isFalse);
  });

  test('pedido desde solicitud usa origin=post', () async {
    a.on('POST', '/v1/engagement/orders', Fx.order(role: 'client'), status: 201);
    await api.createOrder(
        providerId: 'prv_1',
        requestId: 'req_1',
        category: 'plomeria',
        description: 'x' * 12,
        attention: 'shop',
        idempotencyKey: 'k');
    expect((a.last('POST', '/v1/engagement/orders').body as Map)['origin'], 'post');
  });

  test('aceptar manda If-Match con la versión y recarga el pedido', () async {
    a.on('POST', '/v1/engagement/orders/ord_1/accept', {'status': 'accepted'});
    final o = await api.acceptOrder(pend, amountCents: 45000, includes: 'Material');
    final c = a.last('POST', '/v1/engagement/orders/ord_1/accept');
    expect(c.header('If-Match'), '"3"');
    expect(c.body, {
      'agreedPrice': {'amountCents': 45000, 'includes': 'Material'},
    });
    expect(o.status, 'accepted');
    expect(o.version, 4);
  });

  test('rechazar, cancelar y resolver', () async {
    a.on('POST', '/v1/engagement/orders/ord_1/reject', {});
    a.on('POST', '/v1/engagement/orders/ord_1/cancel', {});
    a.on('POST', '/v1/engagement/orders/ord_1/resolve', {});
    await api.rejectOrder(pend, reason: 'noAvailability');
    expect(a.last('POST', '/v1/engagement/orders/ord_1/reject').body, {'reason': 'noAvailability'});
    await api.cancelOrder(pend, reason: 'Ya no lo necesito');
    expect(a.last('POST', '/v1/engagement/orders/ord_1/cancel').body, {'reason': 'Ya no lo necesito'});
    await api.resolveOrder(pend, finalPriceCents: 50000);
    expect(a.last('POST', '/v1/engagement/orders/ord_1/resolve').body, {
      'finalPrice': {'amountCents': 50000},
    });
  });

  test('conflicto de versión llega como 412 con código', () async {
    a.on('POST', '/v1/engagement/orders/ord_1/accept', problem('order.version_conflict', 412), status: 412);
    await expectLater(
      api.acceptOrder(pend),
      throwsA(isA<ApiException>()
          .having((e) => e.status, 'status', 412)
          .having((e) => e.code, 'code', 'order.version_conflict')),
    );
  });

  test('cambiar domicilio con PUT e If-Match', () async {
    a.on('PUT', '/v1/engagement/orders/ord_1/address', {});
    await api.updateAddress(pend, address: 'Morelos 15', location: const GeoPoint(20.05, -99.34));
    final c = a.last('PUT', '/v1/engagement/orders/ord_1/address');
    expect(c.header('If-Match'), '"3"');
    expect((c.body as Map)['address'], 'Morelos 15');
  });

  test('lista por rol con conteos', () async {
    a.on('GET', '/v1/engagement/orders', {
      ...Fx.page([Fx.order()]),
      'counts': {'pending': 1, 'accepted': 2, 'resolved': 5},
    });
    final p = await api.orders(role: 'provider', status: 'active');
    expect(p.pending, 1);
    expect(p.resolved, 5);
    final q = a.last('GET', '/v1/engagement/orders').query;
    expect(q['role'], 'provider');
    expect(q['status'], 'active');
  });

  test('opiniones: publicar y leer resumen', () async {
    a.on('POST', '/v1/engagement/reviews', {'reviewId': 'rev_1'}, status: 201);
    a.on('GET', '/v1/engagement/providers/prv_1/reviews', {
      ...Fx.page([
        {
          'reviewId': 'rev_1',
          'stars': 5,
          'text': 'Excelente',
          'recommend': true,
          'author': {'displayName': 'Laura G.'},
          'ago': 'ayer'
        },
      ]),
      'summary': {'avg': 4.8, 'count': 12, 'recommendCount': 11},
    });
    await api.review(orderId: 'ord_1', stars: 5, text: 'Excelente', recommend: true);
    final c = a.last('POST', '/v1/engagement/reviews');
    expect(c.body, {'orderId': 'ord_1', 'stars': 5, 'text': 'Excelente', 'recommend': true});
    expect(c.header('Idempotency-Key'), isNotEmpty);
    final r = await api.reviews('prv_1');
    expect(r.recommendCount, 11);
    expect(r.items.single.author, 'Laura G.');
  });
}
