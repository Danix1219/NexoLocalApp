import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../core/auth/session_controller.dart';
import '../../core/widgets/map_view.dart';
import '../../core/widgets/nexo_field.dart';
import '../../core/widgets/nexo_icon.dart';
import '../../core/widgets/ui.dart';
import '../../data/api_provider.dart';
import '../../data/models.dart';
import '../common/cards.dart';
import '../shell/gate.dart';
import '../shell/top_bar.dart';
import 'filters.dart';

/// 7.6 Buscar — solicitante y 7.7 Buscar — prestador (`V.search`).
class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> {
  final _q = TextEditingController();
  final _focus = FocusNode();
  Timer? _debounce;
  List<Suggestion> _sugs = const [];
  bool _map = false;

  @override
  void initState() {
    super.initState();
    final pro = ref.read(sessionProvider).isProviderMode;
    _q.text = pro ? ref.read(oppFiltersProvider).q : ref.read(searchFiltersProvider).q;
    _focus.addListener(() {
      if (!_focus.hasFocus) setState(() => _sugs = const []);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool get _pro => ref.read(sessionProvider).isProviderMode;

  void _changed(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 280), () async {
      if (_pro) {
        ref.read(oppFiltersProvider.notifier).set(ref.read(oppFiltersProvider).copyWith(q: v));
        return;
      }
      ref.read(searchFiltersProvider.notifier).set(ref.read(searchFiltersProvider).copyWith(q: v));
      if (v.trim().length < 2) {
        if (mounted) setState(() => _sugs = const []);
        return;
      }
      try {
        final s = await ref.read(apiProvider).suggest(v, at: ref.read(searchLocationProvider).point);
        if (mounted && _focus.hasFocus) setState(() => _sugs = s);
      } catch (_) {}
    });
  }

  void _pick(Suggestion s) {
    final f = ref.read(searchFiltersProvider);
    if (s.kind == 'category') {
      _q.clear();
      ref.read(searchFiltersProvider.notifier).set(f.copyWith(q: '', cat: s.slug));
    } else {
      _q.text = s.label;
      ref.read(searchFiltersProvider.notifier).set(f.copyWith(q: s.label, cat: s.slug.isEmpty ? f.cat : s.slug));
    }
    _focus.unfocus();
    setState(() => _sugs = const []);
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sessionProvider);
    if (s.isProviderMode) {
      final mp = ref.watch(myProviderProvider);
      if (mp.asData != null && mp.asData!.value == null) return const NoProviderProfile(title: 'Buscar solicitudes');
      return _providerSearch(mp.asData?.value);
    }
    return Stack(
      children: [
        Positioned.fill(child: _clientSearch()),
        const Positioned(left: 0, right: 0, bottom: 0, child: CompareBar()),
      ],
    );
  }

