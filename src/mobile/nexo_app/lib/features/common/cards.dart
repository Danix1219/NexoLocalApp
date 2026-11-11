import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../core/auth/session_controller.dart';
import '../../core/widgets/nexo_button.dart';
import '../../core/widgets/nexo_icon.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/ui.dart';
import '../../core/widgets/nexo_motion.dart';
import '../../data/api_provider.dart';
import '../../data/models.dart';
import '../shell/gate.dart';
import 'actions.dart';
import 'carousel.dart';
import 'request_editor.dart';
import 'work_editor.dart';

/// Botón de acción redondo de la publicación (`.act`).
class ActIcon extends StatelessWidget {
  const ActIcon(
      {super.key, required this.icon, required this.label, required this.onTap, this.on = false, this.fill = false});
  final String icon;
  final String label;
  final VoidCallback onTap;
  final bool on;
  final bool fill;

  @override
  Widget build(BuildContext context) => NexoPressFeedback(
          child: Semantics(
        button: true,
        label: label,
        selected: on,
        child: InkResponse(
          onTap: onTap,
          radius: 24,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: NexoIcon(icon,
                  size: 24,
                  color: on ? NexoColors.brand : NexoColors.ink,
                  fillColor: on && fill ? NexoColors.brand.withValues(alpha: .18) : null),
            ),
          ),
        ),
      ));
}

/// Publicación de trabajo en el feed (`postHTML`).
/// Expands long posts without hiding their original text.
class ExpandablePublicationText extends StatefulWidget {
  const ExpandablePublicationText(this.text, {super.key, this.style});
  final String text;
  final TextStyle? style;

  @override
  State<ExpandablePublicationText> createState() => _ExpandablePublicationTextState();
}

class _ExpandablePublicationTextState extends State<ExpandablePublicationText> {
  bool expanded = false;

  @override
  void didUpdateWidget(ExpandablePublicationText oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.text != widget.text) expanded = false;
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
        final style = widget.style ?? NexoText.body(14, height: 1.45);
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: style),
          maxLines: 3,
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
        )..layout(maxWidth: constraints.maxWidth);
        final overflows = painter.didExceedMaxLines;
        painter.dispose();
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.text,
              style: style,
              maxLines: expanded ? null : 3,
              overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis),
          if (overflows)
            TextButton(
              onPressed: () => setState(() => expanded = !expanded),
              style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                  minimumSize: const Size(48, 36),
                  alignment: Alignment.centerLeft),
              child: Text(expanded ? 'Ver menos' : 'Ver m\u00e1s',
                  style: NexoText.body(13, color: NexoColors.brand, weight: FontWeight.w700)),
            ),
        ]);
      });
}

class WorkCard extends ConsumerStatefulWidget {
  const WorkCard({super.key, required this.work, this.own = false});
  final Work work;
  final bool own;

  @override
  ConsumerState<WorkCard> createState() => _WorkCardState();
}

class _WorkCardState extends ConsumerState<WorkCard> {
  late Work w = widget.work;

  @override
  void didUpdateWidget(WorkCard old) {
    super.didUpdateWidget(old);
    if (old.work != widget.work) w = widget.work;
  }

  bool _recommending = false;
  Future<void> _recommend() async {
    if (_recommending) return;
    if (!requireAccount(context, ref, why: 'Con una cuenta puedes recomendar los trabajos que te gustan.')) return;
    _recommending = true;
    final on = !w.recommended;
    setState(() => w = w.copyWith(recommended: on, recs: w.recs + (on ? 1 : -1)));
    try {
      final r = await ref.read(apiProvider).recommend(w, on);
      if (mounted) setState(() => w = r);
    } catch (e) {
      if (mounted) setState(() => w = w.copyWith(recommended: !on, recs: w.recs + (on ? -1 : 1)));
      showNexoToast(apiErrorMessage(e));
    } finally {
      _recommending = false;
    }
  }

