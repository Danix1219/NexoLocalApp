import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/core/auth/session_controller.dart';
import 'package:nexo_app/core/auth/token_storage.dart';
import 'package:nexo_app/core/network/api_client.dart';

import '../support/fixtures.dart';
import '../support/mock_adapter.dart';

/// Specs 004/041/026: sesión, modo y Bearer en las peticiones.
void main() {
  late MemoryTokenStorage storage;
  late ProviderContainer c;

  setUp(() async {
    storage = MemoryTokenStorage();
    c = ProviderContainer(overrides: [tokenStorageProvider.overrideWithValue(storage)]);
    c.read(sessionProvider);
    await Future<void>.delayed(Duration.zero);
  });
  tearDown(() => c.dispose());

  test('sin tokens arranca sin sesión; visitante entra y sale', () {
    expect(c.read(sessionProvider).status, SessionStatus.signedOut);
    c.read(sessionProvider.notifier).enterGuest();
    expect(c.read(sessionProvider).isGuest, isTrue);
    c.read(sessionProvider.notifier).leaveGuest();
    expect(c.read(sessionProvider).status, SessionStatus.signedOut);
  });

  test('iniciar sesión lee claims y guarda nombre', () async {
    await c.read(sessionProvider.notifier).signIn(fakeTokens(sub: 'acc_7'), name: 'Ana');
    final s = c.read(sessionProvider);
    expect(s.isSignedIn, isTrue);
    expect(s.accountId, 'acc_7');
    expect(s.mode, 'client');
    expect(storage.data['name'], 'Ana');
  });

  test('cambio de modo sin tokens se guarda en el teléfono y sobrevive al refresh', () async {
    await c.read(sessionProvider.notifier).signIn(fakeTokens());
    await c.read(sessionProvider.notifier).setMode('provider', hasProvider: true);
    expect(c.read(sessionProvider).isProviderMode, isTrue);
    await c.read(sessionProvider.notifier).updateTokens(fakeTokens());
    expect(c.read(sessionProvider).mode, 'provider');
  });

  test('cambio de modo con tokens del backend usa el claim', () async {
    await c.read(sessionProvider.notifier).signIn(fakeTokens());
    await c.read(sessionProvider.notifier).setMode('provider', tokens: fakeTokens(mode: 'provider', hasProvider: true));
    final s = c.read(sessionProvider);
    expect(s.mode, 'provider');
    expect(s.hasProvider, isTrue);
    expect(storage.data.containsKey('mode'), isFalse);
  });

  test('el interceptor pone el Bearer solo en peticiones marcadas', () async {
    await storage.write(fakeTokens(sub: 'acc_1'));
    final a = MockAdapter()
      ..on('GET', '/privado', {'ok': true})
      ..on('GET', '/publico', {'ok': true});
    final dio = testDio(a);
    final p = Provider<AuthInterceptor>((ref) => AuthInterceptor(ref, dio));
    dio.interceptors.add(c.read(p));
    await dio.get<dynamic>('/privado', options: Options(extra: const {kAuth: true}));
    await dio.get<dynamic>('/publico');
    expect(a.last('GET', '/privado').header('Authorization'), startsWith('Bearer '));
    expect(a.last('GET', '/publico').header('Authorization'), isNull);
  });

  test('un 401 en petición pública no intenta renovar ni cierra sesión', () async {
    await c.read(sessionProvider.notifier).signIn(fakeTokens());
    final a = MockAdapter()..on('GET', '/publico', {'code': 'x'}, status: 401);
    final dio = testDio(a);
    final p = Provider<AuthInterceptor>((ref) => AuthInterceptor(ref, dio));
    dio.interceptors.add(c.read(p));
    await expectLater(dio.get<dynamic>('/publico'), throwsA(isA<DioException>()));
    expect(c.read(sessionProvider).isSignedIn, isTrue);
    expect(a.calls, hasLength(1));
  });
}
