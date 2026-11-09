import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/core/auth/session_controller.dart';
import 'package:nexo_app/core/auth/token_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../support/fake_api.dart';
import '../support/fixtures.dart';

/// Spec 039/041/046 · H01/H02 y aislamiento por cuenta.
void main() {
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
}