  Future<void> _save() async {
    final r = await toggleSaved(context, ref, 'work', w.id, !w.saved);
    if (r != null && mounted) setState(() => w = w.copyWith(saved: r));
  }

  @override
  Widget build(BuildContext context) {
    final p = w.provider;
    final c = catInfo(w.category);
    final cmp = ref.watch(compareProvider).any((x) => x.id == p.id);
    final own = widget.own || !w.canContact;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: const BoxDecoration(
        color: NexoColors.surface,
        border: Border(bottom: BorderSide(color: NexoColors.line)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
            child: Row(
              children: [
                InkWell(
                  onTap: () => context.push(Routes.provider(p.id)),
                  customBorder: const CircleBorder(),
                  child: NexoAvatar(name: p.name, url: p.photoUrl),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InkWell(
                    onTap: () => context.push(Routes.provider(p.id)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Flexible(
                            child: Text(p.name,
                                overflow: TextOverflow.ellipsis, style: NexoText.body(14.5, weight: FontWeight.w700)),
                          ),
                          if (p.emailVerified) ...[
                            const SizedBox(width: 4),
                            const NexoIcon('shield', size: 15, color: NexoColors.ok),
                          ],
                        ]),
                        Text('${c.name} · ${w.zoneLabel}',
                            overflow: TextOverflow.ellipsis, style: NexoText.body(12.5, color: NexoColors.muted)),
                      ],
                    ),
                  ),
                ),
                if (own)
                  ActIcon(
                      icon: 'dots',
                      label: 'Editar trabajo',
                      onTap: () async {
                        final updated = await showWorkEditor(context, ref, w);
                        if (updated != null && mounted) setState(() => w = updated);
                      })
                else
                  ActIcon(
                      icon: 'dots',
                      label: 'Reportar publicación',
                      onTap: () => showReportSheet(context, ref, targetType: 'work', targetId: w.id)),
              ],
            ),
          ),
          PhotoCarousel(
              aspect: 1, images: w.images, category: w.category, tag: w.tag, onTap: () => showWorkSheet(context, w)),
          if (!own)
            Material(
              color: NexoColors.brand,
              child: InkWell(
                onTap: () => showContactSheet(context, ref, p),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      const NexoIcon('chat', size: 19, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text('Contactar',
                              style: NexoText.body(14, weight: FontWeight.w700, color: Colors.white))),
                      const NexoIcon('chevron', size: 18, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
            child: Row(
              children: [
                ActIcon(icon: 'thumb', label: 'Recomendar', on: w.recommended, fill: true, onTap: _recommend),
                ActIcon(icon: 'share', label: 'Compartir', onTap: () => shareLink('/w/${w.id}', 'la publicación')),
                if (!own)
                  ActIcon(
                      icon: cmp ? 'check' : 'compare',
                      label: 'Comparar',
                      on: cmp,
                      onTap: () => toggleCompare(context, ref, p)),
                const Spacer(),
                ActIcon(icon: 'bookmark', label: 'Guardar trabajo', on: w.saved, fill: true, onTap: _save),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text('${w.recs} ${plural(w.recs, 'recomendación', 'recomendaciones')}',
                style: NexoText.body(14, weight: FontWeight.w800)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(w.title, style: NexoText.display(15, weight: FontWeight.w700)),
                const SizedBox(height: 2),
                ExpandablePublicationText(w.text,
                    style: NexoText.body(14, color: NexoColors.ink.withValues(alpha: .86), height: 1.45)),
                const SizedBox(height: 4),
                Text(w.ago, style: NexoText.body(12, color: NexoColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Píldora de urgencia (`.urgp`).
class UrgencyPill extends StatelessWidget {
  const UrgencyPill(this.urgency, this.text, {super.key});
  final String urgency;
  final String text;

  @override
  Widget build(BuildContext context) => NBadge(text,
      icon: urgency == 'today' ? 'bolt' : 'clock',
      tone: urgency == 'today'
          ? BadgeTone.hot
          : urgency == 'week'
              ? BadgeTone.brand
              : BadgeTone.plain);
}

/// Solicitud de servicio (`reqHTML`): propia (cliente) o ajena (prestador).
class RequestCard extends ConsumerWidget {
  const RequestCard({super.key, required this.r});
  final ServiceRequest r;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = catInfo(r.category);
    final me = ref.watch(accountProvider).asData?.value;
    final displayName = r.mine && me != null ? me.name : r.clientName;
    final displayPhoto = r.mine && me != null ? me.photoUrl : r.clientPhoto;
    final hot = r.urgency == 'today' && !r.closed;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
      decoration: BoxDecoration(
        color: NexoColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: hot ? NexoColors.accent2.withValues(alpha: .6) : NexoColors.line),
        boxShadow: r.mine ? const [BoxShadow(color: Color(0x101C2926), blurRadius: 18, offset: Offset(0, 5))] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (r.mine)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 15, 16, 0),
              child: Row(children: [
                Text('TU SOLICITUD', style: NexoText.body(11, weight: FontWeight.w800, color: NexoColors.brand, letterSpacing: .8)),
                const Spacer(),
                NBadge(r.closed ? 'Resuelta' : 'Publicada', icon: r.closed ? 'check' : 'clock', tone: BadgeTone.ok),
              ]),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 2),
            child: Row(
              children: [
                GestureDetector(
                    onTap: r.mine && me != null
                        ? () => context.push(Routes.myProfile, extra: me)
                        : () => context.push(Routes.requestAuthor(r.id), extra: r),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [hexColor(c.c1), hexColor(c.c2)]),
                      ),
                      clipBehavior: Clip.antiAlias,
                      alignment: Alignment.center,
                      child: displayPhoto != null
                          ? SizedBox.expand(child: NexoImage(displayPhoto))
                          : Text(initialsOf(displayName.isEmpty ? '?' : displayName),
                              style: NexoText.display(15, color: Colors.white, letterSpacing: 0)),
                    )),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      InkWell(
                        onTap: r.mine && me != null
                            ? () => context.push(Routes.myProfile, extra: me)
                            : () => context.push(Routes.requestAuthor(r.id), extra: r),
                        child: Text(displayName,
                            maxLines: 2, overflow: TextOverflow.ellipsis, style: NexoText.body(15, weight: FontWeight.w800)),
                      ),
                      Text(
                          '${r.zoneLabel}${r.distanceText.isNotEmpty && !r.mine ? ' · ${r.distanceText}' : ''} · ${r.ago}',
                          overflow: TextOverflow.ellipsis,
                          style: NexoText.body(12.5, color: NexoColors.muted)),
                    ],
                  ),
                ),
                if (!r.mine) UrgencyPill(r.urgency, r.urgencyText),
                if (!r.mine)
                  ActIcon(
                      icon: 'dots',
                      label: 'Reportar solicitud',
                      onTap: () => showReportSheet(context, ref, targetType: 'request', targetId: r.id))
                else
                  ActIcon(icon: 'dots', label: 'Editar solicitud', onTap: () => showRequestEditor(context, ref, r)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r.title, style: NexoText.display(16, weight: FontWeight.w700)),
                if (r.mine) ...[
                  const SizedBox(height: 7),
                  Wrap(spacing: 7, runSpacing: 7, children: [
                    UrgencyPill(r.urgency, r.urgencyText),
                    NBadge(c.name, icon: c.icon, tone: BadgeTone.ink),
                  ]),
                ],
                const SizedBox(height: 3),
                ExpandablePublicationText(r.description,
                    style: NexoText.body(14, color: NexoColors.ink.withValues(alpha: .86), height: 1.45)),
                if (r.photos.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: PhotoCarousel(
                          images: [for (final url in r.photos) Img(url)], category: r.category, aspect: 1)),
                ],
                const SizedBox(height: 9),
                Wrap(spacing: 6, runSpacing: 6, children: [
                  if (!r.mine) NBadge(c.name, icon: c.icon, tone: BadgeTone.ink),
                  if (r.matchesMyService && !r.mine)
                    const NBadge('Coincide con tu perfil', icon: 'check', tone: BadgeTone.ok),
                  if (!r.inMyRadius && !r.mine) const NBadge('Fuera de tu radio', icon: 'pin', tone: BadgeTone.warn),
                  if (r.mine) const NBadge('Tu solicitud', tone: BadgeTone.ok),
                ]),
              ],
            ),
          ),
          if (r.mine) _MyRequestFoot(r: r) else _OpportunityFoot(r: r),
        ],
      ),
    );
  }
}

