import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nexo_app/features/push/chat_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
  TestWidgetsFlutterBinding.ensureInitialized();
  test('shortcut retries missing avatar and updates it when photo becomes available', () async {
    const channel = MethodChannel('mx.nexolocal/chat-notifications');
    final calls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return null;
    });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null),
    );
    await ChatNotifications.prepareShortcut('avatar-test', 'thread', 'Contacto', null);
    await ChatNotifications.prepareShortcut(
      'avatar-test',
      'thread',
      'Contacto',
      null,
      image: Uint8List.fromList([1, 2, 3]),
    );
    await ChatNotifications.prepareShortcut(
      'avatar-test',
      'thread',
      'Contacto',
      null,
      image: Uint8List.fromList([1, 2, 3]),
    );
    expect(calls, hasLength(2));
    expect((calls.first.arguments as Map).containsKey('avatar'), isFalse);
    expect((calls.last.arguments as Map)['avatar'], [1, 2, 3]);
  });
  test('avatar permits local debug storage but requires TLS in release', () {
    for (final url in ['http://127.0.0.1:10000/avatar.png', 'http://192.168.1.5/avatar.png']) {
      expect(ChatNotifications.allowsAvatarUrl(Uri.parse(url), release: false), isTrue);
      expect(ChatNotifications.allowsAvatarUrl(Uri.parse(url), release: true), isFalse);
    }
    expect(ChatNotifications.allowsAvatarUrl(Uri.parse('https://cdn.example/avatar.png'), release: true), isTrue);
    for (final url in ['http://public.example/avatar.png', 'file:///avatar.png', 'https://user:pass@cdn.example/a']) {
      expect(ChatNotifications.allowsAvatarUrl(Uri.parse(url), release: false), isFalse);
    }
  });
  test('notification previews describe private attachments without leaking their metadata', () {
    expect(ChatNotifications.preview('image', 'secret file metadata'), '\u{1f4f7} Foto');
    expect(ChatNotifications.preview('audio', 'secret file metadata'), '\u{1f3a4} Nota de voz');
    expect(ChatNotifications.preview('encrypted', 'ciphertext'), 'Nuevo mensaje');
    expect(ChatNotifications.preview('text', ' Hola '), 'Hola');
  });
  test('visible chat suppresses only its own notification and resumes after leaving', () {
    ChatNotifications.isViewing = (id) => id == 'open';
    expect(ChatNotifications.shouldDisplay('account-a', 'open', 'new'), isFalse);
    expect(ChatNotifications.shouldDisplay('account-a', 'other', 'new'), isTrue);
    ChatNotifications.isViewing = null;
    expect(ChatNotifications.shouldDisplay('account-a', 'open', 'new'), isTrue);
  });
  test('persisted read watermark suppresses a delayed push without suppressing a newer message', () {
    expect(ChatNotifications.shouldDisplay('a', 'chat', 'read', persistedRead: 'read'), isFalse);
    expect(ChatNotifications.shouldDisplay('a', 'chat', 'new', persistedRead: 'read'), isTrue);
    expect(ChatNotifications.shouldDisplay('b', 'chat', 'new'), isTrue);
  });
  test('older UUIDv7 notification cannot revive after a later read receipt', () {
    const previous = '019a9340-0000-7000-8000-000000000001';
    const read = '019a9341-0000-7000-8000-000000000001';
    const next = '019a9342-0000-7000-8000-000000000001';
    expect(ChatNotifications.shouldDisplay('a', 'chat', previous, persistedRead: read), isFalse);
    expect(ChatNotifications.shouldDisplay('a', 'chat', next, persistedRead: read), isTrue);
  });
  test('notification read markers survive a new storage instance and are purged on logout', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final first = TokenStorage();
    await first.writeChatRead('a', 'chat', 'message');
    final background = TokenStorage();
    expect(await background.readChatRead('a', 'chat'), 'message');
    expect(await background.readChatRead('b', 'chat'), isNull);
    expect(await background.readChatRead('a', 'different'), isNull);
    await first.clear();
    expect(await background.readChatRead('a', 'chat'), isNull);
  });
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
    final c = ProviderContainer(
      overrides: [
        tokenStorageProvider.overrideWithValue(storage),
        localStoreProvider.overrideWithValue(Future.value(MemoryLocalStore())),
        pushGatewayProvider.overrideWithValue(gw),
        pushNavigatorProvider.overrideWithValue(nav.add),
        apiProvider.overrideWithValue(HttpNexoApi(testDio(a))),
      ],
    );
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
