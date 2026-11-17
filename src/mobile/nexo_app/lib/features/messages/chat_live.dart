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

  Future<void> start() async {
    if (Env.apiMode == 'fake') return;
    try {
      // Ticket de un solo uso (60 s): el token de sesión nunca viaja en la URL del WebSocket.
      final r = await _dio.post<Map<String, dynamic>>('/v1/engagement/hubs/chat/ticket',
          options: Options(extra: const {kAuth: true}));
      final ticket = r.data?['ticket'] as String?;
      if (ticket == null) return;
      final hub = HubConnectionBuilder()
          .withUrl('${Env.apiBaseUrl}/hubs/chat?ticket=$ticket',
              // Solo WebSocket y sin negociación: no requiere afinidad de sesión entre las réplicas del App Service.
              options: HttpConnectionOptions(transport: HttpTransportType.WebSockets, skipNegotiation: true))
          .build();
      for (final event in const ['messageReceived', 'messageRead', 'conversationBlocked']) {
        hub.on(event, (args) {
          final payload = args?.firstOrNull;
          final id = payload is Map ? payload['conversationId']?.toString() : null;
          if (id != null) _onChange(id);
        });
      }
      await hub.start();
      _hub = hub;
    } catch (_) {
      // Sin tiempo real: queda la recarga periódica de la pantalla.
    }
  }

  Future<void> stop() async {
    final hub = _hub;
    _hub = null;
    try {
      await hub?.stop();
    } catch (_) {}
  }
}
