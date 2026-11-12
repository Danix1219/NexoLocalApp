import 'package:nexo_app/core/network/api_client.dart';
import 'package:nexo_app/data/models.dart';
import 'package:nexo_app/features/auth/data/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/data/http_nexo_api.dart';

import '../support/fixtures.dart';
import '../support/mock_adapter.dart';

/// Spec 041 · grupo `cuenta`: rutas, métodos y cuerpos contra el contrato.
void main() {
  test('geocodificación y restauración usan rutas reales y conservan zona y coordenadas', () async {
    final adapter = MockAdapter();
    adapter.on('GET', '/v1/discovery/places/search', {
      'items': [
        {'lat': 20.0489, 'lng': -99.3729, 'label': 'Tula de Allende', 'zoneLabel': 'Tula de Allende, Hidalgo'}
      ]
    });
    adapter.on('GET', '/v1/discovery/places/reverse', {
      'place': {'lat': 20.0489, 'lng': -99.3729, 'label': 'Tula de Allende', 'zoneLabel': 'Tula de Allende, Hidalgo'}
    });
    adapter.on('GET', '/v1/discovery/me/location', {
      'searchLocation': {'lat': 20.0489, 'lng': -99.3729},
      'zoneLabel': 'Tula de Allende, Hidalgo',
      'radiusKm': 5
    });
    final api = HttpNexoApi(testDio(adapter));
    expect((await api.searchPlaces('Tula & Hidalgo', at: const GeoPoint(20.05, -99.34))).single.zoneLabel,
        'Tula de Allende, Hidalgo');
    expect(adapter.last('GET', '/v1/discovery/places/search').query['q'], 'Tula & Hidalgo');
    expect((await api.reversePlace(const GeoPoint(20.0489, -99.3729)))!.point.lng, -99.3729);
    final saved = await api.getLocation();
    expect(saved!.radiusKm, 5);
    expect(saved.zoneLabel, 'Tula de Allende, Hidalgo');
    expect(saved.point.lat, 20.0489);
    expect(adapter.last('GET', '/v1/discovery/me/location').options.extra[kAuth], isTrue);
    expect(adapter.last('GET', '/v1/discovery/places/search').options.extra[kAuth], isFalse);
    expect(adapter.last('GET', '/v1/discovery/places/reverse').options.extra[kAuth], isFalse);
  });
  test('sin ubicación guardada devuelve null sin inventar Centro', () async {
    final adapter = MockAdapter()..on('GET', '/v1/discovery/me/location', null);
    expect(await HttpNexoApi(testDio(adapter)).getLocation(), isNull);
  });

  test('registro envia las coordenadas y radio seleccionados, sin sustituirlos por Centro', () async {
    final adapter = MockAdapter()
      ..on('POST', '/v1/identity/accounts', {'name': 'Ana', 'nextStep': 'home'}, status: 201);
    final repository = AuthRepository(testDio(adapter));
    await repository.createAccount(
        location: const GeoPoint(19.43, -99.13),
        radiusKm: 2,
        ticket: 'ticket',
        name: 'Ana',
        password: testPasswordForFixture(),
        intent: 'client',
        idempotencyKey: 'alta-1');
    final body = adapter.last('POST', '/v1/identity/accounts').body;
    expect(body['searchLocation'], {'lat': 19.43, 'lng': -99.13});
    expect(body['searchRadiusKm'], 2);
  });
  late MockAdapter a;
  late HttpNexoApi api;
  setUp(() {
    a = MockAdapter();
    api = HttpNexoApi(testDio(a));
  });

  test('GET /v1/identity/me', () async {
    a.on('GET', '/v1/identity/me', {
      'name': 'Ana',
      'email': 'ana@x.mx',
      'emailVerifiedAt': '2026-11-09T12:00:00Z',
      'currentMode': 'client',
      'hasProvider': false,
      'status': 'active',
    });
    final s = await api.accountScreen();
    expect(s.name, 'Ana');
    expect(s.emailVerified, isTrue);
    expect(s.mode, 'client');
  });

  test('PATCH /v1/identity/me solo manda lo que cambia', () async {
    a.on('PATCH', '/v1/identity/me', {'name': 'Ana L.'});
    await api.updateMe(name: 'Ana L.');
    expect(a.last('PATCH', '/v1/identity/me').body, {'name': 'Ana L.'});
  });

  test('POST /v1/identity/me/mode devuelve tokens nuevos', () async {
    a.on('POST', '/v1/identity/me/mode', {
      'currentMode': 'provider',
      'hasProvider': true,
      'accessToken': fakeJwt({'sub': 'acc_1', 'mode': 'provider', 'has_provider': true}),
      'refreshToken': 'r2',
      'expiresInSeconds': 600,
    });
    final t = await api.switchMode('provider');
    expect(t, isNotNull);
    expect(t!.refreshToken, 'r2');
    expect(a.last('POST', '/v1/identity/me/mode').body, {'mode': 'provider'});
  });

  test('celular declarado: guarda sin solicitar SMS', () async {
    a.on('POST', '/v1/identity/me/phone', {'phone': '+527715550123', 'phoneVerificationStatus': 'declared'});
    expect(await api.addPhone('+527715550123'), '+527715550123');
    expect(a.calls.length, 1);
  });

  test('cambio de modo renueva mediante OAuth cuando lo exige el backend', () async {
    api = HttpNexoApi(testDio(a), refreshToken: () async => 'refresh-actual');
    a.on('POST', '/v1/identity/me/mode', {'currentMode': 'provider', 'tokenRefreshRequired': true});
    a.on('POST', '/connect/token', {'access_token': 'nuevo', 'refresh_token': 'rotado', 'expires_in': 600});
    final tokens = await api.switchMode('provider');
    expect(tokens!.refreshToken, 'rotado');
    expect(a.calls.last.body['refresh_token'], 'refresh-actual');
  });

  test('eliminación: POST y DELETE /v1/identity/me/deletion', () async {
    a.on('POST', '/v1/identity/me/deletion', {'pendingDeletion': true, 'daysRemaining': 30});
    a.on('DELETE', '/v1/identity/me/deletion', null, status: 204);
    expect(await api.requestDeletion(password: testPasswordForFixture(), reason: 'prueba'), contains('30'));
    await api.cancelDeletion();
    expect(a.calls.map((c) => '${c.method} ${c.path}'), contains('DELETE /v1/identity/me/deletion'));
  });
}
