/// Aviso push ya reducido a lo que la app usa. El cuerpo nunca trae datos
/// sensibles (contrato de notificaciones); el dato real se pide a la API.
class PushMessage {
  const PushMessage({this.title, this.body, this.link});
  final String? title;
  final String? body;

  /// `deepLink` (`nexolocal://…`). Se valida con `Routes.fromDeepLink`.
  final String? link;

  factory PushMessage.fromData(Map<String, dynamic> data, {String? title, String? body}) => PushMessage(
        title: title ?? data['title']?.toString(),
        body: body ?? data['body']?.toString(),
        link: (data['deepLink'] ?? data['link'])?.toString(),
      );
}

/// Frontera con el proveedor de push (Firebase Cloud Messaging). Permite
/// probar el controlador sin Firebase.
abstract class PushGateway {
  /// false si el proyecto no tiene `google-services.json`: la app funciona
  /// igual, solo sin push (la bandeja de avisos sigue disponible).
  Future<bool> init();
  Future<bool> isGranted();
  Future<bool> requestPermission();
  Future<String?> token();
  Future<void> deleteToken();
  Stream<String> get onTokenRefresh;
  Stream<PushMessage> get onForeground;
  Stream<PushMessage> get onOpened;
  Future<PushMessage?> initialMessage();
}

/// Sin proveedor configurado.
class NoPushGateway implements PushGateway {
  const NoPushGateway();
  @override
  Future<bool> init() async => false;
  @override
  Future<bool> isGranted() async => false;
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<String?> token() async => null;
  @override
  Future<void> deleteToken() async {}
  @override
  Stream<String> get onTokenRefresh => const Stream.empty();
  @override
  Stream<PushMessage> get onForeground => const Stream.empty();
  @override
  Stream<PushMessage> get onOpened => const Stream.empty();
  @override
  Future<PushMessage?> initialMessage() async => null;
}
