import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/core/auth/session_controller.dart';
import 'package:nexo_app/core/auth/token_storage.dart';
import 'package:nexo_app/core/local/local_store.dart';
import 'package:nexo_app/core/local/sync_controller.dart';
import 'package:nexo_app/core/network/api_client.dart';

import '../support/fixtures.dart';
import '../support/mock_adapter.dart';

/// Spec 051: la cola se envía al volver la conexión, una sola vez por
/// Idempotency-Key, y descarta lo que el backend rechaza por negocio.
void main() {
  late MockAdapter a;
  late MemoryLocalStore store;
  late StreamController<bool> net;
  late ProviderContainer c;
  final avisos = <String>[];

  OutboxItem item(String idem, {String account = 'acc_1'}) => OutboxItem(
        account: account,
        method: 'POST',
        path: '/v1/discovery/requests',
        body: '{"category":"plomeria","title":"Fuga"}',
        idempotencyKey: idem,
        createdAt: DateTime(2026, 11, 8),
      );

  Future<void> start({bool signedIn = true}) async {
    final storage = MemoryTokenStorage();
    if (signedIn) await storage.write(fakeTokens(sub: 'acc_1'));
    c = ProviderContainer(overrides: [
      tokenStorageProvider.overrideWithValue(storage),
      localStoreProvider.overrideWithValue(Future.value(store)),
      connectivityChangesProvider.overrideWithValue(net.stream),
      dioProvider.overrideWithValue(testDio(a)),
    ]);
    c.read(sessionProvider);
    await pumpEventQueue();
    c.read(syncProvider.notifier).notify = avisos.add;
  }

  setUp(() {
    a = MockAdapter();
    store = MemoryLocalStore();
    net = StreamController<bool>.broadcast();
    avisos.clear();
  });
  tearDown(() async {
    c.dispose();
    await net.close();
  });

  test('al reconectar envía lo pendiente con la misma Idempotency-Key', () async {
    await store.enqueue(item('idem-1'));
    a.on('POST', '/v1/discovery/requests', Fx.request(mine: true), status: 201);
    await start();
    final r = await c.read(syncProvider.notifier).flush();
    expect(r.sent, 1);
    expect(a.last('POST', '/v1/discovery/requests').header('Idempotency-Key'), 'idem-1');
    expect(await store.pending('acc_1'), isEmpty);
    expect(c.read(syncProvider).pending, 0);
    expect(avisos, ['Se publicó tu solicitud guardada.']);
  });

  test('el evento de conectividad dispara el envío', () async {
    await store.enqueue(item('idem-2'));
    a.on('POST', '/v1/discovery/requests', Fx.request(mine: true), status: 201);
    await start();
    net.add(true);
    await pumpEventQueue();
    expect(a.calls.where((x) => x.method == 'POST'), hasLength(1));
  });

  test('error de negocio: se descarta y se avisa el motivo', () async {
    await store.enqueue(item('idem-3'));
    a.on('POST', '/v1/discovery/requests', problem('request.too_many_open', 409, 'Ya tienes 5 solicitudes abiertas.'),
        status: 409);
    await start();
    final r = await c.read(syncProvider.notifier).flush();
    expect(r.failed, ['Ya tienes 5 solicitudes abiertas.']);
    expect(await store.pending('acc_1'), isEmpty);
  });

  test('sigue sin señal: se conserva para después', () async {
    await store.enqueue(item('idem-4'));
    a.offline();
    await start();
    final r = await c.read(syncProvider.notifier).flush();
    expect(r.sent, 0);
    expect(await store.pending('acc_1'), hasLength(1));
  });

  test('endpoint aún inexistente: reintenta hasta el límite y luego descarta', () async {
    await store.enqueue(item('idem-5'));
    await start();
    for (var i = 0; i < LocalStore.maxAttempts - 1; i++) {
      await c.read(syncProvider.notifier).flush();
      expect(await store.pending('acc_1'), hasLength(1), reason: 'intento ${i + 1}');
    }
    final r = await c.read(syncProvider.notifier).flush();
    expect(r.failed, hasLength(1));
    expect(await store.pending('acc_1'), isEmpty);
  });

  test('solo envía la cola de la cuenta con sesión', () async {
    await store.enqueue(item('idem-6', account: 'acc_otro'));
    a.on('POST', '/v1/discovery/requests', Fx.request(mine: true), status: 201);
    await start();
    await c.read(syncProvider.notifier).flush();
    expect(a.calls, isEmpty);
    expect(await store.pending('acc_otro'), hasLength(1));
  });

  test('sin sesión no se envía nada', () async {
    await store.enqueue(item('idem-7'));
    await start(signedIn: false);
    final r = await c.read(syncProvider.notifier).flush();
    expect(r.sent, 0);
    expect(a.calls, isEmpty);
  });

  test('sin señal / con señal cambia el aviso del shell', () async {
    await start();
    final n = c.read(syncProvider.notifier);
    n.markOffline(DateTime(2026, 11, 8, 9, 30));
    expect(c.read(syncProvider).offline, isTrue);
    n.markOnline();
    expect(c.read(syncProvider).offline, isFalse);
  });
}
