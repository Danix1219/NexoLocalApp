import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/core/network/api_exception.dart';

import '../support/fake_api.dart';

/// Spec 039: máquina de estados del pedido (pend→ok/cancel; ok→done/cancel).
void main() {
  late FakeSession s;
  setUp(() => s = FakeSession());

  test('servicio resuelto de la cuenta demo se puede calificar una vez', () async {
    final o = await s.api.order('ma2');
    expect(o.status, 'resolved');
    expect(o.canReview, isTrue);
    await s.api.review(orderId: 'ma2', stars: 5, text: 'Muy bien', recommend: true);
    expect((await s.api.order('ma2')).canReview, isFalse);
    await expectLater(
      s.api.review(orderId: 'ma2', stars: 4, text: '', recommend: true),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'review.already_exists')),
    );
  });

  test('prestador acepta con precio y luego resuelve', () async {
    await s.becomeProvider();
    final pend = await s.api.order('m1');
    expect(pend.status, 'pending');
    expect(pend.iAmProvider, isTrue);
    final ok = await s.api.acceptOrder(pend, amountCents: 45000, includes: 'Material');
    expect(ok.status, 'accepted');
    expect(ok.agreedPrice!.amountCents, 45000);
    expect(ok.version, pend.version + 1);
    final done = await s.api.resolveOrder(ok);
    expect(done.status, 'resolved');
  });

  test('versión vieja (If-Match) da conflicto y no cambia el estado', () async {
    await s.becomeProvider();
    final pend = await s.api.order('m1');
    await s.api.acceptOrder(pend);
    await expectLater(
      s.api.rejectOrder(pend, reason: 'other'),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 412)),
    );
    expect((await s.api.order('m1')).status, 'accepted');
  });

  test('pedido directo, duplicado activo rechazado y cancelación', () async {
    final o = await s.api.createOrder(
      providerId: 'p3',
      category: 'carpinteria',
      description: 'Ajustar la puerta principal que roza',
      attention: 'home',
      address: 'Morelos 15',
      idempotencyKey: 'k1',
    );
    expect(o.status, 'pending');
    expect(o.can('cancel'), isTrue);
    await expectLater(
      s.api.createOrder(
          providerId: 'p3', category: 'carpinteria', description: 'Otra vez', attention: 'home', idempotencyKey: 'k2'),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'order.already_active')),
    );
    final c = await s.api.cancelOrder(o, reason: 'Ya no lo necesito');
    expect(c.status, 'cancelled');
    expect(c.allowedActions.contains('cancel'), isFalse);
  });

  test('no se califica un servicio sin resolver', () async {
    await s.becomeProvider();
    s.mode = 'client';
    final o = await s.api.createOrder(
        providerId: 'p6',
        category: 'cerrajeria',
        description: 'Cambiar chapa de la puerta',
        attention: 'home',
        idempotencyKey: 'k3');
    await expectLater(
      s.api.review(orderId: o.id, stars: 5, text: '', recommend: true),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'review.order_not_resolved')),
    );
  });

  test('lista de pedidos por rol con conteos', () async {
    final c = await s.api.orders(role: 'client');
    expect(c.resolved, greaterThanOrEqualTo(1));
    final p = await s.api.orders(role: 'provider');
    expect(p.items, isEmpty);
  });
}
