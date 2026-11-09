import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/tokens.dart';
import '../../../app/theme/typography.dart';
import '../../../core/widgets/nexo_icon.dart';
import '../../../core/widgets/ob_scaffold.dart';

/// Pantalla de éxito de la maqueta (`.obdone`): círculo verde con palomita,
/// título, texto y contenido opcional; botones fijos abajo.
class DoneView extends StatelessWidget {
  const DoneView({
    super.key,
    required this.title,
    required this.message,
    this.extra = const [],
    required this.footer,
  });

  final String title;
  final String message;
  final List<Widget> extra;
  final List<Widget> footer;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: NexoColors.surface,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
                    child: Column(
                      children: [
                        Container(
                          width: 76,
                          height: 76,
                          decoration: const BoxDecoration(
                            color: NexoColors.okSoft,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: const NexoIcon('check',
                              size: 38, color: NexoColors.ok, strokeWidth: 2.2),
                        ),
                        const SizedBox(height: 14),
                        Semantics(
                          header: true,
                          child: Text(title,
                              textAlign: TextAlign.center,
                              style: NexoText.display(26, height: 1.15)),
                        ),
                        const SizedBox(height: 14),
                        Text(message,
                            textAlign: TextAlign.center,
                            style: NexoText.body(15,
                                color: NexoColors.muted, height: 1.45)),
                        for (final w in extra) ...[const SizedBox(height: 14), w],
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
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

/// Caja blanca con lista de comprobación (`.box` + `.checkl`).
class CheckList extends StatelessWidget {
  const CheckList({super.key, required this.items});

  /// (hecho, texto)
  final List<(bool, String)> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: NexoColors.surface,
        border: Border.all(color: NexoColors.line),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(color: Color(0x0A1F302B), blurRadius: 18, offset: Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: withGap(
          [
            for (final (done, text) in items)
              Row(
                children: [
                  NexoIcon(done ? 'check' : 'dots',
                      size: 18, color: done ? NexoColors.ok : NexoColors.muted),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(text,
                        style: NexoText.body(14,
                            color: done ? NexoColors.ink : NexoColors.muted)),
                  ),
                ],
              ),
          ],
          8,
        ),
      ),
    );
  }
}
