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
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: NexoColors.brandSoft,
          borderRadius: BorderRadius.circular(18),
        ),
        alignment: Alignment.center,
        child: NexoIcon(icon, size: 26, color: NexoColors.brand),
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
  });

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
                        NexoIconButton(
                          icon: 'back',
                          label: 'Atrás',
                          onTap: onBack ?? () => _defaultBack(context),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: progress == null
                              ? const SizedBox.shrink()
                              : _ProgressBar(value: progress!, label: stepLabel),
                        ),
                        if (onClose != null) ...[
                          const SizedBox(width: 8),
                          NexoIconButton(
                            icon: 'close',
                            label: 'Salir del registro',
                            onTap: onClose!,
                          ),
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
                              style: NexoText.body(11,
                                  weight: FontWeight.w800, color: NexoColors.muted, letterSpacing: .9),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(alignment: Alignment.centerLeft, child: StepIcon(icon)),
                      const SizedBox(height: 10),
                      Semantics(
                        header: true,
                        child: Text(title, style: NexoText.display(26, height: 1.15)),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 6),
                        Text(subtitle!, style: NexoText.body(15, color: NexoColors.muted, height: 1.45)),
                      ],
                      const SizedBox(height: 18),
                      ...withGap(content, 18),
                    ],
                  ),
                ),
              ),
              if (footer.isNotEmpty)
                Container(
                  color: NexoColors.surface,
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: withGap(footer, 8),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value, this.label});
  final double value;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label ?? 'Progreso',
      value: '${(value * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Container(
          height: 4,
          color: NexoColors.line,
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 250),
            builder: (context, v, _) => FractionallySizedBox(
              widthFactor: v,
              child: Container(color: NexoColors.brand),
            ),
          ),
        ),
      ),
    );
  }
}
