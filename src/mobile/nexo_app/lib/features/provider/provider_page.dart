import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/router.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../core/widgets/map_view.dart';
import '../../core/widgets/nexo_button.dart';
import '../../core/widgets/nexo_icon.dart';
import '../../core/widgets/toast.dart';
import '../../core/widgets/ui.dart';
import '../../data/api_provider.dart';
import '../../data/models.dart';
import '../common/actions.dart';
import 'edit_sheets.dart';

Future<void> openDirections(GeoPoint p) async {
  final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${p.lat},${p.lng}');
  if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
    showNexoToast('No pudimos abrir el mapa');
  }
}

/// 7.8 Perfil del prestador (`V.profile`), también "Mi perfil" del prestador.
class ProviderPage extends ConsumerStatefulWidget {
  const ProviderPage({super.key, required this.id});
  final String id;

  @override
  ConsumerState<ProviderPage> createState() => _ProviderPageState();
}

class _ProviderPageState extends ConsumerState<ProviderPage> {
  String _tab = 'work';
  bool? _saved;

  @override
  Widget build(BuildContext context) {
    final mine = ref.watch(myProviderProvider).asData?.value;
    final own = mine != null && (widget.id == 'me' || widget.id == mine.profile.id);
    final v = own ? AsyncValue<ProviderProfile>.data(mine.profile) : ref.watch(providerProfileProvider(widget.id));
    final p = v.asData?.value;
    return NexoPage(
      background: NexoColors.surface,
      child: Column(
        children: [
          SubBar(own ? 'Mi perfil' : 'Perfil', actions: [
            if (!own && p != null)
              _BarIcon(
                  icon: 'flag',
                  label: 'Reportar perfil',
                  onTap: () => showReportSheet(context, ref, targetType: 'provider', targetId: p.id)),
          ]),
          Expanded(
            child: asyncView(v, (p) => _body(p, own, mine),
                onRetry: () => ref.invalidate(providerProfileProvider(widget.id))),
          ),
        ],
      ),
    );
  }

