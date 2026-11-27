import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import 'nexo_button.dart';
import 'nexo_icon.dart';

List<Widget> withGap(List<Widget> items, double gap) {
  final out = <Widget>[];
  for (var i = 0; i < items.length; i++) {
    if (i > 0) out.add(SizedBox(height: gap));
    out.add(items[i]);
  }
  return out;
}

/// Ícono cuadrado verde sobre el título (`.stepic` / `.authic`).
class StepIcon extends StatelessWidget {
  const StepIcon(this.icon, {super.key});
  final String icon;

  @override
  Widget build(BuildContext context) => Container(
    width: 58,
    height: 58,
    decoration: BoxDecoration(color: NexoColors.brandSoft, borderRadius: BorderRadius.circular(20)),
    alignment: Alignment.center,
    child: NexoIcon(icon, size: 28, color: NexoColors.brand),
  );
}

/// Pantalla de formulario de la maqueta (`.ob`): barra con "Atrás", progreso
/// opcional, ícono, título, subtítulo, contenido y pie fijo con botones.
class ObScaffold extends StatelessWidget {
  const ObScaffold({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.content,
    this.footer = const [],
    this.onBack,
    this.progress,
    this.stepLabel,
    this.onClose,
    this.steps,
  });

  /// Número de pasos: la barra de progreso se parte en tramos.
  final int? steps;

  final String icon;
  final String title;
  final String? subtitle;
  final List<Widget> content;
  final List<Widget> footer;
  final VoidCallback? onBack;

  /// 0–1. Si es nulo no se dibuja la barra (pantallas de autenticación).
  final double? progress;
  final String? stepLabel;
  final VoidCallback? onClose;

  void _defaultBack(BuildContext context) {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: NexoColors.surface,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                child: Column(
                  children: [
                    Row(
                      children: [
                        NexoIconButton(icon: 'back', label: 'Atrás', onTap: onBack ?? () => _defaultBack(context)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: progress == null
                              ? const SizedBox.shrink()
                              : _ProgressBar(value: progress!, label: stepLabel, steps: steps),
                        ),
                        if (onClose != null) ...[
                          const SizedBox(width: 8),
                          NexoIconButton(icon: 'close', label: 'Salir del registro', onTap: onClose!),
                        ],
                      ],
                    ),
                    if (stepLabel != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ExcludeSemantics(
                            child: Text(
                              stepLabel!.toUpperCase(),
                              style: NexoText.body(
                                11,
                                weight: FontWeight.w800,
                                color: NexoColors.muted,
                                letterSpacing: .9,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
                  child: _StepEnter(
                    // Cada paso entra con una transición corta.
                    key: ValueKey(title),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(alignment: Alignment.centerLeft, child: StepIcon(icon)),
                        const SizedBox(height: 20),
                        Semantics(
                          header: true,
                          child: Text(title, style: NexoText.display(28, height: 1.14, letterSpacing: -.7)),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 9),
                          Text(subtitle!, style: NexoText.body(15.5, color: NexoColors.muted, height: 1.5)),
                        ],
                        const SizedBox(height: 28),
                        ...withGap(content, 18),
                      ],
                    ),
                  ),
                ),
              ),
              if (footer.isNotEmpty)
                Container(
                  color: NexoColors.surface,
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 18),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: withGap(footer, 8)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value, this.label, this.steps});
  final double value;
  final String? label;
  final int? steps;

  @override
  Widget build(BuildContext context) {
    final count = steps ?? 1;
    final filled = value.clamp(0.0, 1.0) * count;
    return Semantics(
      label: label ?? 'Progreso',
      value: '${(value * 100).round()}%',
      child: Row(
        children: [
          for (var i = 0; i < count; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  height: 5,
                  color: NexoColors.surface2,
                  alignment: Alignment.centerLeft,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: (filled - i).clamp(0.0, 1.0).toDouble()),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    builder: (context, v, _) => FractionallySizedBox(
                      widthFactor: v,
                      child: Container(color: NexoColors.brand),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepEnter extends StatelessWidget {
  const _StepEnter({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      child: child,
      builder: (_, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 14 * (1 - v)), child: child),
      ),
    );
  }
}

/// Pregunta secundaria con su enlace, bajo el botón principal.
class ObSwitch extends StatelessWidget {
  const ObSwitch({super.key, required this.question, required this.action, required this.onTap});
  final String question, action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    crossAxisAlignment: WrapCrossAlignment.center,
    spacing: 2,
    children: [
      Text(question, style: NexoText.body(13.5, color: NexoColors.muted)),
      NexoLink(action, onTap: onTap),
    ],
  );
}

/// Bloque de un paso largo: título y campos agrupados en una tarjeta.
class ObSection extends StatelessWidget {
  const ObSection({super.key, required this.title, this.icon, this.hint, required this.children});
  final String title;
  final String? icon, hint;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(15, 15, 15, 16),
    decoration: BoxDecoration(
      color: NexoColors.surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: NexoColors.line),
      boxShadow: const [BoxShadow(color: Color(0x0A1F302B), blurRadius: 18, offset: Offset(0, 6))],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: NexoColors.brandSoft, borderRadius: BorderRadius.circular(11)),
                child: NexoIcon(icon!, size: 17, color: NexoColors.brand),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Semantics(
                header: true,
                child: Text(title, style: NexoText.body(15.5, weight: FontWeight.w800)),
              ),
            ),
          ],
        ),
        if (hint != null) ...[
          const SizedBox(height: 6),
          Text(hint!, style: NexoText.body(13, color: NexoColors.muted, height: 1.4)),
        ],
        const SizedBox(height: 14),
        ...withGap(children, 14),
      ],
    ),
  );
}