  Widget _field(String hint, int filters, VoidCallback onFilters) {
    return Container(
      color: NexoColors.surface,
      padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _q,
              focusNode: _focus,
              onChanged: _changed,
              textInputAction: TextInputAction.search,
              style: NexoText.body(15.5),
              decoration: nexoInputDecoration(hint: hint).copyWith(
                prefixIcon: const Padding(
                    padding: EdgeInsets.only(left: 12, right: 8), child: NexoIcon('search', size: 20, color: NexoColors.muted)),
                prefixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                suffixIcon: _q.text.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Borrar',
                        onPressed: () {
                          _q.clear();
                          _changed('');
                          setState(() {});
                        },
                        icon: const NexoIcon('close', size: 18, color: NexoColors.muted),
                      ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          FilterButton(count: filters, onTap: onFilters),
        ],
      ),
    );
  }

  Widget _mapToggle() => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: SegControl<bool>(
          small: true,
          options: const [(false, 'Lista'), (true, 'Mapa')],
          value: _map,
          onChanged: (v) => setState(() => _map = v),
        ),
      );

  // ------------------------------------------------------------- cliente
  Widget _clientSearch() {
    final f = ref.watch(searchFiltersProvider);
    final res = ref.watch(searchResultsProvider);
    final loc = ref.watch(searchLocationProvider);
    return ListView(
      padding: const EdgeInsets.only(bottom: 90),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        const ScreenTitleBar('Buscar', trailing: LocationChip(), border: false),
        _field('Fuga, chapa, pintar, closet…', f.count, () => showSearchFiltersSheet(context, ref)),
        if (_sugs.isNotEmpty) _Suggestions(items: _sugs, query: _q.text, onPick: _pick),
        _ActiveChips(f: f),
        if (f.q.isEmpty && f.cat == null) ...[
          const Sect('Explora por servicio'),
          SizedBox(
            height: 96,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                for (final c in allCats)
                  _CatRing(
                    slug: c.id,
                    onTap: () => ref.read(searchFiltersProvider.notifier).set(f.copyWith(cat: c.id)),
                  ),
              ],
            ),
          ),
        ],
        _mapToggle(),
        if (_map)
          _NearbyMap(kind: 'providers', center: loc.point, radiusKm: loc.radiusKm)
        else
          asyncView(res, (r) {
            if (r.items.isEmpty) {
              return EmptyState(
                icon: 'search',
                title: 'No encontramos prestadores',
                text: 'Prueba con otra palabra, quita algún filtro o cambia la zona.',
                action: f.count > 0 || f.q.isNotEmpty ? 'Quitar filtros' : 'Cambiar ubicación',
                onAction: () {
                  if (f.count > 0 || f.q.isNotEmpty) {
                    _q.clear();
                    ref.read(searchFiltersProvider.notifier).set(const SearchFilters());
                  } else {
                    openSearchLocation(context, ref);
                  }
                },
              );
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (r.notice != null)
                  Padding(padding: const EdgeInsets.fromLTRB(12, 12, 12, 0), child: Notice(r.notice!, tone: BadgeTone.warn, icon: 'pin')),
                Sect('${r.items.length} ${plural(r.items.length, 'prestador', 'prestadores')}',
                    trailing: f.expanded ? 'Zona ampliada' : 'Atienden ${loc.zoneLabel}'),
                for (final p in r.items) ProviderRow(p: p),
                if (!f.expanded && !r.outOfZone)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Center(
                      child: TextButton(
                        onPressed: () => ref.read(searchFiltersProvider.notifier).set(f.copyWith(expanded: true)),
                        child: Text('Ver también los que están cerca pero fuera de tu zona',
                            style: NexoText.body(13.5, weight: FontWeight.w700, color: NexoColors.brand)),
                      ),
                    ),
                  ),
              ],
            );
          }, onRetry: () => ref.invalidate(searchResultsProvider)),
      ],
    );
  }

  // ----------------------------------------------------------- prestador
  Widget _providerSearch(MyProvider? me) {
    final f = ref.watch(oppFiltersProvider);
    final res = ref.watch(opportunitiesProvider);
    final p = me?.profile;
    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: [
        ScreenTitleBar('Buscar solicitudes',
            border: false,
            trailing: p == null
                ? null
                : NBadge('${p.zoneLabel} · ${p.radiusKm} km', icon: 'pin', tone: BadgeTone.brand)),
        _field('Fuga, boiler, pintar, chapa…', f.count, () => showOppFiltersSheet(context, ref)),
        _mapToggle(),
        if (_map && me != null)
          _NearbyMap(kind: 'requests', center: me.location ?? me.profile.zonePoint ?? ref.read(searchLocationProvider).point, radiusKm: p!.radiusKm == 0 ? 5 : p.radiusKm)
        else
          asyncView(res, (list) {
            if (list.isEmpty) {
              return EmptyState(
                icon: 'search',
                title: 'Ninguna solicitud coincide',
                text: 'Prueba quitando algún filtro o ampliando tu zona de atención.',
                action: 'Quitar filtros',
                onAction: () {
                  _q.clear();
                  ref.read(oppFiltersProvider.notifier).set(const OppFilters());
                },
              );
            }
            return Column(children: [
              Sect('${list.length} ${plural(list.length, 'solicitud', 'solicitudes')}'),
              for (final r in list) RequestCard(r: r),
            ]);
          }, onRetry: () => ref.invalidate(opportunitiesProvider)),
      ],
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.items, required this.query, required this.onPick});
  final List<Suggestion> items;
  final String query;
  final ValueChanged<Suggestion> onPick;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      decoration: BoxDecoration(
        color: NexoColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: NexoColors.line),
        boxShadow: const [BoxShadow(color: Color(0x1A1F302B), blurRadius: 20, offset: Offset(0, 8))],
      ),
      child: Column(
        children: [
          for (final s in items)
            InkWell(
              onTap: () => onPick(s),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(children: [
                  NexoIcon(s.kind == 'category' ? catInfo(s.slug).icon : 'search', size: 18, color: NexoColors.muted),
                  const SizedBox(width: 10),
                  Expanded(child: Text(s.label, style: NexoText.body(14.5, weight: FontWeight.w600))),
                  if (s.kind != 'term' && s.slug.isNotEmpty)
                    Text(catInfo(s.slug).name, style: NexoText.body(12, color: NexoColors.muted)),
                ]),
              ),
            ),
        ],
      ),
    );
  }
}