class _OpportunityFoot extends ConsumerStatefulWidget {
  const _OpportunityFoot({required this.r});
  final ServiceRequest r;
  @override
  ConsumerState<_OpportunityFoot> createState() => _OpportunityFootState();
}

class _OpportunityFootState extends ConsumerState<_OpportunityFoot> {
  late bool _saved = widget.r.saved;
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.r;
    final myId = ref.watch(myProviderProvider).asData?.value?.profile.id;
    final pickedMe = r.picked != null && myId != null && r.picked!.id == myId;
    Widget cta;
    if (pickedMe) {
      cta = NexoButton(label: 'Contactar', icon: 'chat', onPressed: () => openChatForRequest(context, ref, r.id));
    } else if (r.picked != null) {
      cta = Center(child: Text('Eligió a otro prestador', style: NexoText.body(13, color: NexoColors.muted)));
    } else {
      cta = NexoButton(
        label: !r.interestKnown
            ? 'Interés no disponible'
            : r.iAmInterested
                ? 'Interés enviado'
                : 'Me interesa',
        icon: r.iAmInterested ? 'check' : 'thumb',
        loading: _busy,
        variant: r.iAmInterested ? NexoButtonVariant.line : NexoButtonVariant.primary,
        onPressed: () async {
          if (!ref.read(sessionProvider).isProviderMode) {
            showNexoToast('Cambia a modo proveedor para responder solicitudes.');
            return;
          }
          setState(() => _busy = true);
          if (!r.interestKnown) {
            showNexoToast('No pudimos comprobar tu interés. Actualiza las solicitudes.');
          } else {
            await toggleInterest(context, ref, r);
          }
          if (mounted) setState(() => _busy = false);
        },
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      child: Row(
        children: [
          if (pickedMe)
            const NBadge('Te eligió', icon: 'check', tone: BadgeTone.ok)
          else
            Semantics(
              button: true,
              label: _saved ? 'Quitar de guardadas' : 'Guardar solicitud',
              child: Material(
                color: NexoColors.surface2,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    final v = await toggleSaved(context, ref, 'request', r.id, !_saved);
                    if (v != null && mounted) setState(() => _saved = v);
                  },
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: Center(
                      child: NexoIcon('bookmark',
                          size: 21,
                          color: _saved ? NexoColors.brand : NexoColors.ink,
                          fillColor: _saved ? NexoColors.brand.withValues(alpha: .2) : null),
                    ),
                  ),
                ),
              ),
            ),
          const SizedBox(width: 10),
          Expanded(child: cta),
        ],
      ),
    );
  }
}

