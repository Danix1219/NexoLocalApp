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
import '../../data/models.dart';
import '../common/actions.dart';
import '../common/cards.dart';

/// Interesados en una solicitud propia (`V.ints`): lista completa y ordenable.
class InterestedPage extends ConsumerStatefulWidget {
  const InterestedPage({super.key, required this.requestId});
  final String requestId;

  @override
  ConsumerState<InterestedPage> createState() => _InterestedPageState();
}

class _InterestedPageState extends ConsumerState<InterestedPage> {
  String _sort = 'rate';

  @override
  Widget build(BuildContext context) {
    final v = ref.watch(interestedProvider((widget.requestId, _sort)));
    final req = ref.watch(myRequestsProvider).asData?.value.where((r) => r.id == widget.requestId).firstOrNull;
    return NexoPage(
      child: Column(
        children: [
          const SubBar('Interesados'),
          Expanded(
            child: Stack(children: [
              Positioned.fill(
                child: asyncView(v, (page) {
                  final c = catInfo(req?.category ?? (page.items.isEmpty ? 'otros' : page.items.first.provider.categories.firstOrNull ?? 'otros'));
                  return ListView(
                    padding: const EdgeInsets.only(bottom: 100),
                    children: [
                      Container(
                        color: NexoColors.surface,
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            NBadge(c.name, icon: c.icon, tone: BadgeTone.ink),
                            const SizedBox(height: 8),
                            Text(page.title.isEmpty ? (req?.title ?? '') : page.title, style: NexoText.display(20)),
                            if (req != null) ...[
                              const SizedBox(height: 4),
                              Text('${req.urgencyText} · ${req.zoneLabel} · ${req.ago}',
                                  style: NexoText.body(13.5, color: NexoColors.muted)),
                            ],
                          ],
                        ),
                      ),
                      if (page.items.isEmpty)
                        const EmptyState(
                            icon: 'user', title: 'Aún no hay interesados', text: 'Te avisaremos cuando un prestador se interese.')
                      else ...[
                        Sect('${page.items.length} ${plural(page.items.length, 'interesado', 'interesados')}'),
                        SizedBox(
                          height: 46,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            children: [
                              for (final o in const [('rate', 'Mejor calificados'), ('recs', 'Más recomendados'), ('open', 'Abiertos ahora')])
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: ToggleChip(label: o.$2, selected: _sort == o.$1, onTap: () => setState(() => _sort = o.$1)),
                                ),
                            ],
                          ),
                        ),
                        for (final it in page.items) _IntCard(it: it, request: req),
                      ],
                      if (req != null && !req.closed)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: NexoLink('Ya lo resolví · cerrar solicitud',
                                center: true, onTap: () => showCloseRequestSheet(context, ref, req)),
                          ),
                        ),
                    ],
                  );
                }, onRetry: () => ref.invalidate(interestedProvider((widget.requestId, _sort)))),
              ),
              const Positioned(left: 0, right: 0, bottom: 0, child: SafeArea(top: false, child: CompareBar())),
            ]),
          ),
        ],
      ),
    );
  }
}

class _IntCard extends ConsumerWidget {
  const _IntCard({required this.it, this.request});
  final Interested it;
  final ServiceRequest? request;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = it.provider;
    final cmp = ref.watch(compareProvider).any((x) => x.id == p.id);
    return NexoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => context.push(Routes.provider(p.id)),
            child: Row(children: [
              NexoAvatar(name: p.name, url: p.photoUrl, size: 46),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Flexible(child: Text(p.name, overflow: TextOverflow.ellipsis, style: NexoText.body(15, weight: FontWeight.w800))),
                      if (p.phoneVerified) ...[const SizedBox(width: 4), const NexoIcon('shield', size: 15, color: NexoColors.ok)],
                    ]),
                    Text(
                      [
                        if (p.rating.count > 0) '★ ${p.rating.avg}',
                        '${p.recs} recomiendan',
                        p.attentionText,
                      ].join(' · '),
                      style: NexoText.body(12.5, color: NexoColors.muted),
                    ),
                  ],
                ),
              ),
              const NexoIcon('chevron', size: 18, color: NexoColors.muted),
            ]),
          ),
          const SizedBox(height: 10),
          Wrap(spacing: 6, runSpacing: 6, children: [
            NBadge(p.status.short, icon: 'clock', tone: p.status.open ? BadgeTone.ok : BadgeTone.plain),
            if (p.minPriceText != null) NBadge(p.minPriceText!, tone: BadgeTone.ink),
            if (p.visitText != null) NBadge(p.visitText!, tone: BadgeTone.plain),
            if (p.distanceText.isNotEmpty) NBadge(p.distanceText, icon: 'pin', tone: BadgeTone.plain),
          ]),
          if (it.note != null && it.note!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: NexoColors.surface2, borderRadius: BorderRadius.circular(12)),
              child: Text('“${it.note}”', style: NexoText.body(13.5, height: 1.4)),
            ),
          ],
          const SizedBox(height: 12),
          if (it.orderStatus != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Notice(
                it.orderStatus == 'pending' ? 'Le enviaste un pedido · esperando respuesta' : 'Pedido ${it.orderStatus == 'accepted' ? 'aceptado' : it.orderStatus}',
                icon: 'check',
                tone: BadgeTone.brand,
              ),
            ),
          Row(children: [
            NexoIconButton(
              icon: cmp ? 'check' : 'compare',
              label: 'Comparar',
              onTap: () => toggleCompare(context, ref, p.mini),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: NexoButton(
                label: 'Mensaje',
                icon: 'chat',
                variant: NexoButtonVariant.line,
                onPressed: it.canMessage
                    ? () => it.conversationId != null
                        ? context.push(Routes.chat(it.conversationId!))
                        : openChatWithProvider(context, ref, p.id, requestId: request?.id)
                    : null,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: NexoButton(
                label: 'Pedir servicio',
                icon: 'check',
                onPressed: it.canOrder ? () => showRequestServiceSheet(context, ref, p, request: request) : null,
              ),
            ),
          ]),
        ],
      ),
    );
  }
}
