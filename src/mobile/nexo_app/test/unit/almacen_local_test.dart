import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/core/local/local_store.dart';

/// Spec 051: caché y cola por cuenta, con límites.
void main() {
  final t0 = DateTime(2026, 11, 8, 10);
  CachedResponse r(String body, [int min = 0]) => CachedResponse(body: body, savedAt: t0.add(Duration(minutes: min)));
  OutboxItem item(String account, String idem) => OutboxItem(
        account: account,
        method: 'POST',
        path: '/v1/discovery/requests',
        body: '{}',
        idempotencyKey: idem,
        createdAt: t0,
      );

  test('cada cuenta ve solo lo suyo', () async {
    final s = MemoryLocalStore();
    await s.write('acc_1', '/v1/x', r('{"a":1}'));
    expect((await s.read('acc_1', '/v1/x'))!.body, '{"a":1}');
    expect(await s.read('acc_2', '/v1/x'), isNull);
  });

  test('respuestas enormes no se guardan', () async {
    final s = MemoryLocalStore();
    await s.write('acc_1', 'k', r('x' * (LocalStore.maxBodyBytes + 1)));
    expect(await s.read('acc_1', 'k'), isNull);
  });

  test('al pasar el límite se borra la entrada más vieja', () async {
    final s = MemoryLocalStore();
    for (var i = 0; i <= LocalStore.maxEntries; i++) {
      await s.write('acc_1', 'k$i', r('{}', i));
    }
    expect(await s.read('acc_1', 'k0'), isNull);
    expect(await s.read('acc_1', 'k${LocalStore.maxEntries}'), isNotNull);
  });

  test('la cola no duplica la misma Idempotency-Key', () async {
    final s = MemoryLocalStore();
    final a = await s.enqueue(item('acc_1', 'idem-1'));
    final b = await s.enqueue(item('acc_1', 'idem-1'));
    expect(a, b);
    expect(await s.pending('acc_1'), hasLength(1));
  });

  test('reintentos se cuentan y se puede quitar de la cola', () async {
    final s = MemoryLocalStore();
    final id = await s.enqueue(item('acc_1', 'idem-1'));
    await s.bumpAttempt(id);
    expect((await s.pending('acc_1')).single.attempts, 1);
    await s.removeOutbox(id);
    expect(await s.pending('acc_1'), isEmpty);
  });

  test('purgar una cuenta no toca a las demás', () async {
    final s = MemoryLocalStore();
    await s.write('acc_1', 'k', r('{}'));
    await s.write('acc_2', 'k', r('{}'));
    await s.enqueue(item('acc_1', 'i1'));
    await s.enqueue(item('acc_2', 'i2'));
    await s.purgeAccount('acc_1');
    expect(await s.read('acc_1', 'k'), isNull);
    expect(await s.pending('acc_1'), isEmpty);
    expect(await s.read('acc_2', 'k'), isNotNull);
    expect(await s.pending('acc_2'), hasLength(1));
  });
}