  Widget _body(ProviderProfile p, bool own, MyProvider? mine) {
    final saved = _saved ??
        (ref.watch(savedProvider).asData?.value.$1.any((s) => s.kind == 'provider' && s.targetId == p.id) ?? false);
    final cats = p.categories.map((c) => catInfo(c).name).join(', ');
    final facts = <(String, String, bool)>[
      (p.attention == 'shop' ? 'pin' : 'home', p.attentionText, false),
      ('clock', p.status.short, p.status.open),
      if (p.visitText != null) ('info', p.visitText!, false),
      ('info', p.minPriceText ?? 'Sin precios publicados', false),
    ];
    return RefreshIndicator(
      color: NexoColors.brand,
      onRefresh: () async {
        ref.invalidate(providerProfileProvider(widget.id));
        ref.invalidate(myProviderProvider);
        ref.invalidate(providerWorksProvider(p.id));
        ref.invalidate(reviewsProvider(p.id));
      },
      child: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          SizedBox(
            height: 94,
            child: p.coverUrl != null
                ? NexoImage(p.coverUrl!)
                : const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [NexoColors.brandSoft, NexoColors.accentSoft]),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.translate(
                  offset: const Offset(0, -42),
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 0),
                    child: NexoAvatar(name: p.name, url: p.photoUrl, size: 84, border: true),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -34),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: NexoText.display(22)),
                      const SizedBox(height: 2),
                      Text('${p.isBusiness ? 'Negocio' : 'Persona con oficio'} · $cats',
                          style: NexoText.body(14, color: NexoColors.muted)),
                      const SizedBox(height: 10),
                      Wrap(spacing: 6, runSpacing: 6, children: [
                        if (p.phoneVerified)
                          NBadge('Teléfono confirmado',
                              icon: 'shield', tone: BadgeTone.ok, onTap: () => showTrustSheet(context)),
                        if (p.isNew) const NBadge('Perfil nuevo', tone: BadgeTone.brand),
                        if (p.updatedText.isNotEmpty)
                          NBadge(p.badges.any((b) => b.key == 'stale') ? 'Sin actualizar' : p.updatedText,
                              icon: 'clock',
                              tone: p.badges.any((b) => b.key == 'stale') ? BadgeTone.warn : BadgeTone.plain),
                      ]),
                      const SizedBox(height: 10),
                      Facts(facts),
                      const SizedBox(height: 14),
                      StatsRow([
                        ('${p.jobs}', 'Trabajos'),
                        ('${p.recs}', 'Recomiendan'),
                        if (p.attention == 'shop')
                          (
                            own ? 'Local' : p.distanceText.replaceFirst('a ', '').replaceFirst('~', ''),
                            own ? 'Atención' : 'Del local a ti'
                          )
                        else
                          ('${p.radiusKm} km', 'Radio'),
                      ]),
                      const SizedBox(height: 14),
                      if (own) ...[
                        Row(children: [
                          Expanded(
                            child: NexoButton(
                                label: 'Publicar un trabajo',
                                icon: 'plus',
                                onPressed: () => context.go(Routes.publish)),
                          ),
                          const SizedBox(width: 8),
                          NexoButton(
                              label: 'Compartir',
                              icon: 'share',
                              block: false,
                              variant: NexoButtonVariant.ghost,
                              onPressed: () => shareLink('/p/${p.id}', 'tu perfil')),
                        ]),
                      ] else ...[
                        Row(children: [
                          Expanded(
                            child: NexoButton(
                              label: 'Contactar',
                              icon: 'chat',
                              onPressed: () => showContactSheet(context, ref, p.mini,
                                  responseTime: p.responseTime, canCall: p.channelCall),
                            ),
                          ),
                          const SizedBox(width: 8),
                          NexoButton(
                            label: saved ? 'Guardado' : 'Guardar',
                            icon: 'bookmark',
                            block: false,
                            variant: NexoButtonVariant.ghost,
                            onPressed: () async {
                              final r = await toggleSaved(context, ref, 'provider', p.id, !saved);
                              if (r != null && mounted) setState(() => _saved = r);
                            },
                          ),
                          const SizedBox(width: 8),
                          _BarIcon(
                              icon: 'share', label: 'Compartir perfil', onTap: () => shareLink('/p/${p.id}', 'perfil')),
                        ]),
                        const SizedBox(height: 8),
                        NexoButton(
                          label: 'Pedir este servicio',
                          icon: 'thumb',
                          variant: NexoButtonVariant.line,
                          onPressed: () => showRequestServiceSheet(context, ref, p),
                        ),
                        if (p.hasShop && p.shopLocation != null) ...[
                          const SizedBox(height: 8),
                          NexoButton(
                            label: 'Cómo llegar al local · ${p.distanceText.replaceFirst('a ', '')}',
                            icon: 'pin',
                            variant: NexoButtonVariant.line,
                            onPressed: () => openDirections(p.shopLocation!),
                          ),
                        ],
                      ],
                    ],
                  ),
                ),
                if (own && mine != null) Transform.translate(offset: const Offset(0, -20), child: _TodoCard(me: mine)),
              ],
            ),
          ),
          _Tabs(value: _tab, onChanged: (t) => setState(() => _tab = t)),
          if (_tab == 'work') _WorksTab(p: p, own: own),
          if (_tab == 'info') _InfoTab(p: p, own: own),
          if (_tab == 'trust') _TrustTab(p: p),
        ],
      ),
    );
  }
}

class _BarIcon extends StatelessWidget {
  const _BarIcon({required this.icon, required this.label, required this.onTap});
  final String icon;
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => NexoIconButton(icon: icon, label: label, onTap: onTap);
}

