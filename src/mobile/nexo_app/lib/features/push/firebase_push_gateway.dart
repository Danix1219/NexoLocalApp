import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'push_gateway.dart';

/// Con la app cerrada, Android muestra la notificación por sí solo; aquí no
/// se procesa nada más (sin red ni almacenamiento en segundo plano).
@pragma('vm:entry-point')
Future<void> nexoPushBackground(RemoteMessage message) async {}

PushMessage _map(RemoteMessage m) =>
    PushMessage.fromData(m.data, title: m.notification?.title, body: m.notification?.body);

class FirebasePushGateway implements PushGateway {
  FirebaseMessaging get _fm => FirebaseMessaging.instance;

  @override
  Future<bool> init() async {
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      FirebaseMessaging.onBackgroundMessage(nexoPushBackground);
      return true;
    } catch (_) {
      // Sin google-services.json (p. ej. build de CI sin secreto): sin push.
      return false;
    }
  }

  bool _ok(AuthorizationStatus s) => s == AuthorizationStatus.authorized || s == AuthorizationStatus.provisional;

  @override
  Future<bool> isGranted() async => _ok((await _fm.getNotificationSettings()).authorizationStatus);

  @override
  Future<bool> requestPermission() async => _ok((await _fm.requestPermission()).authorizationStatus);

  @override
  Future<String?> token() => _fm.getToken();

  @override
  Future<void> deleteToken() => _fm.deleteToken();

  @override
  Stream<String> get onTokenRefresh => _fm.onTokenRefresh;

  @override
  Stream<PushMessage> get onForeground => FirebaseMessaging.onMessage.map(_map);

  @override
  Stream<PushMessage> get onOpened => FirebaseMessaging.onMessageOpenedApp.map(_map);

  @override
  Future<PushMessage?> initialMessage() async {
    final m = await _fm.getInitialMessage();
    return m == null ? null : _map(m);
  }
}
