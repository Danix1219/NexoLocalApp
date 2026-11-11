import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme/tokens.dart';
import '../../app/theme/typography.dart';
import '../../core/auth/session_controller.dart';
import '../../core/widgets/nexo_button.dart';
import '../../core/widgets/nexo_icon.dart';
import '../../core/widgets/ui.dart';
import '../../data/api_provider.dart';
import '../../data/models.dart';
import '../common/cards.dart';
import '../search/filters.dart';
import '../shell/top_bar.dart';

/// 7.4 Inicio — solicitante y 7.5 Inicio — prestador (`V.home`).
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  String _clientTab = 'for'; // for | mine
  String _proTab = 'comm'; // comm | opp

  Future<void> _refresh() async {
    refreshActivity(ref);
    ref.invalidate(myProviderProvider);
    await Future<void>.delayed(const Duration(milliseconds: 400));
  }

  @override
  Widget build(BuildContext context) {
    final s = ref.watch(sessionProvider);
    final body = s.isProviderMode ? _provider() : _client(s);
    return Stack(
      children: [
        Positioned.fill(
          child: RefreshIndicator(color: NexoColors.brand, onRefresh: _refresh, child: body),
        ),
        const Positioned(left: 0, right: 0, bottom: 0, child: CompareBar()),
      ],
    );
  }

  Widget _withHeader(List<Widget> header, {EdgeInsetsGeometry? padding, required List<Widget> children}) => Column(
        children: [
          header.first,
          Expanded(
              child: ListView(
            padding: padding,
            physics: const AlwaysScrollableScrollPhysics(),
            children: [...header.skip(1), ...children],
          )),
        ],
      );

  // ------------------------------------------------------------- cliente
  Widget _client(SessionState s) {
    final feed = ref.watch(feedProvider);
    final mine = ref.watch(myRequestsProvider);
    final open = mine.asData?.value.where((r) => !r.closed).length ?? 0;
    final loc = ref.watch(searchLocationProvider);
    final pendingDot = mine.asData?.value.any((r) => !r.closed) ?? false;

    final header = <Widget>[
      HomeTopBar(dot: pendingDot && s.isSignedIn),
      _SearchRow(
        hint: 'Buscar servicio en ${loc.zoneLabel}',
        onTap: () => context.go(Routes.search),
        filters: ref.watch(searchFiltersProvider).count,
        onFilters: () async {
          await showSearchFiltersSheet(context, ref);
          if (!mounted) return;
          context.go(Routes.search);
        },
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: SegControl<String>(
          options: [('for', 'Para ti'), ('mine', 'Mis solicitudes · ${s.isGuest ? 0 : open}')],
          value: _clientTab,
          onChanged: (v) => setState(() => _clientTab = v),
        ),
      ),
    ];

    if (_clientTab == 'mine') {
      if (s.isGuest) {
        return _withHeader(header, children: [
          EmptyState(
            icon: 'search',
            title: 'Publica lo que necesitas',
            text: 'Con una cuenta puedes publicar lo que buscas y dejar que los prestadores de tu zona te contacten.',
            action: 'Crear cuenta gratis',
            onAction: () {
              ref.read(sessionProvider.notifier).leaveGuest();
              context.go(Routes.registerEmail);
            },
          ),
        ]);
      }
      final orders = ref.watch(ordersProvider('client'));
      final active =
          orders.asData?.value.items.where((o) => o.status != 'cancelled' && o.status != 'rejected').toList() ??
              const <Order>[];
      return _withHeader(
        header,
        padding: const EdgeInsets.only(bottom: 90),
        children: [
          if (active.isNotEmpty) ...[
            const Sect('Mis servicios'),
            for (final o in active) OrderMiniCard(o: o),
          ],
          const Sect('Mis solicitudes'),
          asyncView(mine, (list) {
            if (list.isEmpty) {
              return EmptyState(
                icon: 'search',
                title: 'Aún no has publicado lo que necesitas',
                text: 'Cuéntalo en pocas palabras y deja que los prestadores de tu zona te contacten.',
                action: 'Publicar lo que necesito',
                onAction: () => context.go(Routes.publish),
              );
            }
            return Column(children: [for (final r in list) RequestCard(r: r)]);
          }, onRetry: () => ref.invalidate(myRequestsProvider)),
        ],
      );
    }

    return _withHeader(
      header,
      padding: const EdgeInsets.only(bottom: 90),
      children: [
        asyncView(feed, (f) {
          final interests = {
            ...ref.watch(interestsProvider),
            ...(mine.asData?.value ?? const <ServiceRequest>[]).where((r) => !r.closed).map((r) => r.category),
          };
          final items = [
            ...f.page.items.where((w) => interests.contains(w.category)),
            ...f.page.items.where((w) => !interests.contains(w.category)),
          ];
          final shown = s.isGuest ? items.take(2).toList() : items;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Sect('Trabajos en ${f.zoneLabel.isEmpty ? loc.zoneLabel : f.zoneLabel}'),
              if (items.isEmpty)
                const EmptyState(
                  icon: 'info',
                  title: 'Aún no hay trabajos aquí',
                  text: 'Prueba con otra zona o busca un servicio directamente.',
                ),
              for (final w in shown) WorkCard(work: w),
              if (s.isGuest) const _GuestMore(),
            ],
          );
        }, onRetry: () => ref.invalidate(feedProvider)),
      ],
    );
  }

  // ----------------------------------------------------------- prestador
  Widget _provider() {
    final mp = ref.watch(myProviderProvider);
    return mp.when(
      loading: () => ListView(children: const [HomeTopBar(), LoadingView()]),
      error: (e, _) =>
          ListView(children: [const HomeTopBar(), ErrorView(e, onRetry: () => ref.invalidate(myProviderProvider))]),
      data: (me) {
        if (me == null) {
          return ListView(children: [
            const HomeTopBar(),
            EmptyState(
              icon: 'hammer',
              title: 'Crea tu perfil para ver oportunidades',
              text: 'Con tu perfil verás las solicitudes de personas que buscan justo lo que ofreces en tus zonas.',
              action: 'Crear mi perfil',
              onAction: () => context.push(Routes.proOnboarding),
            ),
          ]);
        }
        return _providerHome(me);
      },
    );
  }

  Widget _providerHome(MyProvider me) {
    final opps = ref.watch(opportunitiesProvider);
    final orders = ref.watch(ordersProvider('provider'));
    final f = ref.watch(oppFiltersProvider);
    final count = opps.asData?.value.length ?? 0;
    final header = <Widget>[
      HomeTopBar(zoneLabel: me.profile.zoneLabel, dot: (orders.asData?.value.pending ?? 0) > 0),
      _SearchRow(
        hint: 'Buscar solicitudes cerca de ti',
        onTap: () => context.go(Routes.search),
        filters: f.count,
        onFilters: () => showOppFiltersSheet(context, ref),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: SegControl<String>(
          options: [('comm', 'Comunidad'), ('opp', 'Oportunidades · $count')],
          value: _proTab,
          onChanged: (v) => setState(() => _proTab = v),
        ),
      ),
    ];

    if (_proTab == 'comm') {
      final feed = ref.watch(feedProvider);
      return _withHeader(
        header,
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          const Sect('Trabajos de tu rubro'),
          asyncView(feed, (fp) {
            final mine = me.profile.categories.toSet();
            final list =
                fp.page.items.where((w) => mine.contains(w.category) && w.provider.id != me.profile.id).toList();
            if (list.isEmpty) {
              return const EmptyState(
                icon: 'info',
                title: 'Aún no hay trabajos de tu rubro',
                text: 'Cuando otros prestadores de tus categorías publiquen, los verás aquí.',
              );
            }
            return Column(children: [for (final w in list) WorkCard(work: w)]);
          }, onRetry: () => ref.invalidate(feedProvider)),
        ],
      );
    }

    final all = orders.asData?.value.items ?? const <Order>[];
    final pend = all.where((o) => o.status == 'pending').toList();
    final ok = all.where((o) => o.status == 'accepted').toList();
    return _withHeader(
      header,
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        if (pend.isNotEmpty) ...[
          const Sect('Pedidos por responder'),
          for (final o in pend) PendingOrderCard(o: o),
        ],
        if (ok.isNotEmpty) ...[
          const Sect('Pedidos aceptados'),
          for (final o in ok) OrderMiniCard(o: o),
        ],
        Sect('Solicitudes para ti · $count', trailing: f.cat == null ? null : catInfo(f.cat!).name),
        asyncView(opps, (list) {
          if (list.isEmpty) {
            return EmptyState(
              icon: 'search',
              title: 'Aún no hay solicitudes para tu perfil',
              text: 'Cuando alguien publique lo que ofreces en tu zona, aparecerá aquí.',
              action: f.count > 0 ? 'Quitar filtros' : null,
              onAction: () => ref.read(oppFiltersProvider.notifier).set(const OppFilters()),
            );
          }
          return Column(children: [for (final r in list) RequestCard(r: r)]);
        }, onRetry: () => ref.invalidate(opportunitiesProvider)),
        if (me.completeness < 100) ...[
          const Sect('Áreas de oportunidad'),
          NexoCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: NexoColors.accentSoft, borderRadius: BorderRadius.circular(12)),
                  child: const Center(child: NexoIcon('bolt', size: 19, color: NexoColors.accentInk)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tu perfil está al ${me.completeness}%',
                          style: NexoText.body(14.5, weight: FontWeight.w800)),
                      const SizedBox(height: 2),
                      Text(
                          'Los perfiles completos aparecen primero. Siguiente: ${me.todo.where((t) => !t.done).map((t) => t.label).firstOrNull ?? 'listo'}.',
                          style: NexoText.body(13, color: NexoColors.muted, height: 1.4)),
                      const SizedBox(height: 8),
                      NexoButton(
                        label: 'Completar mi perfil',
                        small: true,
                        block: false,
                        variant: NexoButtonVariant.ghost,
                        onPressed: () => context.push(Routes.provider(me.profile.id)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Buscador falso + botón de filtros (`.hsearch .srow`).
class _SearchRow extends StatelessWidget {
  const _SearchRow({required this.hint, required this.onTap, required this.filters, required this.onFilters});
  final String hint;
  final VoidCallback onTap;
  final int filters;
  final VoidCallback onFilters;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: NexoColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: NexoColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: NexoColors.line),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  child: Row(children: [
                    const NexoIcon('search', size: 20, color: NexoColors.muted),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(hint,
                          overflow: TextOverflow.ellipsis, style: NexoText.body(14.5, color: NexoColors.muted)),
                    ),
                  ]),
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
}

class _GuestMore extends ConsumerWidget {
  const _GuestMore();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return NexoCard(
      margin: const EdgeInsets.fromLTRB(12, 14, 12, 0),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          const NexoIcon('user', size: 30, color: NexoColors.brand),
          const SizedBox(height: 8),
          Text('Esto es solo una probadita', style: NexoText.display(18, weight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Crea tu cuenta gratis para contactar, comparar, guardar y publicar lo que necesitas.',
              textAlign: TextAlign.center, style: NexoText.body(14, color: NexoColors.muted, height: 1.45)),
          const SizedBox(height: 14),
          NexoButton(
            label: 'Crear cuenta gratis',
            onPressed: () {
              ref.read(sessionProvider.notifier).leaveGuest();
              context.go(Routes.registerEmail);
            },
          ),
          const SizedBox(height: 8),
          NexoButton(
            label: 'Ya tengo cuenta · Iniciar sesión',
            variant: NexoButtonVariant.line,
            onPressed: () {
              ref.read(sessionProvider.notifier).leaveGuest();
              context.go(Routes.login);
            },
          ),
        ],
      ),
    );
  }
}
