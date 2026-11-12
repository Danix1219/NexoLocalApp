import 'package:flutter/material.dart';

import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import 'nexo_button.dart';
import 'nexo_icon.dart';
import 'nexo_motion.dart';

Widget _pressFeedback(Widget child) => NexoPressFeedback(child: child);

/// Hoja inferior de la maqueta (`.sheet`): radio 28, barra para arrastrar y X.
Future<T?> showNexoSheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useRootNavigator: true,
    sheetAnimationStyle: AnimationStyle(
        duration: NexoMotion.duration(context, NexoMotion.enter),
        reverseDuration: NexoMotion.duration(context, NexoMotion.enter)),
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: const Color(0x80141F1C),
    builder: (ctx) => _SheetFrame(child: builder(ctx)),
  );
}

class _SheetFrame extends StatelessWidget {
  const _SheetFrame({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: mq.viewInsets.bottom),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: mq.size.height * .86),
        child: Container(
          decoration: const BoxDecoration(
            color: NexoColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(color: Color(0x33141F1C), blurRadius: 46, offset: Offset(0, -14)),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 42,
                          height: 5,
                          decoration: BoxDecoration(
                            color: NexoColors.line,
                            borderRadius: BorderRadius.circular(9),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      child,
                    ],
                  ),
                ),
                Positioned(
                  right: 12,
                  top: 18,
                  child: NexoIconButton(
                    icon: 'close',
                    label: 'Cerrar',
                    size: 36,
                    circle: true,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Título y subtítulo de hoja (`.sheet h2` + `.sub`).
class SheetHeader extends StatelessWidget {
  const SheetHeader(this.title, {super.key, this.subtitle});
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 44, bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(title, style: NexoText.display(20)),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: NexoText.body(14.5, color: NexoColors.muted, height: 1.45)),
          ],
        ],
      ),
    );
  }
}

/// Tarjeta de opción grande (`.choice`).
class ChoiceCard extends StatelessWidget {
  const ChoiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final r = BorderRadius.circular(18);
    return _pressFeedback(Semantics(
      button: true,
      child: Material(
        color: NexoColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: r,
          side: const BorderSide(color: NexoColors.line, width: 1.5),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(borderRadius: r),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: NexoColors.brandSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  alignment: Alignment.center,
                  child: NexoIcon(icon, color: NexoColors.brand),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: NexoText.body(16, weight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: NexoText.body(13.5, color: NexoColors.muted, height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ));
  }
}

/// Fila de opción (`.opt`), con estado presionado opcional.
class OptRow extends StatelessWidget {
  const OptRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected,
    this.danger = false,
    this.trailingChevron = false,
  });

  final String icon;
  final String label;
  final VoidCallback onTap;

  /// Si no es nulo, la fila se comporta como casilla (aria-pressed).
  final bool? selected;
  final bool danger;
  final bool trailingChevron;

  @override
  Widget build(BuildContext context) {
    final on = selected == true;
    final fg = danger
        ? NexoColors.danger
        : on
            ? NexoColors.brand
            : NexoColors.ink;
    final r = BorderRadius.circular(14);
    return _pressFeedback(Semantics(
      button: selected == null,
      checked: selected,
      child: Material(
        color: on ? NexoColors.brandSoft : NexoColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: r,
          side: BorderSide(
            color: on
                ? NexoColors.brand
                : danger
                    ? NexoColors.danger.withValues(alpha: .4)
                    : NexoColors.line,
            width: 1.5,
          ),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(borderRadius: r),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 50),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
              child: Row(
                children: [
                  NexoIcon(icon, size: 22, color: fg),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(label, style: NexoText.body(14, weight: FontWeight.w600, color: fg)),
                  ),
                  if (trailingChevron) const NexoIcon('chevron', size: 18, color: NexoColors.muted),
                ],
              ),
            ),
          ),
        ),
      ),
    ));
  }
}

/// Nota verde (`.onenote`).
class OneNote extends StatelessWidget {
  const OneNote({super.key, required this.icon, required this.text});
  final String icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: NexoColors.brandSoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: NexoIcon(icon, size: 18, color: NexoColors.brandDeep),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text,
                style: NexoText.body(13.5, weight: FontWeight.w600, color: NexoColors.brandDeep, height: 1.4)),
          ),
        ],
      ),
    );
  }
}

/// Hoja de confirmación de dos botones. Devuelve true (confirmar), false
/// (cancelar) o null si se cerró sin elegir.
Future<bool?> confirmSheet(
  BuildContext context, {
  required String title,
  required String subtitle,
  required String confirmLabel,
  String cancelLabel = 'Cancelar',
  bool confirmFirst = true,
}) {
  return showNexoSheet<bool>(
    context,
    builder: (ctx) {
      final confirm = NexoButton(
        label: confirmLabel,
        onPressed: () => Navigator.of(ctx).pop(true),
        variant: confirmFirst ? NexoButtonVariant.primary : NexoButtonVariant.ghost,
      );
      final cancel = NexoButton(
        label: cancelLabel,
        onPressed: () => Navigator.of(ctx).pop(false),
        variant: confirmFirst ? NexoButtonVariant.ghost : NexoButtonVariant.primary,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SheetHeader(title, subtitle: subtitle),
          if (confirmFirst) confirm else cancel,
          const SizedBox(height: 8),
          if (confirmFirst) cancel else confirm,
        ],
      );
    },
  );
}