/// Pie de la solicitud propia (`myReqFoot`).
class _MyRequestFoot extends ConsumerWidget {
  const _MyRequestFoot({required this.r});
  final ServiceRequest r;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const pad = EdgeInsets.fromLTRB(14, 12, 14, 14);
    if (r.closed && r.orderId == null) {
      return const Padding(
          padding: pad,
          child: Align(alignment: Alignment.centerLeft, child: NBadge('Resuelta', icon: 'check', tone: BadgeTone.ok)));
    }
    if (r.orderId != null && r.picked != null) {
      final done = r.summaryText.contains('resuelto');
      final rate = r.summaryText.contains('¿cómo te fue?');
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: pad,
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: NexoColors.line))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              NexoIcon(done ? 'check' : 'clock', size: 16, color: NexoColors.brand),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(r.summaryText,
                      style: NexoText.body(13.5, weight: FontWeight.w700, color: NexoColors.brandDeep))),
            ]),
            const SizedBox(height: 10),
            _ProvRowMini(p: r.picked!),
            const SizedBox(height: 10),
            Row(children: [
              Expanded(
                child: NexoButton(
                  label: rate ? 'Calificar' : 'Ver pedido',
                  icon: rate ? 'star' : 'pin',
                  onPressed: () => context.push(Routes.order(r.orderId!)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: NexoButton(
                  label: 'Mensaje',
                  icon: 'chat',
                  variant: NexoButtonVariant.ghost,
                  onPressed: () => openChatWithProvider(context, ref, r.picked!.id, requestId: r.id),
                ),
              ),
            ]),
          ],
        ),
      );
    }
    if (r.interestCount > 0) {
      final prev = r.interestedPreview;
      return Container(
        margin: const EdgeInsets.only(top: 8),
        padding: pad,
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: NexoColors.line))),
        child: Column(
          children: [
            Material(
              color: NexoColors.brandSoft,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => context.push(Routes.interested(r.id)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      SizedBox(
                        width:
                            (34 + (prev.length - 1).clamp(0, 3) * 22 + (r.interestedMoreCount > 0 ? 24 : 0)).toDouble(),
                        height: 36,
                        child: Stack(children: [
                          for (var i = 0; i < prev.length && i < 4; i++)
                            Positioned(
                                left: i * 22.0,
                                child: NexoAvatar(name: prev[i].name, url: prev[i].photoUrl, size: 36, border: true)),
                          if (r.interestedMoreCount > 0)
                            Positioned(
                              left: (prev.length.clamp(0, 4) * 22).toDouble(),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: NexoColors.surface,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: NexoColors.line, width: 2),
                                ),
                                child: Center(
                                    child: Text('+${r.interestedMoreCount}',
                                        style: NexoText.body(12, weight: FontWeight.w800, color: NexoColors.brand))),
                              ),
                            ),
                        ]),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${r.interestCount} ${plural(r.interestCount, 'interesado', 'interesados')}',
                                style: NexoText.body(14.5, weight: FontWeight.w800)),
                            Text('Compara y elige a quién pedirle',
                                style: NexoText.body(12.5, color: NexoColors.muted)),
                          ],
                        ),
                      ),
                      Text('Ver', style: NexoText.body(13.5, weight: FontWeight.w800, color: NexoColors.brand)),
                      const NexoIcon('chevron', size: 17, color: NexoColors.brand),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            NexoLink('Ya lo resolví · cerrar solicitud',
                center: true, onTap: () => showCloseRequestSheet(context, ref, r)),
          ],
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: pad,
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: NexoColors.line))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(r.summaryText, style: NexoText.body(13, color: NexoColors.muted)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: NexoButton(
                label: 'Ver prestadores',
                small: true,
                variant: NexoButtonVariant.ghost,
                onPressed: () {
                  ref.read(searchFiltersProvider.notifier).set(SearchFilters(cat: r.category));
                  context.go(Routes.search);
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: NexoButton(
                label: 'Marcar como resuelta',
                small: true,
                variant: NexoButtonVariant.ghost,
                onPressed: () => showCloseRequestSheet(context, ref, r),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

class _ProvRowMini extends StatelessWidget {
  const _ProvRowMini({required this.p});
  final ProviderMini p;
  @override
  Widget build(BuildContext context) => InkWell(
        onTap: () => context.push(Routes.provider(p.id)),
        child: Row(children: [
          NexoAvatar(name: p.name, url: p.photoUrl, size: 38),
          const SizedBox(width: 10),
          Expanded(child: Text(p.name, style: NexoText.body(14.5, weight: FontWeight.w800))),
          if (p.emailVerified) const NexoIcon('shield', size: 16, color: NexoColors.ok),
        ]),
      );
}

String orderStatusShort(Order o) => switch (o.status) {
      'pending' => o.iAmProvider ? 'Por responder' : 'Enviado',
      'accepted' => 'Aceptado',
      'resolved' => 'Resuelto',
      'rejected' => 'Rechazado',
      _ => 'Cancelado',
    };

BadgeTone orderTone(String status) => switch (status) {
      'pending' => BadgeTone.hot,
      'accepted' => BadgeTone.ok,
      'resolved' => BadgeTone.brand,
      _ => BadgeTone.plain,
    };

/// Tarjeta compacta de pedido (`matchCard`).
class OrderMiniCard extends ConsumerWidget {
  const OrderMiniCard({super.key, required this.o});
  final Order o;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(sessionProvider).name ?? 'Tú';
    final where = o.attention == 'shop' ? 'En su local' : 'A domicilio';
    return NexoCard(
      padding: const EdgeInsets.all(12),
      onTap: () => context.push(Routes.order(o.id)),
      child: Row(
        children: [
          AvatarPair(
              a: (me, null),
              b: (o.counterpart.displayName, o.counterpart.photoUrl),
              ok: o.status == 'accepted' || o.status == 'resolved',
              size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(o.counterpart.displayName,
                    overflow: TextOverflow.ellipsis, style: NexoText.body(14.5, weight: FontWeight.w800)),
                Text('${catInfo(o.category).name} · $where · ${o.ago}',
                    overflow: TextOverflow.ellipsis, style: NexoText.body(12.5, color: NexoColors.muted)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          NBadge(orderStatusShort(o), tone: orderTone(o.status)),
        ],
      ),
    );
  }
}

/// Pedido por responder del prestador (`provPendHTML`).
class PendingOrderCard extends ConsumerStatefulWidget {
  const PendingOrderCard({super.key, required this.o});
  final Order o;
  @override
  ConsumerState<PendingOrderCard> createState() => _PendingOrderCardState();
}

class _PendingOrderCardState extends ConsumerState<PendingOrderCard> {
  @override
  Widget build(BuildContext context) {
    final o = widget.o;
    final name = o.counterpart.displayName;
    return NexoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => context.push(Routes.order(o.id)),
            child: Row(children: [
              NexoAvatar(name: name, url: o.counterpart.photoUrl),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$name te hizo un pedido', style: NexoText.body(14.5, weight: FontWeight.w800)),
                    Text(
                        '${catInfo(o.category).name} · ${o.attention == 'shop' ? 'Irá a tu local' : 'A domicilio en ${o.placeZone}'} · ${o.ago}',
                        style: NexoText.body(12.5, color: NexoColors.muted)),
                  ],
                ),
              ),
              const NexoIcon('chevron', size: 18, color: NexoColors.muted),
            ]),
          ),
          if (o.description.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(o.description, style: NexoText.body(14, height: 1.45)),
          ],
          const SizedBox(height: 12),
          Row(children: [
            NexoIconButton(
              icon: 'chat',
              label: 'Escribirle a $name',
              onTap: () => o.conversationId == null
                  ? context.push(Routes.order(o.id))
                  : context.push(Routes.chat(o.conversationId!)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: NexoButton(
                  label: 'Rechazar',
                  variant: NexoButtonVariant.ghost,
                  onPressed: () => context.push(Routes.order(o.id))),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: NexoButton(label: 'Aceptar', icon: 'check', onPressed: () => context.push(Routes.order(o.id))),
            ),
          ]),
        ],
      ),
    );
  }
}

