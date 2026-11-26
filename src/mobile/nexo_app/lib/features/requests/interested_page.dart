import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../core/widgets/nexo_button.dart';
import '../../core/widgets/nexo_icon.dart';
import '../../core/widgets/ui.dart';
import '../../core/widgets/nexo_navigation.dart';
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

  static const _sorts = [('rate', 'Mejor calificados'), ('recs', 'Más recomendados'), ('open', 'Abiertos ahora')];

  @override
  Widget build(BuildContext context) {
    final v = ref.watch(interestedProvider((widget.requestId, _sort)));
    final req = ref.watch(myRequestsProvider).asData?.value.where((r) => r.id == widget.requestId).firstOrNull;
    return NexoPage(
      bottom: const NexoNavigation(current: 0),
      child: Column(
        children: [
          const SubBar('Interesados'),
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: skeletonView(NexoSkeletonKind.providers, v, (page) {
                    final category = catInfo(
                      req?.category ??
                          (page.items.isEmpty ? 'otros' : page.items.first.provider.categories.firstOrNull ?? 'otros'),
                    );
                    return ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      children: [
                        _RequestSummary(
                          title: page.title.isEmpty ? (req?.title ?? '') : page.title,
                          categoryName: category.name,
                          categoryIcon: category.icon,
                          request: req,
                        ),
                        if (page.items.isEmpty)
                          const EmptyState(
                            icon: 'user',
                            title: 'Aún no hay interesados',
                            text: 'Te avisaremos cuando un prestador se interese.',
                          )
                        else ...[
                          _ListHeading(count: page.items.length),
                          SizedBox(
                            height: 46,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              children: [
                                for (final o in _sorts)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ToggleChip(
                                      label: o.$2,
                                      selected: _sort == o.$1,
                                      onTap: () => setState(() => _sort = o.$1),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          for (final it in page.items) InterestedProviderCard(it: it, request: req),
                        ],
                        if (req != null && !req.closed)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                            child: Column(
                              children: [
                                Text('¿Ya no buscas ayuda?', style: NexoText.body(12.5, color: NexoColors.muted)),
                                NexoLink(
                                  'Ya lo resolví · cerrar solicitud',
                                  center: true,
                                  onTap: () => showCloseRequestSheet(context, ref, req),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  }, onRetry: () => ref.invalidate(interestedProvider((widget.requestId, _sort)))),
                ),
                const SafeArea(top: false, child: CompareBar()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Resumen de la solicitud con el color corporativo.
class _RequestSummary extends StatelessWidget {
  const _RequestSummary({required this.title, required this.categoryName, required this.categoryIcon, this.request});
  final String title, categoryName, categoryIcon;
  final ServiceRequest? request;

  Widget _tag(String icon, String label) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .14), borderRadius: BorderRadius.circular(99)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        NexoIcon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: NexoText.body(12, weight: FontWeight.w700, color: Colors.white),
          ),
        ),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    final req = request;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [NexoColors.brand, NexoColors.brandDeep],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tu solicitud',
            style: NexoText.body(12, weight: FontWeight.w700, color: Colors.white.withValues(alpha: .78)),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: NexoText.display(19, color: Colors.white, height: 1.2),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _tag(categoryIcon, categoryName),
              if (req != null) ...[_tag('clock', req.urgencyText), _tag('pin', req.zoneLabel)],
            ],
          ),
          if (req != null && req.ago.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Publicada ${req.ago}', style: NexoText.body(12, color: Colors.white.withValues(alpha: .78))),
          ],
        ],
      ),
    );
  }
}

class _ListHeading extends StatelessWidget {
  const _ListHeading({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          header: true,
          child: Text('$count ${plural(count, 'interesado', 'interesados')}', style: NexoText.display(19)),
        ),
        const SizedBox(height: 2),
        Text(
          'Revisa sus perfiles y compara hasta dos antes de elegir.',
          style: NexoText.body(13, color: NexoColors.muted),
        ),
      ],
    ),
  );
}

class InterestedProviderCard extends ConsumerWidget {
  const InterestedProviderCard({super.key, required this.it, this.request});
  final Interested it;
  final ServiceRequest? request;

