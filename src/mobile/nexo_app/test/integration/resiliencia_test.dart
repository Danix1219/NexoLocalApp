import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/core/network/api_exception.dart';
import 'package:nexo_app/data/http_nexo_api.dart';
import 'package:nexo_app/data/models.dart';
import 'package:nexo_app/data/nexo_api.dart';

import '../support/fake_api.dart';
import '../support/fixtures.dart';
import '../support/mock_adapter.dart';

/// Spec 045: si un endpoint no existe o no hay señal, la pantalla recibe
/// datos de ejemplo sin error; cuando el endpoint aparece, se usa el real.
void main() {
  late MockAdapter a;
  late FakeSession s;
  late DateTime now;
  final events = <String>[];

  HybridNexoApi build(Map<ApiGroup, GroupMode> modes) => HybridNexoApi(
        modes: modes,
        http: HttpNexoApi(testDio(a)),
        fake: s.api,
        cooldown: const Duration(seconds: 60),
        clock: () => now,
        onDemo: (g, demo) => events.add('${g.name}:$demo'),
      );

  Map<ApiGroup, GroupMode> all(GroupMode m) => {for (final g in ApiGroup.values) g: m};

  setUp(() {
    a = MockAdapter();
    s = FakeSession();
    now = DateTime(2026, 11, 8, 12);
    events.clear();
  });

  test('endpoint inexistente (404 sin código) → datos de ejemplo, sin error', () async {
    final api = build(all(GroupMode.auto));
    final f = await api.feed(at: centro);
    expect(f.page.items, isNotEmpty, reason: 'viene de la maqueta');
    expect(api.usingDemo(ApiGroup.descubrimiento), isTrue);
    expect(events, ['descubrimiento:true']);
  });

  test('sin señal → todos los grupos auto pasan a ejemplo de una vez', () async {
    a.offline();
    final api = build(all(GroupMode.auto));
    final r = await api.myRequests();
    expect(r, isNotEmpty);
    for (final g in ApiGroup.values) {
      expect(api.usingDemo(g), isTrue, reason: g.name);
    }
    final before = a.calls.length;
    await api.orders(role: 'client');
    expect(a.calls.length, before, reason: 'durante la espera no se vuelve a intentar la red');
  });

  test('el endpoint aparece: tras la espera se usa el backend real', () async {
    final api = build(all(GroupMode.auto));
    await api.feed(at: centro);
    a.on('GET', '/v1/discovery/feed', {
      ...Fx.page([Fx.work(id: 'wrk_real')]),
      'zoneLabel': 'Centro'
    });
    final still = await api.feed(at: centro);
    expect(still.page.items.first.id, isNot('wrk_real'));
    now = now.add(const Duration(seconds: 61));
    final real = await api.feed(at: centro);
    expect(real.page.items.single.id, 'wrk_real');
    expect(api.usingDemo(ApiGroup.descubrimiento), isFalse);
    expect(events.last, 'descubrimiento:false');
  });

  test('errores de negocio NO se ocultan con datos de ejemplo', () async {
    a.on('POST', '/v1/engagement/orders/ord_1/accept', problem('order.version_conflict', 412), status: 412);
    final api = build(all(GroupMode.auto));
    final o = Order.fromJson(Fx.order());
    await expectLater(api.acceptOrder(o), throwsA(isA<ApiException>().having((e) => e.status, 'status', 412)));
    expect(api.usingDemo(ApiGroup.pedidos), isFalse);
  });

  test('respuesta 200 que no es JSON (página HTML) → ejemplo', () async {
    a.onRaw(
        'GET',
        '/v1/discovery/feed',
        (_) => ResponseBody.fromString('<html>Hola</html>', 200, headers: {
              Headers.contentTypeHeader: ['text/html'],
            }));
    final api = build(all(GroupMode.auto));
    final f = await api.feed(at: centro);
    expect(f.page.items, isNotEmpty);
  });

  test('modo live muestra el error y modo fake nunca llama a la red', () async {
    final live = build(all(GroupMode.live));
    await expectLater(live.feed(at: centro), throwsA(isA<ApiException>()));
    a.calls.clear(); // el bloque live de arriba ya registró su llamada
    final fake = build(all(GroupMode.fake));
    await fake.feed(at: centro);
    expect(a.calls, isEmpty);
    expect(fake.usingDemo(ApiGroup.descubrimiento), isTrue);
  });
}
