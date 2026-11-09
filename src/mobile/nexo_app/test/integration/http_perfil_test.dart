import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/core/network/api_exception.dart';
import 'package:nexo_app/data/http_nexo_api.dart';
import 'package:nexo_app/data/models.dart';
import 'package:nexo_app/data/nexo_api.dart';

import '../support/fixtures.dart';
import '../support/mock_adapter.dart';

/// Specs 031/032/033/044 · grupo `perfil`.
void main() {
  late MockAdapter a;
  late HttpNexoApi api;
  setUp(() {
    a = MockAdapter();
    api = HttpNexoApi(testDio(a));
  });

  test('GET /v1/discovery/providers/{id} con lat/lng', () async {
    a.on('GET', '/v1/discovery/providers/prv_1', Fx.provider());
    final p = await api.provider('prv_1', at: const GeoPoint(20.05, -99.34));
    expect(p.name, 'Hernández Plomería');
    final q = a.last('GET', '/v1/discovery/providers/prv_1').query;
    expect(q['lat'], '20.05');
    expect(q['lng'], '-99.34');
  });

  test('perfil propio: 404 significa "aún no tiene perfil"', () async {
    a.on('GET', '/v1/discovery/providers/me', problem('provider.not_found', 404), status: 404);
    expect(await api.myProvider(), isNull);
  });

  test('perfil propio con completitud', () async {
    a.on('GET', '/v1/discovery/providers/me', {
      ...Fx.provider(),
      'completeness': 62,
      'todo': [
        {'key': 'hours', 'label': 'Horario', 'points': 14, 'done': false},
      ],
      'stats': {'views': 40, 'contactClicks': 7},
    });
    final me = await api.myProvider();
    expect(me!.completeness, 62);
    expect(me.todo.single.key, 'hours');
    expect(me.views, 40);
  });

  test('POST /v1/discovery/providers con Idempotency-Key y campos del contrato', () async {
    a.on('POST', '/v1/discovery/providers', {'providerId': 'prv_9'}, status: 201);
    final d = ProviderDraft()
      ..kind = 'trade'
      ..name = 'Luis Ortega'
      ..bio = 'Plomería y electricidad doméstica.'
      ..experience = 2
      ..crew = 'alone'
      ..categories = ['plomeria']
      ..trades = ['Plomero/a']
      ..location = const GeoPoint(20.07, -99.33)
      ..radiusKm = 5
      ..acceptedRules = true;
    expect(await api.createProvider(d, idempotencyKey: 'idem-42'), 'prv_9');
    final c = a.last('POST', '/v1/discovery/providers');
    expect(c.header('Idempotency-Key'), 'idem-42');
    final b = c.body as Map;
    expect(b['kind'], 'trade');
    expect(b['crew'], 'alone');
    expect(b['trades'], ['Plomero/a']);
    expect(b['radiusKm'], 5);
    expect(b['acceptedRules'], isTrue);
    expect(b.containsKey('owner'), isFalse, reason: 'owner es solo de negocio');
  });

  test('PATCH /v1/discovery/providers/me/{seccion}', () async {
    for (final s in ['basic', 'services', 'zone', 'hours', 'prices', 'terms']) {
      a.on('PATCH', '/v1/discovery/providers/me/$s', {'ok': true});
      await api.patchProvider(s, {'x': s});
      expect(a.last('PATCH', '/v1/discovery/providers/me/$s').body, {'x': s});
    }
  });

  test('comparar manda ids separados por coma', () async {
    a.on('GET', '/v1/discovery/providers/compare', {
      'providers': [Fx.provider(), Fx.provider(id: 'prv_2', name: 'Electro Ruiz')],
      'rows': [
        {'key': 'recs', 'label': 'Recomiendan', 'values': ['31', '22'], 'best': 0},
      ],
    });
    final r = await api.compare(['prv_1', 'prv_2']);
    expect(r.rows.single.best, 0);
    expect(a.last('GET', '/v1/discovery/providers/compare').query['ids'], 'prv_1,prv_2');
  });

  test('error de negocio del perfil llega como ApiException con código', () async {
    a.on('PATCH', '/v1/discovery/providers/me/prices', problem('provider.prices_limit', 400, 'Máximo 3 precios'), status: 400);
    await expectLater(
      api.patchProvider('prices', {'prices': []}),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'provider.prices_limit').having((e) => e.detail, 'detail', 'Máximo 3 precios')),
    );
  });
}
