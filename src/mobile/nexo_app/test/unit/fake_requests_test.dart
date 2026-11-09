import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/core/network/api_exception.dart';
import 'package:nexo_app/data/models.dart';

import '../support/fake_api.dart';

/// Specs 035/038: solicitudes, interés e interesados.
void main() {
  late FakeSession s;
  setUp(() => s = FakeSession());

  test('mis solicitudes de la cuenta demo', () async {
    final mine = await s.api.myRequests();
    expect(mine.map((r) => r.id), containsAll(['ra1', 'ra2']));
    expect(mine.every((r) => r.mine), isTrue);
    final ra1 = mine.firstWhere((r) => r.id == 'ra1');
    expect(ra1.interestCount, 2);
  });

  test('interesados ordenados por recomendaciones', () async {
    final page = await s.api.interested('ra1', sort: 'recs');
    final recs = page.items.map((i) => i.provider.recs).toList();
    expect(recs, [...recs]..sort((a, b) => b.compareTo(a)));
    expect(page.items.every((i) => i.canOrder), isTrue);
  });

  test('publicar solicitud la agrega a mis solicitudes', () async {
    final r = await s.api.createRequest(
      category: 'pintura',
      title: 'Pintar recámara',
      description: 'Recámara de 12 m², ya tengo la pintura.',
      urgency: 'week',
      contact: 'chat',
      location: centro,
      idempotencyKey: 'idem-1',
    );
    expect(r.mine, isTrue);
    expect((await s.api.myRequests()).first.id, r.id);
  });

  test('"Me interesa" exige perfil de prestador', () async {
    await expectLater(s.api.setInterest('r1', true), throwsA(isA<ApiException>()));
  });

  test('oportunidades del prestador: ajenas, abiertas y marcadas', () async {
    await s.becomeProvider();
    final list = await s.api.opportunities(const OppFilters(inRadius: false));
    expect(list, isNotEmpty);
    expect(list.any((r) => r.mine || r.closed), isFalse);
    expect(list.first.matchesMyService, isTrue, reason: 'las de su categoría van primero');
    await s.api.setInterest(list.first.id, true);
    final again = await s.api.opportunities(const OppFilters(inRadius: false));
    expect(again.firstWhere((r) => r.id == list.first.id).iAmInterested, isTrue);
  });

  test('cerrar solicitud', () async {
    await s.api.closeRequest('ra1', outcome: 'solvedElsewhere');
    final ra1 = (await s.api.myRequests()).firstWhere((r) => r.id == 'ra1');
    expect(ra1.closed, isTrue);
  });
}