/// Resultado de búsqueda (`provRow`).
class ProviderRow extends ConsumerWidget {
  const ProviderRow({super.key, required this.p});
  final ProviderProfile p;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cmp = ref.watch(compareProvider).any((x) => x.id == p.id);
    final cats = p.categories.map((c) => catInfo(c).name).join(', ');
    return NexoCard(
      radius: 18,
      elevated: false,
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => context.push(Routes.provider(p.id)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NexoAvatar(name: p.name, url: p.photoUrl, size: 54),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Flexible(
                            child: Text(p.name,
                                overflow: TextOverflow.ellipsis, style: NexoText.display(16, weight: FontWeight.w700))),
                        if (p.emailVerified) ...[
                          const SizedBox(width: 4),
                          const NexoIcon('shield', size: 15, color: NexoColors.ok),
                        ],
                      ]),
                      Text('$cats · ${p.attentionText}${p.distanceText.isEmpty ? '' : ' · ${p.distanceText}'}',
                          style: NexoText.body(13, color: NexoColors.muted)),
                      const SizedBox(height: 6),
                      Wrap(spacing: 6, runSpacing: 4, children: [
                        NBadge(p.status.short, icon: 'clock', tone: p.status.open ? BadgeTone.ok : BadgeTone.plain),
                        if (p.rating.count > 0) NBadge('${p.rating.avg}', icon: 'star', tone: BadgeTone.hot),
                        Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Text('${p.recs} recomiendan', style: NexoText.body(12.5, color: NexoColors.muted))),
                        if (p.minPriceText != null) NBadge(p.minPriceText!, tone: BadgeTone.ink),
                        if (p.isNew) const NBadge('Perfil nuevo', tone: BadgeTone.brand),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              flex: 10,
              child: NexoButton(
                label: cmp ? 'Agregado' : 'Comparar',
                icon: cmp ? 'check' : 'compare',
                small: true,
                variant: NexoButtonVariant.line,
                onPressed: () => toggleCompare(context, ref, p.mini),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 14,
              child: NexoButton(
                label: 'Contactar',
                icon: 'chat',
                small: true,
                onPressed: () =>
                    showContactSheet(context, ref, p.mini, responseTime: p.responseTime, canCall: p.channelCall),
              ),
            ),
          ]),
        ],
      ),
    );
  }
}

