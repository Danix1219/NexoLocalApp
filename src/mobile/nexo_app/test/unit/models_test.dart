import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/data/models.dart';

import '../support/fixtures.dart';

/// Spec 003/031/039: los modelos leen los campos de los contratos y toleran
/// campos ausentes sin tronar.
void main() {
  test('ProviderProfile lee perfil completo del contrato', () {
    final p = ProviderProfile.fromJson(Fx.provider());
    expect(p.id, 'prv_1');
    expect(p.isBusiness, isTrue);
    expect(p.zoneLabel, 'Centro');
    expect(p.rating.avg, 4.8);
    expect(p.rating.count, 12);
    expect(p.recs, 31);
    expect(p.phoneVerified, isTrue);
    expect(p.visitMode, 'paid');
    expect(p.minPriceCents, 35000);
    expect(p.days, hasLength(7));
    expect(p.days.first!.open, '08:00');
    expect(p.days[1], isNull);
    expect(p.urgent, isTrue);
    expect(p.channelCall, isFalse);
    expect(p.hasShop, isTrue);
  });

  test('ProviderProfile con JSON vacío usa valores seguros', () {
    final p = ProviderProfile.fromJson(const {});
    expect(p.id, '');
    expect(p.status.open, isFalse);
    expect(p.status.text, 'Horario no publicado');
    expect(p.rating.text, 'Sin calificaciones');
    expect(p.prices, isEmpty);
  });

  test('Work y su prestador', () {
    final w = Work.fromJson(Fx.work());
    expect(w.provider.id, 'prv_1');
    expect(w.provider.phoneVerified, isTrue);
    expect(w.text, 'Sustituimos la llave de cocina.');
    expect(w.images.single.thumbUrl, contains('_t.jpg'));
    final r = w.copyWith(recommended: true, recs: 13);
    expect(r.recommended, isTrue);
    expect(r.recs, 13);
    expect(r.title, w.title);
  });

  test('ServiceRequest de oportunidades', () {
    final r = ServiceRequest.fromJson(Fx.request());
    expect(r.clientName, 'Ana M.');
    expect(r.interestedPreview, hasLength(1));
    expect(r.interestedMoreCount, 1);
    expect(r.matchesMyService, isTrue);
    expect(r.closed, isFalse);
    expect(ServiceRequest.fromJson({...Fx.request(), 'status': 'closed'}).closed, isTrue);
  });

  test('Order: rol, acciones permitidas y versión', () {
    final o = Order.fromJson(Fx.order());
    expect(o.iAmProvider, isTrue);
    expect(o.can('accept'), isTrue);
    expect(o.can('resolve'), isFalse);
    expect(o.version, 3);
    expect(o.address, isNull, reason: 'pendiente: sin domicilio exacto (H02)');
  });

  test('Order con precio acordado', () {
    final o = Order.fromJson({
      ...Fx.order(status: 'accepted'),
      'agreedPrice': {'amountCents': 45000, 'includes': 'Material'},
    });
    expect(o.agreedPrice!.display, r'$450');
    expect(o.agreedPrice!.includes, 'Material');
  });

  test('Conversation y Message', () {
    final c = Conversation.fromJson({
      'conversationId': 'cnv_1',
      'counterpart': {'id': 'prv_1', 'displayName': 'Hernández', 'kind': 'provider'},
      'unread': 2,
      'activeOrder': {'orderId': 'ord_1', 'status': 'accepted', 'statusText': 'Aceptado'},
    });
    expect(c.counterpart.providerId, 'prv_1');
    expect(c.unread, 2);
    expect(c.activeOrder!.statusText, 'Aceptado');
    final m = Message.fromJson({
      'messageId': 'm1',
      'kind': 'system',
      'text': 'Aceptó',
      'mine': false,
      'system': {'type': 'orderAccepted', 'orderId': 'ord_1'},
      'createdAt': '2026-11-06T18:00:00Z',
    });
    expect(m.orderId, 'ord_1');
    expect(m.createdAt, isNotNull);
  });

  test('AccountScreen compuesta', () {
    final a = AccountScreen.fromJson({
      'account': {'name': 'Ana', 'email': 'ana@x.mx', 'status': 'pendingDeletion'},
      'mode': {'current': 'provider', 'hasProvider': true},
      'savedCounts': {'provider': 1, 'work': 2, 'request': 0},
      'search': {'zoneLabel': 'Jardines', 'radiusKm': 5},
    });
    expect(a.pendingDeletion, isTrue);
    expect(a.mode, 'provider');
    expect(a.saved.total, 3);
    expect(a.radiusKm, 5);
  });

  group('formatMoney', () {
    test('pesos con separador de miles', () {
      expect(formatMoney(35000), r'$350');
      expect(formatMoney(120000), r'$1,200');
      expect(formatMoney(0), r'$0');
    });
  });
}
