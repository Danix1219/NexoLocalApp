import 'package:sqflite/sqflite.dart';
import 'package:nexo_app/core/auth/auth_tokens.dart';
import '../support/fixtures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/core/auth/token_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('expired session refresh opens Android SQLite using query for result-producing pragma', () async {
    databaseFactory = databaseFactorySqflitePlugin;
    final calls = <MethodCall>[];
    const channel = MethodChannel('com.tekartik.sqflite');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      final args = call.arguments is Map ? call.arguments as Map : const {};
      final sql = args['sql']?.toString() ?? '';
      if (call.method == 'getDatabasesPath') return '/unit-db';
      if (call.method == 'openDatabase') return {'id': 42};
      if (call.method == 'query') {
        return [
          {'value': 25000},
        ];
      }
      if (call.method == 'execute' && sql.startsWith('PRAGMA busy_timeout')) {
        throw PlatformException(code: 'sqlite_error', message: 'Queries must use rawQuery');
      }
      if (call.method == 'execute' && sql.startsWith('BEGIN')) return {'transactionId': 1};
      return null;
    });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null),
    );
    final storage = MemoryTokenStorage();
    final old = AuthTokens(accessToken: 'expired', refreshToken: 'test', expiresAt: DateTime(2020));
    final fresh = AuthTokens(accessToken: 'renewed', refreshToken: 'rotated', expiresAt: DateTime(2030));
    await storage.write(old);
    var refreshes = 0;
    final result = await storage.refreshCoordinated(old, (_) async {
      refreshes++;
      return fresh;
    });
    expect(result?.accessToken, 'renewed');
    expect((await storage.read())?.accessToken, 'renewed');
    // An overlapping request with the old token reuses the already renewed one.
    await storage.refreshCoordinated(old, (_) async {
      refreshes++;
      return fresh;
    });
    expect(refreshes, 1);
    expect(
      calls.where((c) => c.method == 'query' && (c.arguments as Map)['sql'] == 'PRAGMA busy_timeout = 25000'),
      isNotEmpty,
    );
  });
  test('logout only deletes session keys and never all secure storage', () async {
    final calls = <MethodCall>[];
    const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null),
    );
    final storage = TokenStorage();
    await storage.read();
    await storage.clear();
    expect(calls.where((c) => c.method == 'deleteAll'), isEmpty);
    expect(calls.where((c) => c.method == 'delete').length, 6);
    final deleted = calls.where((c) => c.method == 'delete').map((c) => (c.arguments as Map)['key']);
    expect(deleted, everyElement(startsWith('nexo.')));
    // La decisión sobre los avisos es del teléfono y sobrevive al cierre.
    expect(deleted, isNot(contains('nexo.pushAsked')));
    expect(deleted, isNot(contains('nexo.pushOff')));
  });
}
