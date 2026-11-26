import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';

const chatBackgrounds = <(String, String, Color)>[
  ('linen', 'Lino', Color(0xFFF5F2EB)),
  ('mint', 'Jard\u00edn', Color(0xFFE6F1EB)),
  ('sky', 'Brisa', Color(0xFFEAF1F8)),
  ('peach', 'Terracota', Color(0xFFF8EDE5)),
  ('night', 'Noche', Color(0xFF203337)),
  ('nexo', 'Nexo', Color(0xFFEDF3EF)),
  ('lilac', 'Lavanda', Color(0xFFF0EDF7)),
];

/// Preferencias locales de una conversación. Se guardan como texto; el valor
/// anterior (solo el tema, p. ej. `night`) sigue siendo válido.
@immutable
class ChatStyle {
  const ChatStyle({this.theme = 'linen', this.pattern = true, this.textSize = 'normal', this.rounded = true});

  factory ChatStyle.decode(String? value) {
    final parts = (value ?? '').split('|');
    final options = parts.skip(1).toSet();
    return ChatStyle(
      theme: chatBackgrounds.any((s) => s.$1 == parts.first) ? parts.first : 'linen',
      pattern: !options.contains('plain'),
      textSize: options.contains('compact')
          ? 'compact'
          : options.contains('large')
          ? 'large'
          : 'normal',
      rounded: !options.contains('square'),
    );
  }

  final String theme, textSize;
  final bool pattern, rounded;

  double get fontSize => switch (textSize) {
    'compact' => 13.5,
    'large' => 17.5,
    _ => 15,
  };
  double get radius => rounded ? 20 : 10;

  String encode() =>
      [theme, if (!pattern) 'plain', if (textSize != 'normal') textSize, if (!rounded) 'square'].join('|');

  ChatStyle copyWith({String? theme, bool? pattern, String? textSize, bool? rounded}) => ChatStyle(
    theme: theme ?? this.theme,
    pattern: pattern ?? this.pattern,
    textSize: textSize ?? this.textSize,
    rounded: rounded ?? this.rounded,
  );
}

/// All outgoing palettes use white foregrounds with readable contrast.
class ChatPalette {
  const ChatPalette(this.sent, this.received, this.ink, this.muted, this.soft);
  final Color sent, received, ink, muted, soft;
  static ChatPalette forStyle(String style) => switch (style) {
    'mint' => const ChatPalette(
      Color(0xFF286447),
      Color(0xFFF7FCF8),
      Color(0xFF193D2C),
      Color(0xFF4D6859),
      Color(0xFFD5E8DC),
    ),
    'sky' => const ChatPalette(
      Color(0xFF315F86),
      Color(0xFFF8FBFF),
      Color(0xFF203C55),
      Color(0xFF526B82),
      Color(0xFFD9E6F2),
    ),
    'peach' => const ChatPalette(
      Color(0xFF914D38),
      Color(0xFFFFFAF6),
      Color(0xFF553326),
      Color(0xFF795B4E),
      Color(0xFFF0DCCF),
    ),
    'night' => const ChatPalette(
      Color(0xFF405B79),
      Color(0xFF30464C),
      Color(0xFFF2F6F8),
      Color(0xFFBDCDD2),
      Color(0xFF30464C),
    ),
    'nexo' => const ChatPalette(
      Color(0xFF17695D),
      Color(0xFFFFFEFB),
      Color(0xFF1C2926),
      Color(0xFF55645F),
      Color(0xFFDCEBE5),
    ),
    'lilac' => const ChatPalette(
      Color(0xFF5B4B8A),
      Color(0xFFFCFBFF),
      Color(0xFF2F2748),
      Color(0xFF615878),
      Color(0xFFE2DCF0),
    ),
    _ => const ChatPalette(
      Color(0xFF6D5945),
      Color(0xFFFFFDF9),
      Color(0xFF40382F),
      Color(0xFF6F6559),
      Color(0xFFE9E0D3),
    ),
  };
}

class ChatBackdrop extends StatelessWidget {
  const ChatBackdrop({super.key, required this.style, required this.child, this.pattern = true});
  final String style;
  final bool pattern;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final index = chatBackgrounds.indexWhere((s) => s.$1 == style);
    final choice = chatBackgrounds[index < 0 ? 0 : index];
    return ColoredBox(
      color: choice.$3,
      child: CustomPaint(painter: pattern ? _Pattern(choice.$1) : null, child: child),
    );
  }
}

