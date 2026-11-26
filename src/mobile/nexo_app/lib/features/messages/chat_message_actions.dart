import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../core/widgets/nexo_motion.dart';
import 'chat_backdrop.dart';

class ChatMessageAction {
  const ChatMessageAction(this.kind, [this.text]);

  /// `copy`, `edit` o `delete`.
  final String kind;
  final String? text;
}

/// Menú flotante junto al mensaje: el fondo se difumina, el mensaje se queda en
/// su sitio y las acciones aparecen pegadas a él. [anchor] es su posición en
/// pantalla; sin ella el conjunto se centra.
Future<ChatMessageAction?> showChatMessageActions(
  BuildContext context, {
  required String text,
  required bool canEdit,
  required String style,
  required String kind,
  bool canDelete = true,
  bool mine = true,
  String? time,
  Rect? anchor,
}) async {
  final result = await showGeneralDialog<ChatMessageAction>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Cerrar opciones del mensaje',
    barrierColor: Colors.transparent,
    transitionDuration: NexoMotion.duration(context, const Duration(milliseconds: 170)),
    pageBuilder: (_, __, ___) => _MessageMenu(
      text: text,
      canEdit: canEdit,
      canDelete: canDelete,
      mine: mine,
      time: time,
      style: style,
      kind: kind,
      anchor: anchor,
    ),
    transitionBuilder: (_, animation, __, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    ),
  );
  if (result?.kind != 'delete' || !context.mounted) return result;
  return await _confirmDelete(context) ? result : null;
}

/// Confirmación breve y centrada antes de borrar para ambos.
Future<bool> _confirmDelete(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierColor: const Color(0x66141F1C),
    builder: (dialog) => Dialog(
      backgroundColor: NexoColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 36),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 22, 14, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('¿Eliminar mensaje?', style: NexoText.display(18)),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  'Se eliminará para ambos. Las copias o capturas ya hechas no se borran.',
                  style: NexoText.body(14, color: NexoColors.muted, height: 1.45),
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                alignment: WrapAlignment.end,
                spacing: 4,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(dialog, false),
                    style: TextButton.styleFrom(foregroundColor: NexoColors.ink, minimumSize: const Size(0, 48)),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(dialog, true),
                    style: TextButton.styleFrom(foregroundColor: NexoColors.danger, minimumSize: const Size(0, 48)),
                    child: const Text('Eliminar para todos'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
  return confirmed == true;
}

class _MessageMenu extends StatelessWidget {
  const _MessageMenu({
    required this.text,
    required this.canEdit,
    required this.canDelete,
    required this.mine,
    required this.time,
    required this.style,
    required this.kind,
    required this.anchor,
  });
  final String text, style, kind;
  final String? time;
  final bool canEdit, canDelete, mine;
  final Rect? anchor;

  static const _rowHeight = 48.0, _menuWidth = 208.0, _gap = 8.0;

  Widget _bubble(ChatPalette p) {
    final foreground = mine ? Colors.white : p.ink;
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.fromLTRB(13, 9, 11, 6),
      decoration: BoxDecoration(
        color: mine ? p.sent : p.received,
        borderRadius: BorderRadius.circular(18).copyWith(
          bottomRight: mine ? const Radius.circular(5) : null,
          bottomLeft: mine ? null : const Radius.circular(5),
        ),
        boxShadow: const [BoxShadow(color: Color(0x40000000), blurRadius: 18, offset: Offset(0, 6))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (kind != 'text') ...[
                Icon(kind == 'image' ? Icons.image_outlined : Icons.mic_none_rounded, color: foreground, size: 19),
                const SizedBox(width: 7),
              ],
              Flexible(
                child: Text(
                  text.isNotEmpty
                      ? text
                      : kind == 'image'
                      ? 'Foto'
                      : 'Nota de voz',
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                  style: NexoText.body(15, color: foreground, height: 1.3),
                ),
              ),
            ],
          ),
          if (time?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(time!, style: NexoText.body(11, color: foreground.withValues(alpha: .72))),
            ),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String label, String action, {Color color = NexoColors.ink}) =>
      InkWell(
        onTap: () => Navigator.pop(context, ChatMessageAction(action, action == 'copy' ? text : null)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: _rowHeight),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: NexoText.body(15, weight: FontWeight.w600, color: color),
                  ),
                ),
                Icon(icon, size: 20, color: color),
              ],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[
      if (text.isNotEmpty) _item(context, Icons.copy_rounded, 'Copiar', 'copy'),
      if (canEdit) _item(context, Icons.edit_outlined, 'Editar', 'edit'),
      if (canDelete) _item(context, Icons.delete_outline_rounded, 'Eliminar', 'delete', color: NexoColors.danger),
    ];
    final media = MediaQuery.of(context);
    final menu = SizedBox(
      width: _menuWidth,
      child: Material(
        color: NexoColors.surface,
        elevation: 10,
        shadowColor: Colors.black45,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final (index, item) in items.indexed) ...[
              if (index > 0) const Divider(height: 1, color: NexoColors.line),
              item,
            ],
          ],
        ),
      ),
    );
    final group = Material(
      type: MaterialType.transparency,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: mine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          _bubble(ChatPalette.forStyle(style)),
          const SizedBox(height: _gap),
          menu,
        ],
      ),
    );
    // Espacio que ocupa el conjunto para que nunca se salga por abajo.
    final menuHeight = items.length * (_rowHeight + 1) + _gap;
    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => Navigator.pop(context),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
              child: const ColoredBox(color: Color(0x73101A18)),
            ),
          ),
        ),
        Positioned.fill(
          child: SafeArea(
            minimum: const EdgeInsets.all(12),
            child: anchor == null
                ? Center(child: SingleChildScrollView(child: group))
                : LayoutBuilder(
                    builder: (context, box) {
                      final inset = media.padding.top > 12 ? media.padding.top : 12.0;
                      final wanted = anchor!.top - inset;
                      final bubbleHeight = anchor!.height.clamp(40.0, 190.0);
                      final lowest = box.maxHeight - menuHeight - bubbleHeight - 12;
                      final top = wanted.clamp(0.0, lowest < 0 ? 0.0 : lowest);
                      return Align(
                        alignment: mine ? Alignment.topRight : Alignment.topLeft,
                        child: Padding(
                          padding: EdgeInsets.only(top: top),
                          child: SingleChildScrollView(child: group),
                        ),
                      );
                    },
                  ),
          ),
        ),
      ],
    );
  }
}