class _Tabs extends StatelessWidget {
  const _Tabs({required this.value, required this.onChanged});
  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    const tabs = [('work', 'Trabajos'), ('info', 'Información'), ('trust', 'Opiniones')];
    return Container(
      decoration: const BoxDecoration(
        color: NexoColors.surface,
        border: Border(top: BorderSide(color: NexoColors.line), bottom: BorderSide(color: NexoColors.line)),
      ),
      child: Row(children: [
        for (final t in tabs)
          Expanded(
            child: Semantics(
              selected: value == t.$1,
              button: true,
              child: InkWell(
                onTap: () => onChanged(t.$1),
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: value == t.$1 ? NexoColors.brand : Colors.transparent, width: 2.5)),
                  ),
                  child: Text(t.$2,
                      style: NexoText.body(14,
                          weight: FontWeight.w700, color: value == t.$1 ? NexoColors.ink : NexoColors.muted)),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

/// Tarjeta "Completa tu perfil" (`todoCard`).
class _TodoCard extends ConsumerWidget {
  const _TodoCard({required this.me});
  final MyProvider me;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pending = me.todo.where((t) => !t.done).toList();
    if (pending.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: NexoColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: NexoColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(child: Text('Completa tu perfil', style: NexoText.display(16, weight: FontWeight.w700))),
            Text('${me.completeness}%', style: NexoText.display(16, color: NexoColors.brand)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: LinearProgressIndicator(
              value: me.completeness / 100,
              minHeight: 7,
              color: NexoColors.brand,
              backgroundColor: NexoColors.surface2,
            ),
          ),
          const SizedBox(height: 10),
          for (final t in pending)
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => openTodo(context, ref, t.key, me),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 9),
                child: Row(children: [
                  const NexoIcon('plus', size: 18, color: NexoColors.brand),
                  const SizedBox(width: 10),
                  Expanded(child: Text(t.label, style: NexoText.body(14, weight: FontWeight.w600))),
                  Text('+${t.points}',
                      style: NexoText.body(12.5, weight: FontWeight.w800, color: NexoColors.accentInk)),
                  const SizedBox(width: 4),
                  const NexoIcon('chevron', size: 16, color: NexoColors.muted),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

class _WorksTab extends ConsumerWidget {
  const _WorksTab({required this.p, required this.own});
  final ProviderProfile p;
  final bool own;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(providerWorksProvider(p.id));
    return asyncView(v, (works) {
      final tiles = [
        for (final w in works) (w, w.images.isEmpty ? Img('demo://${w.category}/0') : w.images.first),
      ];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (tiles.isNotEmpty || p.portfolio.isNotEmpty) ...[
            const Sect('Fotos'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 3,
                crossAxisSpacing: 3,
                children: [
                  for (final t in tiles)
                    GestureDetector(
                      onTap: () => showWorkSheet(context, t.$1),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(6), child: NexoImage(t.$2.thumbUrl ?? t.$2.url)),
                    ),
                  for (final im in p.portfolio)
                    ClipRRect(borderRadius: BorderRadius.circular(6), child: NexoImage(im.thumbUrl ?? im.url)),
                ],
              ),
            ),
          ],
          Sect(own ? 'Mis publicaciones' : 'Trabajos publicados', trailing: '${works.length}'),
          if (works.isEmpty)
            EmptyState(
              title: own ? 'Aún no publicas trabajos' : 'Aún no hay trabajos',
              text: own
                  ? 'Cada trabajo que publiques aparecerá aquí y en el inicio de quien busca.'
                  : 'Este prestador todavía no ha publicado trabajos.',
              action: own ? 'Publicar un trabajo' : null,
              onAction: () => context.go(Routes.publish),
            ),
          for (final w in works)
            NexoCard(
              padding: const EdgeInsets.all(10),
              onTap: () => showWorkSheet(context, w),
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 72,
                    height: 72,
                    child: NexoImage(
                        w.images.isEmpty ? 'demo://${w.category}/0' : (w.images.first.thumbUrl ?? w.images.first.url)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(w.title, style: NexoText.body(14.5, weight: FontWeight.w800)),
                      Text('${catInfo(w.category).name} · ${w.ago}',
                          style: NexoText.body(12.5, color: NexoColors.muted)),
                      Text('${w.recs} ${plural(w.recs, 'recomendación', 'recomendaciones')}',
                          style: NexoText.body(12.5, color: NexoColors.muted)),
                    ],
                  ),
                ),
                if (own)
                  IconButton(
                    tooltip: 'Borrar trabajo',
                    icon: const NexoIcon('trash', size: 20, color: NexoColors.danger),
                    onPressed: () => deleteWork(context, ref, w, p.id),
                  ),
              ]),
            ),
        ],
      );
    }, onRetry: () => ref.invalidate(providerWorksProvider(p.id)));
  }
}

const _dayNames = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];

class _ICard extends StatelessWidget {
  const _ICard({required this.icon, required this.title, required this.child, this.onEdit});
  final String icon;
  final String title;
  final Widget child;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) => NexoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              NexoIcon(icon, size: 18, color: NexoColors.brand),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: NexoText.display(15.5, weight: FontWeight.w700))),
              if (onEdit != null)
                InkWell(
                  onTap: onEdit,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text('Editar', style: NexoText.body(13, weight: FontWeight.w800, color: NexoColors.brand)),
                  ),
                ),
            ]),
            const SizedBox(height: 10),
            child,
          ],
        ),
      );
}

class _InfoTab extends ConsumerStatefulWidget {
  const _InfoTab({required this.p, required this.own});
  final ProviderProfile p;
  final bool own;
  @override
  ConsumerState<_InfoTab> createState() => _InfoTabState();
}

