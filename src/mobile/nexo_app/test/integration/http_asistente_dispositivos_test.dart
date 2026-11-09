import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/core/network/api_exception.dart';
import 'package:nexo_app/data/http_nexo_api.dart';

import '../support/mock_adapter.dart';

/// Specs 049/050 contra el backend: EP-082 (borrador generativo) y registro
/// del teléfono para push (`docs/endpoints/02-cuenta/post-devices.md`).
void main() {
  late MockAdapter a;
  late HttpNexoApi api;
  setUp(() {
    a = MockAdapter();
    api = HttpNexoApi(testDio(a));
  });

  test('borrador: manda kind, categoryId, userText y lengthLimit con Bearer', () async {
    a.on('POST', '/v1/assist/draft', {'draft': 'Necesito revisar una fuga.', 'modelVersion': 'nexo-gen-1'});
    final d =
        await api.assistDraft(kind: 'request', category: 'plomeria', userText: 'fuga en el baño', lengthLimit: 600);
    expect(d.text, 'Necesito revisar una fuga.');
    expect(d.modelVersion, 'nexo-gen-1');
    final r = a.last('POST', '/v1/assist/draft');
    expect(r.body, {'kind': 'request', 'categoryId': 'plomeria', 'userText': 'fuga en el baño', 'lengthLimit': 600});
  });

  test('borrador como objeto {title, text}', () async {
    a.on('POST', '/v1/assist/draft', {
      'draft': {'title': 'Fuga en baño', 'text': 'Busco plomero para una fuga.'},
      'modelVersion': 'm2',
    });
    final d = await api.assistDraft(kind: 'request', category: 'plomeria', userText: 'fuga');
    expect(d.title, 'Fuga en baño');
    expect(d.text, 'Busco plomero para una fuga.');
  });

  test('borrador vacío es una respuesta inesperada (no se muestra en blanco)', () async {
    a.on('POST', '/v1/assist/draft', {'draft': '  '});
    await expectLater(api.assistDraft(kind: 'request', category: 'plomeria', userText: 'x'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'client.unexpected_response')));
  });

  test('moderación rechaza el texto → error de negocio', () async {
    a.on('POST', '/v1/assist/draft', problem('content.inappropriate', 403), status: 403);
    await expectLater(api.assistDraft(kind: 'request', category: 'plomeria', userText: 'x'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'content.inappropriate')));
  });

  test('registrar teléfono: fcmToken, platform android y appVersion', () async {
    a.on('POST', '/v1/identity/devices', {'deviceId': 'dev_1', 'lastSeenAt': '2026-11-08T16:30:00Z'}, status: 201);
    expect(await api.registerDevice(fcmToken: 'tok-123', appVersion: '0.3.0'), 'dev_1');
    expect(a.last('POST', '/v1/identity/devices').body,
        {'fcmToken': 'tok-123', 'platform': 'android', 'appVersion': '0.3.0'});
  });

  test('quitar teléfono: DELETE /v1/identity/devices/{id} → 204', () async {
    a.onRaw('DELETE', '/v1/identity/devices/dev_1', (_) => jsonBody(null, status: 204));
    await api.removeDevice('dev_1');
    expect(a.last('DELETE', '/v1/identity/devices/dev_1').method, 'DELETE');
  });
}