class _Pattern extends CustomPainter {
  const _Pattern(this.style);
  final String style;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = (style == 'night' ? Colors.white : const Color(0xFF196C60)).withValues(alpha: .065)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    for (double y = 18; y < size.height; y += 72) {
      for (double x = 18; x < size.width; x += 72) {
        final dx = x + ((y ~/ 72).isOdd ? 24 : 0);
        if (style == 'mint' || style == 'peach') {
          canvas.drawOval(Rect.fromCenter(center: Offset(dx, y), width: 13, height: 27), paint);
          canvas.drawLine(Offset(dx, y - 10), Offset(dx, y + 16), paint);
        } else if (style == 'sky') {
          canvas.drawArc(Rect.fromLTWH(dx, y, 28, 13), 0, 3.14, false, paint);
          canvas.drawArc(Rect.fromLTWH(dx + 8, y + 6, 28, 13), 0, 3.14, false, paint);
        } else if (style == 'night') {
          canvas.drawCircle(Offset(dx, y), 7, paint);
          canvas.drawLine(Offset(dx + 15, y + 17), Offset(dx + 22, y + 24), paint);
        } else {
          canvas.drawCircle(Offset(dx, y), 1.3, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(_Pattern oldDelegate) => oldDelegate.style != style;
}

/// Hoja de personalización con vista previa. Devuelve el estilo codificado
/// ([ChatStyle.encode]) o `null` si se cierra sin aplicar.
Future<String?> chooseChatBackground(BuildContext context, String selected) => showModalBottomSheet<String>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  backgroundColor: NexoColors.bg,
  builder: (_) => _ChatStyleSheet(initial: ChatStyle.decode(selected)),
);

class _ChatStyleSheet extends StatefulWidget {
  const _ChatStyleSheet({required this.initial});
  final ChatStyle initial;

  @override
  State<_ChatStyleSheet> createState() => _ChatStyleSheetState();
}

class _ChatStyleSheetState extends State<_ChatStyleSheet> {
  late ChatStyle _style = widget.initial;

  void _set(ChatStyle style) => setState(() => _style = style);

  Widget _section(String title, Widget child) => Container(
    margin: const EdgeInsets.only(top: 12),
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
    decoration: BoxDecoration(
      color: NexoColors.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: NexoColors.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(title, style: NexoText.body(14, weight: FontWeight.w800)),
        ),
        const SizedBox(height: 12),
        child,
      ],
    ),
  );

  /// Conversación en miniatura con el estilo elegido.
  Widget _preview() {
    final p = ChatPalette.forStyle(_style.theme);
    Widget bubble(String text, String time, {required bool mine}) => Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 240),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.fromLTRB(13, 9, 11, 6),
        decoration: BoxDecoration(
          color: mine ? p.sent : p.received,
          borderRadius: BorderRadius.circular(_style.radius).copyWith(
            bottomRight: mine ? const Radius.circular(5) : null,
            bottomLeft: mine ? null : const Radius.circular(5),
          ),
          boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 4, offset: Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: NexoText.body(_style.fontSize, color: mine ? Colors.white : p.ink, height: 1.3)),
            Text(time, style: NexoText.body(10.5, color: mine ? Colors.white70 : p.muted)),
          ],
        ),
      ),
    );
    return Semantics(
      label: 'Vista previa del chat',
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          boxShadow: const [BoxShadow(color: Color(0x1F141F1C), blurRadius: 18, offset: Offset(0, 8))],
        ),
        child: ChatBackdrop(
          style: _style.theme,
          pattern: _style.pattern,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Column(
              children: [
                bubble('Hola, ¿puedes venir mañana?', '9:41', mine: false),
                bubble('Claro, a las 10 me queda bien.', '9:42', mine: true),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _themeCard((String, String, Color) theme, double width) {
    final selected = theme.$1 == _style.theme;
    final p = ChatPalette.forStyle(theme.$1);
    Widget line(Color color, double w, Alignment side) => Align(
      alignment: side,
      child: Container(
        width: w,
        height: 11,
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
      ),
    );
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _set(_style.copyWith(theme: theme.$1)),
        child: SizedBox(
          width: width,
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                height: 66,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.$3,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: selected ? p.sent : NexoColors.line, width: selected ? 2.5 : 1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    line(p.received, width * .48, Alignment.centerLeft),
                    line(p.sent, width * .58, Alignment.centerRight),
                    line(p.received, width * .34, Alignment.centerLeft),
                  ],
                ),
              ),
              const SizedBox(height: 5),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (selected) ...[
                    Icon(Icons.check_circle_rounded, size: 13, color: p.sent),
                    const SizedBox(width: 3),
                  ],
                  Flexible(
                    child: Text(
                      theme.$2,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: NexoText.body(12, weight: selected ? FontWeight.w800 : FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Opción con muestra visual encima de su nombre.
  Widget _option(String label, bool selected, Widget sample, VoidCallback onTap) {
    final accent = ChatPalette.forStyle(_style.theme).sent;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            decoration: BoxDecoration(
              color: selected ? accent.withValues(alpha: .09) : NexoColors.bg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? accent : Colors.transparent, width: 2),
            ),
            child: Column(
              children: [
                SizedBox(height: 30, child: Center(child: sample)),
                const SizedBox(height: 4),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NexoText.body(12.5, weight: FontWeight.w700),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _shapeSample(double radius) => Container(
    width: 46,
    height: 24,
    decoration: BoxDecoration(
      color: ChatPalette.forStyle(_style.theme).sent,
      borderRadius: BorderRadius.circular(radius).copyWith(bottomRight: const Radius.circular(3)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final accent = ChatPalette.forStyle(_style.theme).sent;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * .9),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Personalizar chat', style: NexoText.display(20)),
                        Text(
                          'Solo tú verás estos cambios, en este chat.',
                          style: NexoText.body(13, color: NexoColors.muted),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar sin aplicar',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, color: NexoColors.muted),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _preview(),
                    _section(
                      'Tema',
                      LayoutBuilder(
                        builder: (context, box) {
                          final columns = box.maxWidth < 270 ? 3 : 4;
                          final width = (box.maxWidth - (columns - 1) * 10) / columns;
                          return Wrap(
                            spacing: 10,
                            runSpacing: 12,
                            children: [for (final t in chatBackgrounds) _themeCard(t, width)],
                          );
                        },
                      ),
                    ),
                    _section(
                      'Tamaño del texto',
                      Row(
                        children: [
                          for (final (index, size) in const [
                            ('compact', 'Compacto', 14.0),
                            ('normal', 'Normal', 18.0),
                            ('large', 'Grande', 23.0),
                          ].indexed) ...[
                            if (index > 0) const SizedBox(width: 10),
                            _option(
                              size.$2,
                              _style.textSize == size.$1,
                              ExcludeSemantics(child: Text('Aa', style: NexoText.display(size.$3))),
                              () => _set(_style.copyWith(textSize: size.$1)),
                            ),
                          ],
                        ],
                      ),
                    ),
                    _section(
                      'Forma de las burbujas',
                      Row(
                        children: [
                          _option(
                            'Redondeadas',
                            _style.rounded,
                            _shapeSample(14),
                            () => _set(_style.copyWith(rounded: true)),
                          ),
                          const SizedBox(width: 10),
                          _option(
                            'Rectas',
                            !_style.rounded,
                            _shapeSample(5),
                            () => _set(_style.copyWith(rounded: false)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Material(
                      color: NexoColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: const BorderSide(color: NexoColors.line),
                      ),
                      child: SwitchListTile(
                        contentPadding: const EdgeInsets.fromLTRB(14, 2, 8, 2),
                        title: Text('Patrón de fondo', style: NexoText.body(14, weight: FontWeight.w800)),
                        subtitle: Text(
                          'Desactívalo para un fondo liso.',
                          style: NexoText.body(12.5, color: NexoColors.muted),
                        ),
                        activeTrackColor: accent,
                        value: _style.pattern,
                        onChanged: (value) => _set(_style.copyWith(pattern: value)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: NexoColors.line)),
              ),
              child: Row(
                children: [
                  OutlinedButton(
                    onPressed: () => _set(const ChatStyle()),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: NexoColors.ink,
                      side: const BorderSide(color: NexoColors.line),
                      minimumSize: const Size(0, 50),
                      shape: const StadiumBorder(),
                    ),
                    child: const Text('Restablecer'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, _style.encode()),
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                        shape: const StadiumBorder(),
                      ),
                      child: const Text('Aplicar'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