/// Chips de filtros activos (`activeChips`) con X para quitar cada uno.
class _ActiveChips extends ConsumerWidget {
  const _ActiveChips({required this.f});
  final SearchFilters f;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final n = ref.read(searchFiltersProvider.notifier);
    final chips = <(String, VoidCallback)>[
      if (f.cat != null) (catInfo(f.cat!).name, () => n.set(f.copyWith(cat: null))),
      if (f.open) ('Abierto ahora', () => n.set(f.copyWith(open: false))),
      if (f.free) ('Visita sin costo', () => n.set(f.copyWith(free: false))),
      if (f.prices) ('Con precios', () => n.set(f.copyWith(prices: false))),
      if (f.urgent) ('Urgencias', () => n.set(f.copyWith(urgent: false))),
      if (f.attention != null) (f.attention == 'home' ? 'A domicilio' : 'En su local', () => n.set(f.copyWith(attention: null))),
      if (f.sort == 'near') ('Más cerca', () => n.set(f.copyWith(sort: 'relevance'))),
      if (f.sort == 'recs') ('Más recomendados', () => n.set(f.copyWith(sort: 'relevance'))),
    ];
    if (chips.isEmpty) return const SizedBox.shrink();
    return Container(
      color: NexoColors.surface,
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
        children: [
          for (final c in chips)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: InputChip(
                label: Text(c.$1, style: NexoText.body(12.5, weight: FontWeight.w700, color: NexoColors.brandDeep)),
                backgroundColor: NexoColors.brandSoft,
                side: BorderSide.none,
                shape: const StadiumBorder(),
                deleteIcon: const NexoIcon('close', size: 14, color: NexoColors.brandDeep),
                onDeleted: c.$2,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
        ],
      ),
    );
  }
}

/// Aro de categoría (`catRing`).
class _CatRing extends StatelessWidget {
  const _CatRing({required this.slug, required this.onTap});
  final String slug;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = catInfo(slug);
    return Semantics(
      button: true,
      label: c.name,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          width: 76,
          child: Column(
            children: [
              Container(
                width: 62,
                height: 62,
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(colors: [NexoColors.accent, NexoColors.accent2, NexoColors.brand, NexoColors.accent]),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: NexoColors.surface, width: 3),
                    gradient: LinearGradient(
                        begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [hexColor(c.c1), hexColor(c.c2)]),
                  ),
                  child: Center(child: NexoIcon(c.icon, size: 24, color: Colors.white)),
                ),
              ),
              const SizedBox(height: 6),
              Text(c.name.replaceAll(' servicios', ''),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: NexoText.body(12, weight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Vista de mapa (`provMapHTML` / `reqMapHTML`).
class _NearbyMap extends ConsumerStatefulWidget {
  const _NearbyMap({required this.kind, required this.center, required this.radiusKm});
  final String kind;
  final GeoPoint center;
  final int radiusKm;
  @override
  ConsumerState<_NearbyMap> createState() => _NearbyMapState();
}

class _NearbyMapState extends ConsumerState<_NearbyMap> {
  late Future<MapNearby> _f = _load();
  MapPoint? _sel;

  Future<MapNearby> _load() =>
      ref.read(apiProvider).mapNearby(at: widget.center, radiusKm: widget.radiusKm, kind: widget.kind);

  @override
  void didUpdateWidget(_NearbyMap old) {
    super.didUpdateWidget(old);
    if (old.center.lat != widget.center.lat || old.radiusKm != widget.radiusKm || old.kind != widget.kind) {
      _f = _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<MapNearby>(
      future: _f,
      builder: (context, snap) {
        if (snap.hasError) {
          return ErrorView(snap.error!, onRetry: () => setState(() {
                _f = _load();
              }));
        }
        if (!snap.hasData) return const LoadingView();
        final m = snap.data!;
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              PointsMap(
                center: widget.center,
                radiusKm: widget.radiusKm,
                points: m.points,
                height: 340,
                onTapPoint: (p) => setState(() => _sel = p),
              ),
              const SizedBox(height: 8),
              Text(m.summary, style: NexoText.body(13, color: NexoColors.muted)),
              if (_sel != null)
                NexoCard(
                  margin: const EdgeInsets.only(top: 10),
                  onTap: widget.kind == 'providers' ? () => context.push(Routes.provider(_sel!.id)) : null,
                  child: Row(children: [
                    NexoIcon(widget.kind == 'providers' ? 'user' : 'search', size: 22, color: NexoColors.brand),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_sel!.title, style: NexoText.body(14.5, weight: FontWeight.w800)),
                          Text(_sel!.subtitle, style: NexoText.body(12.5, color: NexoColors.muted)),
                        ],
                      ),
                    ),
                    if (widget.kind == 'providers') const NexoIcon('chevron', size: 18, color: NexoColors.muted),
                  ]),
                ),
            ],
          ),
        );
      },
    );
  }
}
