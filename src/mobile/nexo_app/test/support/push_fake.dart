import 'dart:async';

import 'package:nexo_app/features/push/push_gateway.dart';

/// Proveedor de push controlado por la prueba (sin Firebase).
class FakePushGateway implements PushGateway {
  bool initOk = true;
  bool granted = false;
  bool grantOnRequest = true;
  String? currentToken = 'tok-abc';
  int deletes = 0;
  PushMessage? initial;
  final fg = StreamController<PushMessage>.broadcast();
  final opened = StreamController<PushMessage>.broadcast();
  final refresh = StreamController<String>.broadcast();

  @override
  Future<bool> init() async => initOk;
  @override
  Future<bool> isGranted() async => granted;
  @override
  Future<bool> requestPermission() async => granted = grantOnRequest;
  @override
  Future<String?> token() async => currentToken;
  @override
  Future<void> deleteToken() async {
    deletes++;
  }

  @override
  Stream<String> get onTokenRefresh => refresh.stream;
  @override
  Stream<PushMessage> get onForeground => fg.stream;
  @override
  Stream<PushMessage> get onOpened => opened.stream;
  @override
  Future<PushMessage?> initialMessage() async => initial;
}
