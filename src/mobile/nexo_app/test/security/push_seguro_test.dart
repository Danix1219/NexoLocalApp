import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/core/auth/session_controller.dart';
import 'package:nexo_app/core/auth/token_storage.dart';
import 'package:nexo_app/core/local/local_store.dart';
import 'package:nexo_app/core/local/sync_controller.dart';
import 'package:nexo_app/data/api_provider.dart';
import 'package:nexo_app/data/http_nexo_api.dart';
import 'package:nexo_app/features/push/push_controller.dart';
import 'package:nexo_app/features/push/push_gateway.dart';

import '../support/fixtures.dart';
import '../support/mock_adapter.dart';
import '../support/push_fake.dart';

/// Spec 050 · Constitución §6: un aviso push no puede llevar a pantallas o
/// sitios arbitrarios, y el token FCM nunca aparece en los registros.
void main() {
  late List<String> logs;
  late DebugPrintCallback original;
  final nav = <String>[];

  setUp(() {
    logs = [];
    nav.clear();
    original = debugPrint;
    debugPrint = (String? m, {int? wrapWidth}) => logs.add(m ?? '');
  });
  tearDown(() => debugPrint = original);

  Future<ProviderContainer> start(FakePushGateway gw, MockAdapter a) async {
    final storage = MemoryTokenStorage();
    await storage.write(fakeTokens(sub: 'acc_1'));
    final c = ProviderContainer(overrides: [
      tokenStorageProvider.overrideWithValue(storage),
      localStoreProvider.overrideWithValue(Future.value(MemoryLocalStore())),
      pushGatewayProvider.overrideWithValue(gw),
      pushNavigatorProvider.overrideWithValue(nav.add),
      apiProvider.overrideWithValue(HttpNexoApi(testDio(a))),
    ]);
    addTearDown(c.dispose);
    c.read(sessionProvider);
    c.read(pushProvider);
    await pumpEventQueue();
    return c;
  }

  test('enlaces de un aviso: solo esquema propio y secciones conocidas', () async {
    final gw = FakePushGateway();
    await start(gw, MockAdapter());
    for (final bad in [
      'https://evil.example/orders/1',
      'nexolocal://admin/1',
      'nexolocal://orders/../account',
      'javascript:alert(1)',
      '//evil.example/chat/1',
    ]) {
      gw.opened.add(PushMessage(link: bad));
    }
    gw.opened.add(const PushMessage(link: 'nexolocal://requests/req_1'));
    await pumpEventQueue();
    expect(nav, ['/requests/req_1']);
  });

  test('el token FCM no se registra en los logs aunque falle el registro', () async {
    final gw = FakePushGateway()
      ..granted = true
      ..currentToken = 'TOKEN-FCM-SECRETO-123';
    final a = MockAdapter()..on('POST', '/v1/identity/devices', problem('server.error', 500), status: 500);
    await start(gw, a);
    expect(a.calls, isNotEmpty);
    expect(logs.join('\n'), isNot(contains('TOKEN-FCM-SECRETO-123')));
  });

  test('el id guardado es el del backend, nunca el token', () async {
    final gw = FakePushGateway()
      ..granted = true
      ..currentToken = 'TOKEN-FCM-XYZ';
    final a = MockAdapter()..on('POST', '/v1/identity/devices', {'deviceId': 'dev_9'}, status: 201);
    final c = await start(gw, a);
    final stored = await c.read(tokenStorageProvider).readDeviceId();
    expect(stored, 'dev_9');
  });
}
