import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/env.dart';
import '../core/auth/session_controller.dart';
import '../core/network/api_client.dart';
import 'fake/fake_nexo_api.dart';
import 'fake/fake_seed.dart';
import 'http_nexo_api.dart';
import 'models.dart';
import 'nexo_api.dart';

/// Modo de cada grupo según `API_MODE`, `LIVE` y `FAKE` (spec 045).
Map<ApiGroup, GroupMode> groupModes({String mode = Env.apiMode, String live = Env.live, String fake = Env.fake}) {
  Set<String> parse(String raw) =>
      raw.split(',').map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty).toSet();
  final base = switch (mode.trim().toLowerCase()) {
    'live' => GroupMode.live,
    'fake' => GroupMode.fake,
    _ => GroupMode.auto,
  };
  final l = parse(live), f = parse(fake);
  return {
    for (final g in ApiGroup.values)
      g: (l.contains('all') || l.contains(g.name))
          ? GroupMode.live
          : (f.contains('all') || f.contains(g.name))
              ? GroupMode.fake
              : base,
  };
}

/// Grupos que en este momento responden con datos de ejemplo.
class DemoGroups extends Notifier<Set<ApiGroup>> {
  @override
  Set<ApiGroup> build() => const {};
  void mark(ApiGroup g, bool demo) {
    if (demo == state.contains(g)) return;
    state = demo ? {...state, g} : ({...state}..remove(g));
  }
}

final demoGroupsProvider = NotifierProvider<DemoGroups, Set<ApiGroup>>(DemoGroups.new);

/// Avisos "del servidor" en modo de prueba (alguien se interesó, aceptó tu
/// pedido o te respondió). El shell los escucha para refrescar y avisar.
class ServerEvent {
  const ServerEvent(this.seq, this.message);
  final int seq;
  final String message;
}

class ServerEvents extends Notifier<ServerEvent> {
  @override
  ServerEvent build() => const ServerEvent(0, '');
  void push(String message) => state = ServerEvent(state.seq + 1, message);
}

final serverEventsProvider = NotifierProvider<ServerEvents, ServerEvent>(ServerEvents.new);

final apiProvider = Provider<NexoApi>((ref) {
  final fake = FakeNexoApi(FakeContext(
    name: () => ref.read(sessionProvider).name ?? '',
    mode: () => ref.read(sessionProvider).mode,
    notify: (m) => ref.read(serverEventsProvider.notifier).push(m),
    simulateCounterpart: !kReleaseMode || Env.apiMode == 'fake',
  ));
  final modes = groupModes();
  final api = HybridNexoApi(
    modes: modes,
    http: HttpNexoApi(ref.read(dioProvider)),
    fake: fake,
    // El asistente y el registro de push no muestran datos de ejemplo: no
    // cuentan para el aviso (spec 049/050).
    onDemo: (g, demo) {
      if (g == ApiGroup.asistente || g == ApiGroup.dispositivos) return;
      ref.read(demoGroupsProvider.notifier).mark(g, demo);
    },
  );
  // Los grupos forzados a la maqueta se anuncian desde el inicio.
  Future.microtask(() {
    for (final e in modes.entries) {
      if (e.value == GroupMode.fake) ref.read(demoGroupsProvider.notifier).mark(e.key, true);
    }
  });
  return api;
});

// --------------------------------------------------------------- estado app

/// Dónde busca la persona (7.13 "Tu ubicación" / selector de mapa).
class SearchLocation {
  const SearchLocation(this.point, this.zoneLabel, this.radiusKm);
  final GeoPoint point;
  final String zoneLabel;
  final int radiusKm;
}

class SearchLocationController extends Notifier<SearchLocation> {
  @override
  SearchLocation build() =>
      const SearchLocation(GeoPoint(Env.defaultLat, Env.defaultLng), Env.defaultZone, Env.defaultRadiusKm);

  Future<LocationResult?> set(GeoPoint p, int radiusKm, {String source = 'map'}) async {
    final s = ref.read(sessionProvider);
    LocationResult? r;
    if (s.isSignedIn) {
      r = await ref.read(apiProvider).setLocation(p, radiusKm: radiusKm, source: source);
    }
    state = SearchLocation(p, r?.zoneLabel ?? FakeNexoApi.zoneOf(p), radiusKm);
    return r;
  }
}

final searchLocationProvider =
    NotifierProvider<SearchLocationController, SearchLocation>(SearchLocationController.new);

/// Selección para comparar (máximo 2), barra `cmpBar`.
class CompareController extends Notifier<List<ProviderMini>> {
  @override
  List<ProviderMini> build() => const [];

  /// Devuelve false si ya había 2.
  bool toggle(ProviderMini p) {
    if (state.any((x) => x.id == p.id)) {
      state = state.where((x) => x.id != p.id).toList();
      return true;
    }
    if (state.length >= 2) return false;
    state = [...state, p];
    return true;
  }

  void clear() => state = const [];
}

final compareProvider = NotifierProvider<CompareController, List<ProviderMini>>(CompareController.new);

class SearchFiltersController extends Notifier<SearchFilters> {
  @override
  SearchFilters build() => const SearchFilters();
  void set(SearchFilters f) => state = f;
}

