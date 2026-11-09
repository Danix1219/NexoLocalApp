import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/core/network/api_exception.dart';
import 'package:nexo_app/data/fake/fake_nexo_api.dart';

/// Spec 049/050 en la maqueta: la plantilla de ejemplo solo existe en
/// depuración o API_MODE=fake; en un release el asistente se informa caído.
void main() {
  FakeNexoApi api({required bool demo}) => FakeNexoApi(FakeContext(
        name: () => 'Ana',
        mode: () => 'client',
        notify: (_) {},
        simulateCounterpart: demo,
      ));

  test('release (sin simulación): el asistente no inventa texto', () async {
    await expectLater(
      api(demo: false).assistDraft(kind: 'request', category: 'plomeria', userText: 'gotea la llave del baño'),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'assist.unavailable')),
    );
  });

  test('modo de prueba: plantilla marcada como demo, sin precios y con el límite', () async {
    final d = await api(demo: true)
        .assistDraft(kind: 'request', category: 'plomeria', userText: 'gotea la llave del baño', lengthLimit: 80);
    expect(d.modelVersion, startsWith('demo'));
    expect(d.text.length, lessThanOrEqualTo(80));
    expect(d.text, isNot(contains(r'$')));
    expect(d.text.toLowerCase(), contains('plomería'));
  });

  test('trabajo del prestador usa otra plantilla', () async {
    final d = await api(demo: true).assistDraft(kind: 'work', category: 'pintura', userText: 'pinté la fachada');
    expect(d.text, startsWith('Trabajo de pintura.'));
  });

  test('dispositivos en la maqueta no fallan (sin push real)', () async {
    final a = api(demo: true);
    expect(await a.registerDevice(fcmToken: 'tok', appVersion: '0.3.0'), 'dev_demo');
    await a.removeDevice('dev_demo');
  });
}