class _InfoTabState extends ConsumerState<_InfoTab> {
  bool _week = false;
  bool _bio = false;

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final own = widget.own;
    final today = DateTime.now().weekday - 1;
    final np = Text('No publicó', style: NexoText.body(14, color: NexoColors.muted));
    final services = p.specialties.isNotEmpty ? p.specialties : p.categories.map((c) => catInfo(c).name).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ICard(
          icon: 'clock',
          title: 'Disponibilidad',
          onEdit: own ? () => showHoursSheet(context, ref, p) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Notice(p.status.text, icon: 'clock', tone: p.status.open ? BadgeTone.ok : BadgeTone.plain),
              if (p.days.any((d) => d != null)) ...[
                InkWell(
                  onTap: () => setState(() => _week = !_week),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(children: [
                      Text('Ver horario de la semana',
                          style: NexoText.body(13.5, weight: FontWeight.w700, color: NexoColors.brand)),
                      const SizedBox(width: 4),
                      AnimatedRotation(
                        turns: _week ? .25 : 0,
                        duration: const Duration(milliseconds: 150),
                        child: const NexoIcon('chevron', size: 15, color: NexoColors.brand),
                      ),
                    ]),
                  ),
                ),
                if (_week)
                  for (var i = 0; i < 7; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(children: [
                        Expanded(
                          child: Text(_dayNames[i],
                              style: NexoText.body(14, weight: i == today ? FontWeight.w800 : FontWeight.w400)),
                        ),
                        Text(
                          i < p.days.length && p.days[i] != null
                              ? '${p.days[i]!.open} a ${p.days[i]!.close}'
                              : 'Cerrado',
                          style: NexoText.body(14,
                              weight: i == today ? FontWeight.w800 : FontWeight.w400,
                              color: i < p.days.length && p.days[i] != null ? NexoColors.ink : NexoColors.muted),
                        ),
                      ]),
                    ),
                if (p.urgent) const NBadge('Atiende urgencias', icon: 'bolt', tone: BadgeTone.hot),
              ] else
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('Este prestador no publicó su horario. Pregúntale al contactarlo.',
                      style: NexoText.body(13, color: NexoColors.muted)),
                ),
            ],
          ),
        ),
        _ICard(
          icon: 'hammer',
          title: p.isBusiness ? 'Giro y especialidades' : 'Oficio',
          onEdit: own ? () => showServicesSheet(context, ref, p) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (p.activity != null) ...[Text(p.activity!, style: NexoText.body(14)), const SizedBox(height: 8)],
              Wrap(spacing: 6, runSpacing: 6, children: [for (final s in services) NBadge(s, tone: BadgeTone.ink)]),
            ],
          ),
        ),
        if (p.bio.isNotEmpty || own)
          _ICard(
            icon: 'user',
            title: 'Acerca de',
            onEdit: own ? () => showBasicSheet(context, ref, p) : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.bio.isEmpty ? 'Cuenta en pocas líneas qué haces y cómo trabajas.' : p.bio,
                    maxLines: _bio ? null : 3,
                    overflow: _bio ? null : TextOverflow.ellipsis,
                    style: NexoText.body(14, height: 1.5, color: p.bio.isEmpty ? NexoColors.muted : NexoColors.ink)),
                if (p.bio.length > 130)
                  InkWell(
                    onTap: () => setState(() => _bio = !_bio),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(_bio ? 'Ver menos' : 'Ver más',
                          style: NexoText.body(13.5, weight: FontWeight.w800, color: NexoColors.brand)),
                    ),
                  ),
                if (p.owner != null || p.experience != null || p.crew != null) ...[
                  const SizedBox(height: 8),
                  if (p.owner != null) InfoRow('Responsable', p.owner!),
                  if (p.experience != null) InfoRow('Experiencia', '${p.experience} años'),
                  if (p.crew != null)
                    InfoRow('Trabaja',
                        switch (p.crew) { 'alone' => 'Solo', 'withHelpers' => 'Con ayudantes', _ => 'Con equipo' }),
                ],
              ],
            ),
          ),
        _ICard(
          icon: 'info',
          title: 'Precios de referencia',
          onEdit: own ? () => showPricesSheet(context, ref, p) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InfoRow('Visita', p.visitText ?? 'No publicó', muted: p.visitText == null),
              if (p.prices.isEmpty)
                Padding(padding: const EdgeInsets.only(top: 4), child: np)
              else
                for (final x in p.prices)
                  InfoRow(
                    x.service,
                    x.fromCents == null
                        ? 'A cotizar'
                        : '${x.unit == 'from' ? 'Desde ' : ''}${formatMoney(x.fromCents!)}${x.suffix.isEmpty ? '' : ' ${x.suffix}'}',
                  ),
              const SizedBox(height: 4),
              Text('Precios declarados por el prestador. El precio final se acuerda contigo.',
                  style: NexoText.body(12, color: NexoColors.muted)),
            ],
          ),
        ),
        _ICard(
          icon: 'shield',
          title: 'Condiciones',
          onEdit: own ? () => showTermsEditSheet(context, ref, p) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              InfoRow('Responde', p.responseTime ?? 'No publicó', muted: p.responseTime == null),
              InfoRow('Pago', p.payment.isEmpty ? 'No publicó' : p.payment.join(', '), muted: p.payment.isEmpty),
              InfoRow('Garantía', p.warranty ?? 'No publicó', muted: p.warranty == null),
              InfoRow('Factura', p.invoice ? 'Sí emite' : 'No', muted: !p.invoice),
              if (p.web != null) InfoRow('Sitio web', p.web!),
              InfoRow('Contacto', p.channelCall ? 'Chat y llamada' : 'Solo chat'),
            ],
          ),
        ),
        _ICard(
          icon: 'pin',
          title: p.attention == 'shop' ? 'Su local' : 'Zona que atiende',
          onEdit: own ? () => showZoneSheet(context, ref, p) : null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              MiniMap(
                point: p.shopLocation ?? p.zonePoint ?? ref.read(searchLocationProvider).point,
                radiusKm: p.attention == 'shop' ? 0 : p.radiusKm,
                label: p.attention == 'shop' ? p.zoneLabel : '${p.zoneLabel} · hasta ${p.radiusKm} km',
                approximate: p.shopLocation == null && p.attention != 'shop' && p.radiusKm == 0,
              ),
              const SizedBox(height: 8),
              Text(p.attentionText, style: NexoText.body(13.5, color: NexoColors.muted)),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrustTab extends ConsumerWidget {
  const _TrustTab({required this.p});
  final ProviderProfile p;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final v = ref.watch(reviewsProvider(p.id));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        NexoCard(
          child: Wrap(spacing: 14, runSpacing: 8, children: [
            _sig('shield', p.phoneVerified ? 'Teléfono confirmado' : 'Teléfono sin confirmar', p.phoneVerified),
            if (p.rating.count > 0) _sig('star', '${p.rating.avg} (${p.rating.count})', false),
            _sig('thumb', '${p.recs} recomiendan', false),
            _sig('clock', p.updatedText, false),
          ]),
        ),
        asyncView(v, (r) {
          if (r.items.isEmpty) {
            return EmptyState(
              icon: 'star',
              title: 'Aún sin opiniones',
              text: p.isNew
                  ? 'Perfil nuevo, aún sin historial. No es una calificación negativa.'
                  : 'Cuando alguien lo califique, lo verás aquí.',
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Sect('Opiniones', trailing: '${r.recommendCount} de ${r.count} recomiendan'),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: LinearProgressIndicator(
                    value: r.count == 0 ? 0 : r.recommendCount / r.count,
                    minHeight: 7,
                    color: NexoColors.ok,
                    backgroundColor: NexoColors.surface2,
                  ),
                ),
              ),
              for (final e in r.items)
                NexoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        NexoAvatar(name: e.author, url: e.authorPhoto, size: 36),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.author, style: NexoText.body(14, weight: FontWeight.w800)),
                              Text(e.ago, style: NexoText.body(12, color: NexoColors.muted)),
                            ],
                          ),
                        ),
                        StarsView(e.stars, size: 14),
                      ]),
                      const SizedBox(height: 8),
                      Text(e.text, style: NexoText.body(14, height: 1.45)),
                      if (e.recommend) ...[
                        const SizedBox(height: 8),
                        const NBadge('Lo recomienda', icon: 'thumb', tone: BadgeTone.ok),
                      ],
                    ],
                  ),
                ),
            ],
          );
        }, onRetry: () => ref.invalidate(reviewsProvider(p.id))),
        Center(
          child: TextButton(
            onPressed: () => showTrustSheet(context),
            child: Text('Cómo leer estas señales',
                style: NexoText.body(13.5, weight: FontWeight.w700, color: NexoColors.brand)),
          ),
        ),
      ],
    );
  }

  Widget _sig(String icon, String t, bool ok) => Row(mainAxisSize: MainAxisSize.min, children: [
        NexoIcon(icon, size: 16, color: ok ? NexoColors.ok : NexoColors.muted),
        const SizedBox(width: 5),
        Text(t, style: NexoText.body(13, weight: FontWeight.w600, color: ok ? NexoColors.ok : NexoColors.muted)),
      ]);
}
