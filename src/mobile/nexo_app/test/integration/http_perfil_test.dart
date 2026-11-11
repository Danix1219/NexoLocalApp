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
        {
          'key': 'recs',
          'label': 'Recomiendan',
          'values': ['31', '22'],
          'best': 0
        },
      ],
    });
    final r = await api.compare(['prv_1', 'prv_2']);
    expect(r.rows.single.best, 0);
    expect(a.last('GET', '/v1/discovery/providers/compare').query['ids'], 'prv_1,prv_2');
  });

  test('error de negocio del perfil llega como ApiException con código', () async {
    a.on('PATCH', '/v1/discovery/providers/me/prices', problem('provider.prices_limit', 400, 'Máximo 3 precios'),
        status: 400);
    await expectLater(
      api.patchProvider('prices', {'prices': []}),
      throwsA(isA<ApiException>()
          .having((e) => e.code, 'code', 'provider.prices_limit')
          .having((e) => e.detail, 'detail', 'Máximo 3 precios')),
    );
  });
  test('404 sin código de perfil no se convierte en ausencia', () async {
    a.on('GET', '/v1/discovery/providers/me', {'title': 'Not found'}, status: 404);
    await expectLater(api.myProvider(), throwsA(isA<ApiException>().having((e) => e.code, 'code', 'http_404')));
  });

  test('alta traduce especialidades y excluye campos de negocio en persona', () async {
    a.on('POST', '/v1/discovery/providers', {'providerId': '019400d4-9e5a-7b23-8c91-4f6a7b8c9d01'}, status: 201);
    final draft = ProviderDraft()
      ..kind = 'trade'
      ..activity = 'Dato residual del negocio'
      ..categories = ['plomeria']
      ..specialties = ['Fugas y reparaciones']
      ..location = const GeoPoint(20, -99);
    await api.createProvider(draft, idempotencyKey: 'profile-test');
    final body = a.last('POST', '/v1/discovery/providers').body as Map;
    expect(body['specialties'], ['fugas']);
    expect(body.containsKey('activity'), isFalse);
    expect(body['experience'], 0);
    expect(body['attention'], 'home');
  });

  test('perfil real conserva política, importes y métricas ausentes', () async {
    a.on('GET', '/v1/discovery/providers/me', {
      ...Fx.provider(),
      'policyVersion': 'provider-completeness/1',
      'location': {'lat': 20.0539, 'lng': -99.3403},
      'visit': {'mode': 'paid', 'amountCents': 12050},
      'minPrice': {'fromCents': 15075},
      'stats': {'views': 2, 'contactClicks': null, 'interestsGiven': null},
    });
    final own = (await api.myProvider())!;
    expect(own.policyVersion, 'provider-completeness/1');
    expect(own.contactClicks, isNull);
    expect(own.location!.lat, 20.0539);
    expect(own.profile.visitAmountCents, 12050);
    expect(own.profile.visitText, r'$120.50');
    expect(own.profile.minPriceText, r'Desde $150.75');
  });

  test('comparación conserva null explícito y coordenadas', () async {
    a.on('GET', '/v1/discovery/providers/compare', {
      'providers': [Fx.provider(), Fx.provider(id: 'prv_2')],
      'rows': [
        {
          'key': 'payment',
          'label': 'Pago',
          'values': ['Efectivo', 'Tarjeta'],
          'best': null
        }
      ],
    });
    final result = await api.compare(['prv_1', 'prv_2'], at: const GeoPoint(20, -99));
    expect(result.rows.single.best, isNull);
    expect(a.last('GET', '/v1/discovery/providers/compare').query['lat'], '20.0');
  });

  test('moderación no disponible permanece como fallo real', () async {
    a.on('POST', '/v1/discovery/providers', problem('server.dependency_unavailable', 503), status: 503);
    await expectLater(api.createProvider(ProviderDraft(), idempotencyKey: 'profile-test'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'server.dependency_unavailable')));
  });
}