/// Barra flotante de comparar (`cmpBar`).
class CompareBar extends ConsumerWidget {
  const CompareBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sel = ref.watch(compareProvider);
    if (sel.isEmpty) return const SizedBox.shrink();
    final two = sel.length >= 2;
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 10),
      padding: const EdgeInsets.fromLTRB(10, 8, 8, 8),
      decoration: BoxDecoration(
        color: NexoColors.ink,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [BoxShadow(color: Color(0x40071C21), blurRadius: 24, offset: Offset(0, 10))],
      ),
      child: Row(
        children: [
          for (var k = 0; k < 2; k++)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: k < sel.length
                  ? NexoAvatar(name: sel[k].name, url: sel[k].photoUrl, size: 34, border: true)
                  : Container(
                      width: 34,
                      height: 34,
                      decoration:
                          BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.white54, width: 1.5)),
                      child: const Center(child: NexoIcon('plus', size: 16, color: Colors.white70)),
                    ),
            ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(two ? 'Listos para comparar' : 'Elige 1 más para comparar',
                style: NexoText.body(13, weight: FontWeight.w700, color: Colors.white)),
          ),
          IconButton(
            tooltip: 'Limpiar selección',
            onPressed: () => ref.read(compareProvider.notifier).clear(),
            icon: const NexoIcon('close', size: 18, color: Colors.white70),
          ),
          NexoButton(
            label: 'Comparar',
            small: true,
            block: false,
            onPressed: two ? () => context.push(Routes.compare) : null,
          ),
        ],
      ),
    );
  }
}
