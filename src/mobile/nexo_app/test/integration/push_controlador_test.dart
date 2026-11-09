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

/// Spec 050: permiso, registro del teléfono, avisos con la app abierta,
/// apertura de la pantalla del aviso y baja al cerrar sesión.
void main() {
  late MockAdapter a;
  late FakePushGateway gw;
  late MemoryTokenStorage storage;
  late ProviderContainer c;
  final nav = <String>[];

  Future<void> start({bool signedIn = true}) async {
    storage = MemoryTokenStorage();
    if (signedIn) await storage.write(fakeTokens(sub: 'acc_1'));
    c = ProviderContainer(overrides: [
      tokenStorageProvider.overrideWithValue(storage),
      localStoreProvider.overrideWithValue(Future.value(MemoryLocalStore())),
      pushGatewayProvider.overrideWithValue(gw),
      pushNavigatorProvider.overrideWithValue(nav.add),
      apiProvider.overrideWithValue(HttpNexoApi(testDio(a))),
    ]);
    c.read(sessionProvider);
    c.read(pushProvider);
    await pumpEventQueue();
  }

  setUp(() {
    a = MockAdapter()
      ..on('POST', '/v1/identity/devices', {'deviceId': 'dev_1'}, status: 201)
      ..onRaw('DELETE', '/v1/identity/devices/dev_1', (_) => jsonBody(null, status: 204));
    gw = FakePushGateway();
    nav.clear();
  });
  tearDown(() => c.dispose());

  test('sin Firebase configurado: sin push y sin llamadas', () async {
    gw.initOk = false;
    await start();
    expect(c.read(pushProvider).available, isFalse);
    expect(await c.read(pushProvider.notifier).enable(), isFalse);
    expect(a.calls, isEmpty);
  });

  test('pantalla previa al permiso: una sola vez', () async {
    await start();
    final n = c.read(pushProvider.notifier);
    expect(await n.shouldAsk(), isTrue);
    await n.markAsked();
    expect(await n.shouldAsk(), isFalse);
  });

  test('activar: pide permiso y registra el teléfono con la versión', () async {
    await start();
    expect(await c.read(pushProvider.notifier).enable(), isTrue);
    final r = a.last('POST', '/v1/identity/devices');
    expect((r.body as Map)['fcmToken'], 'tok-abc');
    expect((r.body as Map)['platform'], 'android');
    expect(storage.data['device'], 'dev_1');
    expect(c.read(pushProvider).enabled, isTrue);
  });

  test('permiso negado: no se registra', () async {
    gw.grantOnRequest = false;
    await start();
    expect(await c.read(pushProvider.notifier).enable(), isFalse);
    expect(a.calls, isEmpty);
  });

  test('con permiso previo se registra al abrir y al rotar el token', () async {
    gw.granted = true;
    await start();
    expect(a.calls.where((x) => x.path == '/v1/identity/devices'), hasLength(1));
    gw.refresh.add('tok-nuevo');
    await pumpEventQueue();
    expect((a.last('POST', '/v1/identity/devices').body as Map)['fcmToken'], 'tok-nuevo');
  });

  test('desactivar o cerrar sesión: baja en el backend y token borrado', () async {
    gw.granted = true;
    await start();
    await c.read(pushProvider.notifier).disable();
    expect(a.last('DELETE', '/v1/identity/devices/dev_1').method, 'DELETE');
    expect(gw.deletes, 1);
    expect(storage.data.containsKey('device'), isFalse);
    expect(c.read(pushProvider).enabled, isFalse);
  });

  test('aviso con la app abierta refresca la actividad', () async {
    await start();
    final before = c.read(serverEventsProvider).seq;
    gw.fg.add(const PushMessage(title: 'Carlos se interesó en tu solicitud'));
    await pumpEventQueue();
    expect(c.read(serverEventsProvider).seq, before + 1);
    expect(c.read(serverEventsProvider).message, 'Carlos se interesó en tu solicitud');
  });

  test('tocar el aviso abre su pantalla', () async {
    await start();
    gw.opened.add(const PushMessage(link: 'nexolocal://orders/ord_1'));
    await pumpEventQueue();
    expect(nav, ['/orders/ord_1']);
  });

  test('aviso que abrió la app antes de restaurar la sesión se abre después de entrar', () async {
    gw.initial = const PushMessage(link: 'nexolocal://chat/c_9');
    await start(signedIn: false);
    expect(nav, isEmpty);
    await c.read(sessionProvider.notifier).signIn(fakeTokens(sub: 'acc_1'));
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(nav, ['/chat/c_9']);
  });
}
