import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/env.dart';
import '../../app/router.dart';
import '../../core/auth/session_controller.dart';
import '../../core/auth/token_storage.dart';
import '../../data/api_provider.dart';
import 'firebase_push_gateway.dart';
import 'push_gateway.dart';

class PushState {
  const PushState({this.available = false, this.enabled = false});

  /// El proveedor (Firebase) está configurado en este build.
  final bool available;

  /// Permiso concedido y teléfono registrado (o en proceso).
  final bool enabled;
}

final pushGatewayProvider = Provider<PushGateway>((ref) => FirebasePushGateway());

/// Abre la pantalla de un aviso. Se separa para poder probarlo sin router.
final pushNavigatorProvider = Provider<void Function(String path)>((ref) => (path) => ref.read(routerProvider).push(path));

/// Notificaciones push de los procesos principales: interés en una
/// solicitud, pedido aceptado o resuelto y mensajes nuevos (spec 050).
class PushController extends Notifier<PushState> {
  final List<StreamSubscription<Object?>> _subs = [];

  /// Aviso tocado antes de que se restaurara la sesión.
  String? _pending;

  PushGateway get _gw => ref.read(pushGatewayProvider);
  TokenStorage get _storage => ref.read(tokenStorageProvider);

  @override
  PushState build() {
    ref.onDispose(() {
      for (final s in _subs) {
        s.cancel();
      }
    });
    // Al iniciar sesión (o restaurarla) se registra el teléfono.
    ref.listen<bool>(sessionProvider.select((s) => s.isSignedIn), (prev, now) {
      if (!now || prev == true) return;
      if (state.enabled) unawaited(_register());
      final p = _pending;
      if (p != null) {
        _pending = null;
        // Deja que el router salga de la pantalla inicial primero.
        Future<void>.delayed(const Duration(milliseconds: 300), () => ref.read(pushNavigatorProvider)(p));
      }
    });
    Future.microtask(_init);
    return const PushState();
  }

  Future<void> _init() async {
    if (!await _gw.init()) return;
    final granted = await _gw.isGranted();
    state = PushState(available: true, enabled: granted);
    _subs
      ..add(_gw.onForeground.listen(_onForeground))
      ..add(_gw.onOpened.listen((m) => open(m.link)))
      ..add(_gw.onTokenRefresh.listen((t) => _register(token: t)));
    final first = await _gw.initialMessage();
    if (first != null) open(first.link);
    if (granted && ref.read(sessionProvider).isSignedIn) await _register();
  }

  /// La app está abierta: se refresca la actividad y se muestra el aviso.
  void _onForeground(PushMessage m) {
    final text = (m.title ?? m.body ?? '').trim();
    ref.read(serverEventsProvider.notifier).push(text.isEmpty ? 'chat' : text);
  }

  /// Solo rutas internas conocidas (spec 046: enlaces profundos).
  bool open(String? link) {
    final path = Routes.fromDeepLink(link);
    if (path == null) return false;
    if (ref.read(sessionProvider).isSignedIn) {
      ref.read(pushNavigatorProvider)(path);
    } else {
      _pending = path;
    }
    return true;
  }

  /// ¿Mostrar la pantalla previa al permiso? Una sola vez por sesión.
  Future<bool> shouldAsk() async =>
      state.available && !state.enabled && ref.read(sessionProvider).isSignedIn && !await _storage.readPushAsked();

  Future<void> markAsked() => _storage.writePushAsked();

  Future<bool> enable() async {
    if (!state.available) return false;
    final ok = await _gw.requestPermission();
    state = PushState(available: true, enabled: ok);
    if (ok) await _register();
    return ok;
  }

  /// Desactivar avisos o cerrar sesión: baja en el backend y token borrado.
  Future<void> disable() async {
    final id = await _storage.readDeviceId();
    if (id != null && id.isNotEmpty) {
      try {
        await ref.read(apiProvider).removeDevice(id);
      } catch (_) {
        // El backend lo limpia solo a los 90 días (TTL del contrato).
      }
      await _storage.writeDeviceId(null);
    }
    if (state.available) {
      try {
        await _gw.deleteToken();
      } catch (_) {}
    }
    state = PushState(available: state.available, enabled: false);
  }

  Future<void> _register({String? token}) async {
    if (!ref.read(sessionProvider).isSignedIn) return;
    try {
      final t = token ?? await _gw.token();
      if (t == null || t.isEmpty) return;
      final id = await ref.read(apiProvider).registerDevice(fcmToken: t, appVersion: Env.appVersion);
      await _storage.writeDeviceId(id);
    } catch (e) {
      // Nunca se registra el token en el log.
      if (kDebugMode) debugPrint('[PUSH] registro pendiente: ${e.runtimeType}');
    }
  }
}

final pushProvider = NotifierProvider<PushController, PushState>(PushController.new);
