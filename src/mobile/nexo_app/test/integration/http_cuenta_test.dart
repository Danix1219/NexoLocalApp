import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/data/http_nexo_api.dart';

import '../support/fixtures.dart';
import '../support/mock_adapter.dart';

/// Spec 041 · grupo `cuenta`: rutas, métodos y cuerpos contra el contrato.
void main() {
  late MockAdapter a;
  late HttpNexoApi api;
  setUp(() {
    a = MockAdapter();
    api = HttpNexoApi(testDio(a));
  });

  test('GET /v1/screens/account', () async {
    a.on('GET', '/v1/screens/account', {
      'account': {'name': 'Ana', 'email': 'ana@x.mx', 'phoneVerified': true, 'status': 'active'},
      'mode': {'current': 'client', 'hasProvider': false},
      'savedCounts': {'provider': 2, 'work': 0, 'request': 0},
    });
    final s = await api.accountScreen();
    expect(s.name, 'Ana');
    expect(s.phoneVerified, isTrue);
    expect(s.saved.provider, 2);
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

  test('celular: alta y confirmación', () async {
    a.on('POST', '/v1/identity/me/phone', {'maskedPhone': '••• ••• 0123'});
    a.on('POST', '/v1/identity/me/phone/confirm', null, status: 204);
    expect(await api.addPhone('+527715550123'), '••• ••• 0123');
    await api.confirmPhone('123456');
    expect(a.last('POST', '/v1/identity/me/phone/confirm').body, {'code': '123456'});
  });

  test('eliminación: POST y DELETE /v1/identity/me/deletion', () async {
    a.on('POST', '/v1/identity/me/deletion', {'pendingDeletion': true, 'daysRemaining': 30});
    a.on('DELETE', '/v1/identity/me/deletion', null, status: 204);
    expect(await api.requestDeletion(password: 'Nexo2026ok', reason: 'prueba'), contains('30'));
    await api.cancelDeletion();
    expect(a.calls.map((c) => '${c.method} ${c.path}'), contains('DELETE /v1/identity/me/deletion'));
  });
}
