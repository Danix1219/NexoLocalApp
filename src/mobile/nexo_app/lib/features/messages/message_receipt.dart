import '../../data/models.dart';
import 'package:flutter/material.dart';

/// Server-confirmed states only; a socket event is not a delivery receipt.
class MessageReceipt extends StatelessWidget {
  const MessageReceipt({super.key, required this.deliveredAt, required this.readAt, this.compact = false});
  final bool compact;
  final DateTime? deliveredAt;
  final DateTime? readAt;
  @override
  Widget build(BuildContext context) {
    final read = readAt != null;
    final delivered = read || deliveredAt != null;
    final label = read
        ? 'Le\u00eddo'
        : delivered
        ? 'Entregado'
        : 'Enviado';
    final color = read ? const Color(0xFF53D7FF) : Colors.white70;
    return Semantics(
      label: 'Mensaje $label',
      child: Tooltip(
        message: label,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(delivered ? Icons.done_all_rounded : Icons.done_rounded, size: 18, color: color),
            if (!compact) const SizedBox(width: 4),
            if (!compact)
              Text(
                label,
                style: TextStyle(fontSize: 10, color: color, fontWeight: read ? FontWeight.w700 : FontWeight.w400),
              ),
          ],
        ),
      ),
    );
  }
}

/// Older unavailable ciphertext must not block newer readable messages.
Message? latestReadableIncoming(Iterable<Message> messages) =>
    messages.where((message) => !message.mine && message.kind != 'system' && message.kind != 'unavailable').lastOrNull;
