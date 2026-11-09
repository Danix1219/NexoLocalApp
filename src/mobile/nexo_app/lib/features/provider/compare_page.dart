import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../core/widgets/nexo_button.dart';
import '../../core/widgets/nexo_icon.dart';
import '../../core/widgets/ui.dart';
import '../../data/api_provider.dart';
import '../common/actions.dart';

/// Comparar dos prestadores (`V.compare`).
class ComparePage extends ConsumerWidget {
  const ComparePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sel = ref.watch(compareProvider);
    if (sel.length < 2) {
      return NexoPage(
        child: Column(children: [
          const SubBar('Comparar'),
          EmptyState(
            icon: 'compare',
            title: 'Elige dos prestadores',
            text: 'Toca «Comparar» en los resultados o en el feed para verlos lado a lado.',
            action: 'Buscar',
            onAction: () => context.go(Routes.search),
          ),
        ]),
      );
    }
    final ids = sel.take(2).map((p) => p.id).join(',');
    final v = ref.watch(compareResultProvider(ids));
    return NexoPage(
      background: NexoColors.surface,
      child: Column(
        children: [
          SubBar('Comparar', actions: [
            TextButton(
              onPressed: () {
                ref.read(compareProvider.notifier).clear();
                context.pop();
              },
              child: Text('Limpiar', style: NexoText.body(14, weight: FontWeight.w700, color: NexoColors.brand)),
            ),
          ]),
          Expanded(
            child: asyncView(v, (r) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
                children: [
                  Row(children: [
                    const SizedBox(width: 96),
                    for (final p in r.providers)
                      Expanded(
                        child: InkWell(
                          onTap: () => context.push(Routes.provider(p.id)),
                          child: Column(children: [
                            NexoAvatar(name: p.name, url: p.photoUrl, size: 56),
                            const SizedBox(height: 6),
                            Text(p.name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: NexoText.body(13.5, weight: FontWeight.w800, height: 1.2)),
                            if (p.phoneVerified) const NexoIcon('shield', size: 15, color: NexoColors.ok),
                          ]),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 14),
                  for (final row in r.rows)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 11),
                      decoration: const BoxDecoration(border: Border(top: BorderSide(color: NexoColors.line))),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                              width: 96, child: Text(row.label, style: NexoText.body(12.5, color: NexoColors.muted))),
                          for (var i = 0; i < row.values.length && i < 2; i++)
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                                decoration: BoxDecoration(
                                  color: row.best == i ? NexoColors.okSoft : Colors.transparent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(row.values[i],
                                    textAlign: TextAlign.center,
                                    style: NexoText.body(13.5,
                                        weight: row.best == i ? FontWeight.w800 : FontWeight.w600,
                                        color: row.best == i
                                            ? NexoColors.ok
                                            : row.values[i] == 'No publicó'
                                                ? NexoColors.muted
                                                : NexoColors.ink)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 14),
                  Row(children: [
                    const SizedBox(width: 96),
                    for (final p in r.providers)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: NexoButton(
                            label: 'Contactar',
                            icon: 'chat',
                            small: true,
                            onPressed: () => showContactSheet(context, ref, p),
                          ),
                        ),
                      ),
                  ]),
                  const SizedBox(height: 14),
                  Text('En verde, lo que favorece a cada uno. Los datos son declarados por cada prestador.',
                      textAlign: TextAlign.center, style: NexoText.body(12.5, color: NexoColors.muted)),
                ],
              );
            }, onRetry: () => ref.invalidate(compareResultProvider(ids))),
          ),
        ],
      ),
    );
  }
}