  /// Dato breve del prestador: ícono y texto en una fila de ancho completo.
  Widget _fact(String icon, String text, {Color color = NexoColors.ink}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        NexoIcon(icon, size: 16, color: color == NexoColors.ink ? NexoColors.muted : color),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: NexoText.body(13, weight: FontWeight.w600, color: color),
          ),
        ),
      ],
    ),
  );

  String get _orderText => switch (it.orderStatus) {
    'pending' => 'Le enviaste un pedido · esperando respuesta',
    'accepted' => 'Aceptó tu pedido',
    _ => 'Pedido ${it.orderStatus}',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = it.provider;
    final comparing = ref.watch(compareProvider).any((x) => x.id == p.id);
    final price = [if (p.minPriceText != null) p.minPriceText!, if (p.visitText != null) p.visitText!].join(' · ');
    final message = NexoButton(
      label: 'Mensaje',
      icon: 'chat',
      variant: NexoButtonVariant.line,
      onPressed: it.canMessage
          ? () => it.conversationId != null
                ? context.push(Routes.chat(it.conversationId!))
                : openChatWithProvider(context, ref, p.id, requestId: request?.id)
          : null,
    );
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: NexoColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: comparing ? NexoColors.brand : NexoColors.line, width: comparing ? 2 : 1),
        boxShadow: const [BoxShadow(color: Color(0x0F141F1C), blurRadius: 14, offset: Offset(0, 5))],
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () => context.push(Routes.provider(p.id)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Row(
                  children: [
                    NexoAvatar(name: p.name, url: p.photoUrl, size: 60),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  p.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: NexoText.body(16.5, weight: FontWeight.w800),
                                ),
                              ),
                              if (p.phoneVerified) ...[
                                const SizedBox(width: 5),
                                const NexoIcon('shield', size: 15, color: NexoColors.ok),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            [
                              p.rating.count > 0 ? '★ ${p.rating.avg} (${p.rating.count})' : 'Sin calificaciones aún',
                              '${p.recs} ${plural(p.recs, 'recomienda', 'recomiendan')}',
                            ].join(' · '),
                            style: NexoText.body(12.5, color: NexoColors.muted),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ver perfil',
                            style: NexoText.body(12.5, weight: FontWeight.w800, color: NexoColors.brand),
                          ),
                        ],
                      ),
                    ),
                    const NexoIcon('chevron', size: 18, color: NexoColors.muted),
                  ],
                ),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              decoration: BoxDecoration(color: NexoColors.bg, borderRadius: BorderRadius.circular(14)),
              child: Column(
                children: [
                  _fact('clock', p.status.short, color: p.status.open ? NexoColors.ok : NexoColors.ink),
                  if (p.distanceText.isNotEmpty || p.attentionText.trim().isNotEmpty)
                    _fact(
                      'pin',
                      [
                        if (p.distanceText.isNotEmpty) p.distanceText,
                        if (p.attentionText.trim().isNotEmpty) p.attentionText,
                      ].join(' · '),
                    ),
                  if (price.isNotEmpty) _fact('info', price),
                ],
              ),
            ),
            if (it.note != null && it.note!.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: NexoColors.brandSoft, borderRadius: BorderRadius.circular(14)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Te propone',
                      style: NexoText.body(11.5, weight: FontWeight.w800, color: NexoColors.brand),
                    ),
                    const SizedBox(height: 5),
                    Text(it.note!, style: NexoText.body(13.5, height: 1.4)),
                  ],
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (it.orderStatus != null) ...[
                    Notice(_orderText, icon: 'check', tone: BadgeTone.brand),
                    const SizedBox(height: 10),
                    message,
                  ] else
                    Row(
                      children: [
                        Expanded(child: message),
                        const SizedBox(width: 10),
                        Expanded(
                          child: NexoButton(
                            label: 'Pedir servicio',
                            onPressed: it.canOrder
                                ? () => showRequestServiceSheet(context, ref, p, request: request)
                                : null,
                          ),
                        ),
                      ],
                    ),
                  if (!it.canMessage)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'El chat no está disponible para esta solicitud.',
                        textAlign: TextAlign.center,
                        style: NexoText.body(12, color: NexoColors.muted),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1, color: NexoColors.line),
            Semantics(
              button: true,
              selected: comparing,
              child: InkWell(
                onTap: () => toggleCompare(context, ref, p.mini),
                child: Container(
                  constraints: const BoxConstraints(minHeight: 48),
                  color: comparing ? NexoColors.brandSoft : Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      NexoIcon(comparing ? 'check' : 'compare', size: 17, color: NexoColors.brandDeep),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          comparing ? 'En comparación' : 'Comparar prestador',
                          style: NexoText.body(13.5, weight: FontWeight.w800, color: NexoColors.brandDeep),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
