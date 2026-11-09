import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../core/widgets/nexo_button.dart';
import '../../core/widgets/ui.dart';
import '../../data/api_provider.dart';
import '../../data/models.dart';
import '../common/actions.dart';
import '../common/cards.dart';

/// 7.12 Guardados (`V.saved`), se abre desde Cuenta.
class SavedPage extends ConsumerWidget {
  const SavedPage({super.key});

  Future<void> _remove(BuildContext context, WidgetRef ref, SavedItem s) async {
    await toggleSaved(context, ref, s.kind, s.targetId, false);
    ref.invalidate(savedProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(savedProvider);
    return NexoPage(
      child: Column(children: [
        const SubBar('Guardados'),
        Expanded(
          child: Stack(children: [
            Positioned.fill(
              child: asyncView(v, (d) {
                final items = d.$1;
                if (items.isEmpty) {
                  return ListView(children: [
                    EmptyState(
                      icon: 'bookmark',
                      title: 'Todavía no guardas nada',
                      text: 'Guarda prestadores, trabajos y solicitudes para volver a ellos cuando los necesites.',
                      action: 'Buscar un servicio',
                      onAction: () => context.go(Routes.search),
                    ),
                  ]);
                }
                final ps = items.where((s) => s.kind == 'provider').toList();
                final ws = items.where((s) => s.kind == 'work').toList();
                final rs = items.where((s) => s.kind == 'request').toList();
                return RefreshIndicator(
                  color: NexoColors.brand,
                  onRefresh: () async => ref.invalidate(savedProvider),
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 90),
                    children: [
                      if (ps.isNotEmpty) ...[
                        Sect('Prestadores', trailing: '${ps.length}'),
                        for (final s in ps) _providerCard(context, ref, s),
                      ],
                      if (ws.isNotEmpty) ...[
                        Sect('Trabajos', trailing: '${ws.length}'),
                        for (final s in ws)
                          s.work != null && s.available ? WorkCard(work: s.work!) : _gone(context, ref, s, 'Este trabajo ya no está disponible'),
                      ],
                      if (rs.isNotEmpty) ...[
                        Sect('Solicitudes', trailing: '${rs.length}'),
                        for (final s in rs)
                          s.request != null && s.available
                              ? RequestCard(r: s.request!)
                              : _gone(context, ref, s, 'Esta solicitud ya se cerró'),
                      ],
                    ],
                  ),
                );
              }, onRetry: () => ref.invalidate(savedProvider)),
            ),
            const Positioned(left: 0, right: 0, bottom: 0, child: SafeArea(top: false, child: CompareBar())),
          ]),
        ),
      ]),
    );
  }

  Widget _providerCard(BuildContext context, WidgetRef ref, SavedItem s) {
    final p = s.provider;
    if (p == null || !s.available) return _gone(context, ref, s, 'Este perfil ya no está disponible');
    return NexoCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        InkWell(
          onTap: () => context.push(Routes.provider(p.id)),
          child: Row(children: [
            NexoAvatar(name: p.name, url: p.photoUrl),
            const SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(p.name, style: NexoText.body(15, weight: FontWeight.w800)),
                Text('${p.categories.map((c) => catInfo(c).name).join(', ')} · ${p.zoneLabel}',
                    style: NexoText.body(12.5, color: NexoColors.muted)),
                const SizedBox(height: 4),
                NBadge(p.status.short, icon: 'clock', tone: p.status.open ? BadgeTone.ok : BadgeTone.plain),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: NexoButton(
                label: 'Quitar', small: true, variant: NexoButtonVariant.ghost, onPressed: () => _remove(context, ref, s)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: NexoButton(
              label: 'Contactar',
              icon: 'chat',
              small: true,
              onPressed: () => showContactSheet(context, ref, p.mini, responseTime: p.responseTime, canCall: p.channelCall),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _gone(BuildContext context, WidgetRef ref, SavedItem s, String text) => NexoCard(
        child: Row(children: [
          Expanded(child: Text(text, style: NexoText.body(14, color: NexoColors.muted))),
          NexoButton(
              label: 'Quitar', small: true, block: false, variant: NexoButtonVariant.ghost, onPressed: () => _remove(context, ref, s)),
        ]),
      );
}