final searchFiltersProvider = NotifierProvider<SearchFiltersController, SearchFilters>(SearchFiltersController.new);

class OppFiltersController extends Notifier<OppFilters> {
  @override
  OppFilters build() => const OppFilters();
  void set(OppFilters f) => state = f;
}

final oppFiltersProvider = NotifierProvider<OppFiltersController, OppFilters>(OppFiltersController.new);

/// Intereses del solicitante (`S.user.interests`). Sin endpoint propio por
/// ahora: viven en el teléfono y ordenan el feed de Inicio.
class InterestsController extends Notifier<Set<String>> {
  @override
  Set<String> build() => <String>{};
  void toggle(String c) => state = state.contains(c) ? ({...state}..remove(c)) : {...state, c};
}

final interestsProvider = NotifierProvider<InterestsController, Set<String>>(InterestsController.new);

/// Rol con el que se piden pedidos y mensajes.
final roleProvider = Provider<String>((ref) => ref.watch(sessionProvider).isProviderMode ? 'provider' : 'client');

// ------------------------------------------------------------------ consultas

final feedProvider = FutureProvider<FeedPage>((ref) {
  final loc = ref.watch(searchLocationProvider);
  return ref.watch(apiProvider).feed(at: loc.point);
});

final myRequestsProvider = FutureProvider<List<ServiceRequest>>((ref) {
  if (!ref.watch(sessionProvider).isSignedIn) return Future.value(const []);
  return ref.watch(apiProvider).myRequests();
});

final opportunitiesProvider = FutureProvider<List<ServiceRequest>>((ref) {
  final f = ref.watch(oppFiltersProvider);
  return ref.watch(apiProvider).opportunities(f);
});

final ordersProvider = FutureProvider.family<OrdersPage, String>((ref, role) {
  if (!ref.watch(sessionProvider).isSignedIn) return Future.value(const OrdersPage([]));
  return ref.watch(apiProvider).orders(role: role);
});

final orderProvider = FutureProvider.autoDispose.family<Order, String>((ref, id) => ref.watch(apiProvider).order(id));

final myProviderProvider = FutureProvider<MyProvider?>((ref) {
  if (!ref.watch(sessionProvider).isSignedIn) return Future.value(null);
  return ref.watch(apiProvider).myProvider();
});

final accountProvider = FutureProvider<AccountScreen?>((ref) {
  if (!ref.watch(sessionProvider.select((s) => s.isSignedIn))) return Future.value(null);
  return ref.watch(apiProvider).accountScreen();
});

final inboxProvider = FutureProvider.family<(List<Conversation>, int), String>((ref, role) {
  if (!ref.watch(sessionProvider).isSignedIn) return Future.value((const <Conversation>[], 0));
  return ref.watch(apiProvider).conversations(role: role);
});

final savedProvider = FutureProvider.autoDispose<(List<SavedItem>, SavedCounts)>((ref) => ref.watch(apiProvider).saved());

final notificationsProvider = FutureProvider<(List<NotificationItem>, int)>((ref) {
  if (!ref.watch(sessionProvider).isSignedIn) return Future.value((const <NotificationItem>[], 0));
  return ref.watch(apiProvider).notifications();
});

final providerProfileProvider = FutureProvider.autoDispose.family<ProviderProfile, String>((ref, id) {
  final loc = ref.read(searchLocationProvider);
  return ref.watch(apiProvider).provider(id, at: loc.point);
});

final providerWorksProvider =
    FutureProvider.autoDispose.family<List<Work>, String>((ref, id) => ref.watch(apiProvider).providerWorks(id));

final reviewsProvider =
    FutureProvider.autoDispose.family<ReviewsPage, String>((ref, id) => ref.watch(apiProvider).reviews(id));

final interestedProvider = FutureProvider.autoDispose.family<InterestedPage, (String, String)>(
    (ref, a) => ref.watch(apiProvider).interested(a.$1, sort: a.$2));

final searchResultsProvider = FutureProvider.autoDispose<SearchResult>((ref) {
  final f = ref.watch(searchFiltersProvider);
  final loc = ref.watch(searchLocationProvider);
  return ref.watch(apiProvider).searchProviders(f, at: loc.point, radiusKm: loc.radiusKm);
});

final compareResultProvider = FutureProvider.autoDispose.family<CompareResult, String>((ref, ids) {
  final loc = ref.read(searchLocationProvider);
  return ref.watch(apiProvider).compare(ids.split(','), at: loc.point);
});

/// Refresca todo lo que depende de la actividad de la cuenta.
void refreshActivity(WidgetRef ref) {
  ref.invalidate(myRequestsProvider);
  ref.invalidate(opportunitiesProvider);
  ref.invalidate(ordersProvider);
  ref.invalidate(inboxProvider);
  ref.invalidate(notificationsProvider);
  ref.invalidate(accountProvider);
  ref.invalidate(feedProvider);
}

/// Info visual de una categoría (nombre, ícono y degradado del catálogo).
FCat catInfo(String slug) => fcat(slug);
List<FCat> get allCats => fakeCats;
