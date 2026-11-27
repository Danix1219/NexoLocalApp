import 'dart:async';
import 'package:dio/dio.dart';
import 'package:signalr_netcore/signalr_client.dart';

import '../../app/env.dart';
import '../../core/network/api_client.dart';

/// Chat en vivo (`/hubs/chat`, SignalR). Solo avisa: los mensajes se envían y se leen por HTTP, así que si la
/// conexión no se logra o se cae, la pantalla sigue funcionando con su recarga periódica.
class ChatLive {
  ChatLive(this._dio, this._onChange);

  final Dio _dio;
  final void Function(String conversationId) _onChange;
  HubConnection? _hub;
  int _generation = 0;
  Timer? _retry;

  Future<void> start() async {
    if (Env.apiMode == 'fake') return;
    _retry?.cancel();
    final generation = ++_generation;
    final previous = _hub;
    _hub = null;
    try {
      await previous?.stop();
      if (generation != _generation) return;
      // Ticket de un solo uso (60 s): el token de sesión nunca viaja en la URL del WebSocket.
      final r = await _dio.post<Map<String, dynamic>>(
        '/v1/engagement/hubs/chat/ticket',
        options: Options(extra: const {kAuth: true}),
      );
      final ticket = r.data?['ticket'] as String?;
      if (ticket == null || generation != _generation) return;
      final negotiate = r.data?['negotiate'] == true;
      final hub = HubConnectionBuilder()
          .withUrl(
            '${Env.apiBaseUrl}/hubs/chat?ticket=$ticket',
            options: HttpConnectionOptions(transport: HttpTransportType.WebSockets, skipNegotiation: !negotiate),
          )
          .build();
      for (final event in const [
        'messageReceived',
        'messageRead',
        'messageDelivered',
        'messageUpdated',
        'conversationBlocked',
      ]) {
        hub.on(event, (args) {
          final payload = args?.firstOrNull;
          final id = payload is Map ? payload['conversationId']?.toString() : null;
          if (id != null) _onChange(id);
        });
      }
      _hub = hub;
      hub.onclose(({error}) {
        if (generation == _generation) {
          _retry?.cancel();
          _retry = Timer(const Duration(seconds: 3), () async {
            if (generation == _generation) await start();
          });
        }
      });
      await hub.start();
      if (generation != _generation) await hub.stop();
    } catch (_) {
      if (generation == _generation) {
        _retry?.cancel();
        _retry = Timer(const Duration(seconds: 5), () async {
          if (generation == _generation) await start();
        });
      }
      // Sin tiempo real: queda la recarga periódica de la pantalla.
    }
  }

  Future<void> stop() async {
    _retry?.cancel();
    _retry = null;
    ++_generation;
    final hub = _hub;
    _hub = null;
    try {
      await hub?.stop();
    } catch (_) {}
  }
}
