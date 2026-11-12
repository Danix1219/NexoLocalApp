import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import 'nexo_icon.dart';
import 'nexo_motion.dart';

Widget _pressFeedback(Widget child) => NexoPressFeedback(child: child);

enum NexoButtonVariant { primary, line, ghost, danger }

/// `.btn` de la maqueta: alto mínimo 48, radio 14, texto 14.5 en negritas.
class NexoButton extends StatelessWidget {
  const NexoButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = NexoButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.block = true,
    this.small = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final NexoButtonVariant variant;
  final String? icon;
  final bool loading;
  final bool block;
  final bool small;

  Widget _text(Color fg) => Text(
        label,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        style: NexoText.body(small ? 13.5 : 14.5, weight: FontWeight.w700, color: fg),
      );

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    late final Color bg;
    late final Color fg;
    BorderSide side = BorderSide.none;
    switch (variant) {
      case NexoButtonVariant.primary:
        bg = NexoColors.brand;
        fg = Colors.white;
      case NexoButtonVariant.danger:
        bg = NexoColors.danger;
        fg = Colors.white;
      case NexoButtonVariant.line:
        bg = NexoColors.surface;
        fg = NexoColors.ink;
        side = const BorderSide(color: NexoColors.line, width: 1.5);
      case NexoButtonVariant.ghost:
        bg = NexoColors.surface2;
        fg = NexoColors.ink;
    }
    final radius = BorderRadius.circular(14);
    final content = Row(
      mainAxisSize: block ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
          )
        else ...[
          if (icon != null) ...[
            NexoIcon(icon!, size: 18, color: fg),
            const SizedBox(width: 8),
          ],
          // Sin Flexible cuando el botón no es de bloque: puede ir dentro de
          // un Row (ancho sin límite) y Flexible ahí truena.
          if (block) Flexible(child: _text(fg)) else _text(fg),
        ],
      ],
    );

    final button = DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: variant == NexoButtonVariant.primary && enabled
            ? const [
                BoxShadow(
                  color: Color(0x2417695D),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                )
              ]
            : null,
      ),
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(borderRadius: radius, side: side),
        child: InkWell(
          customBorder: RoundedRectangleBorder(borderRadius: radius),
          onTap: enabled ? onPressed : null,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: small ? 42 : 48),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: small ? 13 : 17, vertical: small ? 9 : 12),
              child: Center(widthFactor: 1, child: content),
            ),
          ),
        ),
      ),
    );

    return NexoPressFeedback(
        enabled: enabled,
        child: Semantics(
          button: true,
          enabled: enabled,
          label: loading ? '$label, cargando' : null,
          child: Opacity(
            opacity: enabled || loading ? 1 : .45,
            child: block ? SizedBox(width: double.infinity, child: button) : button,
          ),
        ));
  }
}

/// Enlace en texto (`.link2` / `.linkbtn`).
class NexoLink extends StatelessWidget {
  const NexoLink(this.label, {super.key, required this.onTap, this.center = false});

  final String label;
  final VoidCallback onTap;
  final bool center;

  @override
  Widget build(BuildContext context) {
    return _pressFeedback(Semantics(
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Align(
              alignment: center ? Alignment.center : Alignment.centerLeft,
              widthFactor: 1,
              child: Text(
                label,
                style: NexoText.body(14, weight: FontWeight.w800, color: NexoColors.brandDeep),
              ),
            ),
          ),
        ),
      ),
    ));
  }
}

/// `.iconbtn`: 44×44, radio 14, fondo surface-2.
class NexoIconButton extends StatelessWidget {
  const NexoIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.size = 44,
    this.circle = false,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;
  final double size;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(circle ? size : 14);
    return _pressFeedback(Semantics(
      button: true,
      label: label,
      child: Material(
        color: NexoColors.surface2,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: SizedBox(
            width: size,
            height: size,
            child: Center(
              child: NexoIcon(icon, size: circle ? 18 : 20, color: NexoColors.ink),
            ),
          ),
        ),
      ),
    ));
  }
}
