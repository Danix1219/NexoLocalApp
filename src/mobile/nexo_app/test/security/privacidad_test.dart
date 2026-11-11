import 'package:nexo_app/data/models.dart';
import 'package:dio/dio.dart';
import 'package:nexo_app/core/local/offline_interceptor.dart';
import 'package:nexo_app/core/widgets/ui.dart';
import 'package:nexo_app/data/nexo_api.dart';
import 'package:nexo_app/data/http_nexo_api.dart';
import 'package:nexo_app/core/network/api_exception.dart';
import '../support/mock_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/core/auth/session_controller.dart';
import 'package:nexo_app/core/auth/token_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../support/fake_api.dart';
import '../support/fixtures.dart';

/// Spec 039/041/046 · H01/H02 y aislamiento por cuenta.
void main() {
  test('grupos publicados no usan demo ante red ni ruta ausente', () async {
    for (final offline in [false, true]) {
      final adapter = MockAdapter()..isOffline = offline;
      final api = HybridNexoApi(modes: const {}, http: HttpNexoApi(testDio(adapter)), fake: FakeSession().api);
      await expectLater(api.myRequests(), throwsA(isA<ApiException>()));
      await expectLater(api.providerWorks('p'), throwsA(isA<ApiException>()));
      await expectLater(api.categories(), throwsA(isA<ApiException>()));
      for (final group in [ApiGroup.solicitudes, ApiGroup.trabajos, ApiGroup.descubrimiento]) {
        expect(api.usingDemo(group), false);
      }
    }
  });

  test('proximamente solo sustituye rutas inexistentes, no autorizacion o errores de negocio', () {
    expect(isPendingFeature(const ApiException(code: 'http_404', status: 404)), isTrue);
    expect(isPendingFeature(const ApiException(code: 'auth.token_revoked', status: 401)), isFalse);
    expect(isPendingFeature(const ApiException(code: 'upload.not_found', status: 404)), isFalse);
    expect(isPendingFeature(const ApiException(code: 'server.dependency_unavailable', status: 503)), isFalse);
  });
  test('sin red, una baja real no puede convertirse en éxito simulado', () async {
    final adapter = MockAdapter()..offline();
    final api = HybridNexoApi(modes: const {}, http: HttpNexoApi(testDio(adapter)), fake: FakeSession().api);
    await expectLater(api.requestDeletion(password: testPasswordForFixture()), throwsA(isA<ApiException>()));
  });
  test('sin red, Cuenta no muestra la identidad de la maqueta', () async {
    final adapter = MockAdapter()..offline();
    final api = HybridNexoApi(modes: const {}, http: HttpNexoApi(testDio(adapter)), fake: FakeSession().api);
    await expectLater(api.accountScreen(), throwsA(isA<ApiException>()));
  });
  test('estado de cuenta nunca se autoriza desde caché local', () {
    expect(OfflineCacheInterceptor.cacheable(RequestOptions(path: '/v1/identity/me', method: 'GET')), isFalse);
  });
  test('H02: pedido pendiente no muestra domicilio exacto al prestador', () async {
    final s = FakeSession();
    await s.becomeProvider();
    final o = await s.api.order('m1');
    expect(o.status, 'pending');
    expect(o.address, isNull);
    expect(o.mapExact, isFalse);
    expect(o.counterpart.canCopyPhone, isFalse);
    final ok = await s.api.acceptOrder(o);
    expect(ok.address, isNotNull, reason: 'al aceptar ya puede llegar');
  });

  test('cerrar sesión borra credenciales, nombre y modo del teléfono', () async {
    final storage = MemoryTokenStorage();
    final c = ProviderContainer(overrides: [tokenStorageProvider.overrideWithValue(storage)]);
    addTearDown(c.dispose);
    c.read(sessionProvider);
    await Future<void>.delayed(Duration.zero);
    await c.read(sessionProvider.notifier).signIn(fakeTokens(sub: 'acc_a'), name: 'Ana');
    await c.read(sessionProvider.notifier).setMode('provider');
    await c.read(sessionProvider.notifier).signOutLocal();
    expect(storage.data, isEmpty);
    expect(c.read(sessionProvider).status, SessionStatus.signedOut);
  });

  test('una cuenta nueva no hereda el modo de la anterior', () async {
    final storage = MemoryTokenStorage();
    final c = ProviderContainer(overrides: [tokenStorageProvider.overrideWithValue(storage)]);
    addTearDown(c.dispose);
    c.read(sessionProvider);
    await Future<void>.delayed(Duration.zero);
    await c.read(sessionProvider.notifier).signIn(fakeTokens(sub: 'acc_a'));
    await c.read(sessionProvider.notifier).setMode('provider');
    await c.read(sessionProvider.notifier).signIn(fakeTokens(sub: 'acc_b'));
    expect(c.read(sessionProvider).mode, 'client');
    expect(c.read(sessionProvider).accountId, 'acc_b');
  });

  test('el celular se devuelve enmascarado', () async {
    final s = FakeSession();
    final m = await s.api.addPhone('+52 771 555 0123');
    expect(m, isNot(contains('555')));
  });
  test('perfiles nunca pasan a datos demo por caída de la red', () async {
    final adapter = MockAdapter()..offline();
    final api = HybridNexoApi(modes: const {}, http: HttpNexoApi(testDio(adapter)), fake: FakeSession().api);
    await expectLater(api.myProvider(), throwsA(isA<ApiException>()));
    await expectLater(api.createProvider(ProviderDraft(), idempotencyKey: 'profile-test'),
        throwsA(isA<ApiException>()));
    await expectLater(api.patchProvider('basic', {'name': 'Nombre'}), throwsA(isA<ApiException>()));
    await expectLater(api.provider('perfil-real'), throwsA(isA<ApiException>()));
    await expectLater(api.compare(['a', 'b']), throwsA(isA<ApiException>()));
    await expectLater(api.feed(at: const GeoPoint(20, -99)), throwsA(isA<ApiException>()));
    expect(api.usingDemo(ApiGroup.perfil), isFalse);
    await expectLater(api.myProvider(), throwsA(isA<ApiException>()));
  });
  test('ubicación privada de perfiles no entra a caché ni cola local', () {
    for (final path in [
      '/v1/discovery/providers/me',
      '/v1/discovery/providers/compare',
      '/v1/discovery/providers/real'
    ]) {
      expect(OfflineCacheInterceptor.cacheable(RequestOptions(path: path, method: 'GET')), isFalse);
    }
    expect(OfflineCacheInterceptor.canQueue(RequestOptions(path: '/v1/discovery/providers', method: 'POST')), isFalse);
  });
}
