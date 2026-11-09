import 'dart:typed_data';

import '../core/auth/auth_tokens.dart';
import '../core/network/api_exception.dart';
import 'models.dart';

/// Grupos de endpoints (carpetas de `docs/endpoints`). Cada grupo se puede
/// conectar al backend real por separado con `--dart-define=LIVE=...`.
enum ApiGroup {
  cuenta,
  perfil,
  descubrimiento,
  trabajos,
  solicitudes,
  interes,
  pedidos,
  opiniones,
  mensajes,
  guardados,
  contacto,
  notificaciones,
  imagenes,

  /// IA generativa: borrador editable (EP-082, spec 049).
  asistente,

  /// Teléfonos registrados para push (spec 050).
  dispositivos,
}

/// Borrador que propone la IA generativa. Nunca se publica solo: la persona
/// lo revisa, lo edita y publica con el botón de siempre (spec 049).
class AssistDraft {
  const AssistDraft({required this.text, this.title, this.modelVersion = ''});
  final String text;
  final String? title;
  final String modelVersion;
}

/// Datos para crear el perfil profesional (`POST /v1/discovery/providers`).
class ProviderDraft {
  ProviderDraft();
  String kind = 'trade'; // trade | business
  String name = '';
  String owner = '';
  String sector = 'servicios';
  String activity = '';
  String bio = '';
  int? experience; // años (aprox.) a partir del rango elegido
  String crew = 'alone'; // alone | withHelpers | team
  int? teamSize; // solo business con crew = team
  List<String> trades = []; // oficios declarados (trade)
  String attention = 'home'; // home | shop | both
  List<String> categories = [];
  List<String> specialties = [];
  GeoPoint? location;
  String zoneLabel = 'Centro';
  int radiusKm = 5;
  String? photoUploadId;
  String? coverUploadId;
  bool acceptedRules = false;
}

/// Una foto elegida en el teléfono, lista para subir.
class PickedImage {
  const PickedImage({required this.path, required this.bytes, required this.contentType, this.width, this.height});
  final String path;
  final Uint8List bytes;
  final String contentType;
  final int? width;
  final int? height;
}

/// Un método por endpoint, con los nombres de campo de los contratos.
/// `HttpNexoApi` llama al backend; `FakeNexoApi` responde con los datos de la
/// maqueta para poder usar toda la app mientras se publican los endpoints.
abstract class NexoApi {
  // ---- 02 cuenta ----
  Future<AccountScreen> accountScreen();
  Future<void> updateMe({String? name, String? photoUploadId});

  /// Devuelve tokens nuevos cuando el backend los emite (claim `mode`).
  Future<AuthTokens?> switchMode(String mode);
  Future<String> requestDeletion({required String password, String? reason});
  Future<void> cancelDeletion();
  Future<String> addPhone(String phone);
  Future<void> confirmPhone(String code);

  // ---- 03 perfil prestador ----
  Future<ProviderProfile> provider(String id, {GeoPoint? at});
  Future<MyProvider?> myProvider();
  Future<String> createProvider(ProviderDraft d, {required String idempotencyKey});
  Future<void> patchProvider(String section, Json body);
  Future<CompareResult> compare(List<String> ids, {GeoPoint? at});

  // ---- 04 descubrimiento ----
  Future<List<ServiceCategory>> categories();
  Future<FeedPage> feed({required GeoPoint at, String? cursor});
  Future<MapNearby> mapNearby({required GeoPoint at, required int radiusKm, required String kind});
  Future<SearchResult> searchProviders(SearchFilters f, {required GeoPoint at, required int radiusKm});
  Future<List<Suggestion>> suggest(String q, {required GeoPoint at});
  Future<LocationResult> setLocation(GeoPoint p, {required int radiusKm, String source = 'map'});

  // ---- 05 trabajos ----
  Future<Work> createWork({
    required String category,
    required String title,
    required String text,
    String? tag,
    GeoPoint? location,
    List<String> imageUploadIds = const [],
  });
  Future<void> deleteWork(String id);
  Future<Work> recommend(Work w, bool on);
  Future<List<Work>> providerWorks(String providerId);

  // ---- 06 solicitudes ----
  Future<ServiceRequest> createRequest({
    required String category,
    required String title,
    required String description,
    required String urgency,
    required String contact,
    required GeoPoint location,
    String? imageUploadId,
    required String idempotencyKey,
  });
  Future<List<ServiceRequest>> myRequests();
  Future<List<ServiceRequest>> opportunities(OppFilters f);
  Future<void> closeRequest(String id, {required String outcome, String? pickedProviderId});

  // ---- 07 interés ----
  Future<void> setInterest(String requestId, bool on, {String? note});
  Future<InterestedPage> interested(String requestId, {String sort = 'rate'});

  // ---- 08 pedidos ----
  Future<Order> createOrder({
    required String providerId,
    String? requestId,
    required String category,
    required String description,
    required String attention,
    String? address,
    String? addressNote,
    GeoPoint? location,
    required String idempotencyKey,
  });
  Future<OrdersPage> orders({required String role, String status = 'all'});
  Future<Order> order(String id);
  Future<Order> acceptOrder(Order o, {int? amountCents, String? includes});
  Future<Order> rejectOrder(Order o, {required String reason, String? note});
  Future<Order> cancelOrder(Order o, {required String reason});
  Future<Order> resolveOrder(Order o, {int? finalPriceCents, String? note});
  Future<Order> updateAddress(Order o, {required String address, String? addressNote, GeoPoint? location});

  // ---- 09 opiniones ----
  Future<void> review({required String orderId, required int stars, required String text, required bool recommend});
  Future<ReviewsPage> reviews(String providerId);

  // ---- 10 mensajes ----
  Future<(List<Conversation>, int)> conversations({required String role, String filter = 'all'});
  Future<String> openConversation({String? providerId, String? requestId});
  Future<ChatThread> messages(String conversationId, {String? before});
  Future<Message> sendMessage(String conversationId, {String? text, String? imageUploadId});
  Future<void> markRead(String conversationId, String upToMessageId);
  Future<bool> block(String conversationId, bool blocked, {bool alsoReport = false});

  // ---- 11 guardados ----
  Future<(List<SavedItem>, SavedCounts)> saved({String? kind});
  Future<SavedCounts> setSaved(String kind, String id, bool on);

  // ---- 12 contacto y reportes ----
  Future<PhoneReveal> revealPhone({required String targetId, required String targetType, required String context});
  Future<String> report(
      {required String targetType, required String targetId, required String category, required String reason});

  // ---- 13 notificaciones ----
  Future<(List<NotificationItem>, int)> notifications({String filter = 'all'});
  Future<void> markNotificationsRead(List<String> ids);

  // ---- 14 imágenes ----
  /// Sube la foto y devuelve el `uploadId` para mandarlo en el alta.
  Future<String> upload(PickedImage img, {required String purpose});

  // ---- 15 asistente (IA generativa) ----
  /// `kind`: `request` | `work`. [userText] ya va sin datos de contacto
  /// (ver `redactForAssist`).
  Future<AssistDraft> assistDraft({
    required String kind,
    required String category,
    required String userText,
    int lengthLimit = 600,
  });

  // ---- 16 dispositivos (push) ----
  /// Registra el token FCM; devuelve el `deviceId`.
  Future<String> registerDevice({required String fcmToken, required String appVersion});
  Future<void> removeDevice(String deviceId);
}

/// Cómo se atiende cada grupo de endpoints.
enum GroupMode {
  /// Siempre el backend; sus errores se muestran.
  live,

  /// Siempre los datos de la maqueta.
  fake,

  /// Primero el backend; si el endpoint aún no existe o no hay señal, se
  /// responde con los datos de la maqueta sin mostrar error (spec 045).
  auto,
}

/// Falla que significa "el endpoint todavía no está disponible", no un error
/// de negocio: sin red, tiempo agotado, ruta inexistente (404 sin código de
/// Nexo), método no permitido, 5xx sin código o respuesta que no es JSON.
bool isUnavailable(Object e) {
  // Respuesta 200 con forma inesperada (contrato aún en construcción).
  if (e is TypeError || e is FormatException) return true;
  if (e is! ApiException) return false;
  if (e.isNetwork || e.code == 'client.unexpected_response') return true;
  final s = e.status;
  if (s == null) return false;
  final noNexoCode = e.code.startsWith('http_');
  if (s == 404 || s == 405 || s == 501) return noNexoCode;
  if (s >= 500) return noNexoCode;
  return false;
}

/// Aviso de qué grupos están respondiendo con datos de ejemplo.
typedef DemoListener = void Function(ApiGroup group, bool usingDemo);

/// Reparte cada llamada entre el backend real y los datos de la maqueta.
///
/// En modo `auto` (el de fábrica) intenta el backend; si el grupo no está
/// disponible usa la maqueta y deja de intentarlo durante [cooldown] para no
/// esperar un tiempo de espera en cada pantalla. Los errores de negocio
/// (409, 412, 403, 400 con código de Nexo…) siempre llegan a la pantalla.
class HybridNexoApi implements NexoApi {
  HybridNexoApi({
    required this.modes,
    required this.http,
    required this.fake,
    this.cooldown = const Duration(seconds: 60),
    this.onDemo,
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  final Map<ApiGroup, GroupMode> modes;
  final NexoApi http;
  final NexoApi fake;
  final Duration cooldown;
  final DemoListener? onDemo;
  final DateTime Function() _now;
  final Map<ApiGroup, DateTime> _downUntil = {};

  GroupMode modeOf(ApiGroup g) => modes[g] ?? GroupMode.auto;

  /// true si el grupo está respondiendo con datos de ejemplo ahora mismo.
  bool usingDemo(ApiGroup g) {
    final m = modeOf(g);
    if (m == GroupMode.fake) return true;
    if (m == GroupMode.live) return false;
    final until = _downUntil[g];
    return until != null && _now().isBefore(until);
  }

  /// Operaciones que siempre intentan el backend aunque su grupo esté en
  /// espera: sin señal se guardan en la cola local (spec 051) en vez de
  /// "publicarse" solo en la maqueta.
  static const alwaysTryLive = {'createRequest'};

  Future<T> _run<T>(ApiGroup g, String op, Future<T> Function(NexoApi api) call) async {
    final m = modeOf(g);
    if (m == GroupMode.live) return call(http);
    if (m == GroupMode.fake || (usingDemo(g) && !alwaysTryLive.contains(op))) return call(fake);
    try {
      final r = await call(http);
      if (_downUntil.remove(g) != null) onDemo?.call(g, false);
      return r;
    } catch (e) {
      if (!isUnavailable(e)) rethrow;
      final until = _now().add(cooldown);
      // Sin señal o servidor inalcanzable afecta a todos los grupos: así no
      // se espera el tiempo de conexión una vez por pantalla.
      final all = e is ApiException && e.isNetwork;
      for (final x in all ? ApiGroup.values : [g]) {
        if (modeOf(x) != GroupMode.auto) continue;
        final wasUp = !usingDemo(x);
        _downUntil[x] = until;
        if (wasUp) onDemo?.call(x, true);
      }
      return call(fake);
    }
  }

  @override
  Future<AccountScreen> accountScreen() => _run(ApiGroup.cuenta, 'accountScreen', (a) => a.accountScreen());
  @override
  Future<void> updateMe({String? name, String? photoUploadId}) =>
      _run(ApiGroup.cuenta, 'updateMe', (a) => a.updateMe(name: name, photoUploadId: photoUploadId));
  @override
  Future<AuthTokens?> switchMode(String mode) => _run(ApiGroup.cuenta, 'switchMode', (a) => a.switchMode(mode));
  @override
  Future<String> requestDeletion({required String password, String? reason}) =>
      _run(ApiGroup.cuenta, 'requestDeletion', (a) => a.requestDeletion(password: password, reason: reason));
  @override
  Future<void> cancelDeletion() => _run(ApiGroup.cuenta, 'cancelDeletion', (a) => a.cancelDeletion());
  @override
  Future<String> addPhone(String phone) => _run(ApiGroup.cuenta, 'addPhone', (a) => a.addPhone(phone));
  @override
  Future<void> confirmPhone(String code) => _run(ApiGroup.cuenta, 'confirmPhone', (a) => a.confirmPhone(code));

  @override
  Future<ProviderProfile> provider(String id, {GeoPoint? at}) =>
      _run(ApiGroup.perfil, 'provider', (a) => a.provider(id, at: at));
  @override
  Future<MyProvider?> myProvider() => _run(ApiGroup.perfil, 'myProvider', (a) => a.myProvider());
  @override
  Future<String> createProvider(ProviderDraft d, {required String idempotencyKey}) =>
      _run(ApiGroup.perfil, 'createProvider', (a) => a.createProvider(d, idempotencyKey: idempotencyKey));
  @override
  Future<void> patchProvider(String section, Json body) =>
      _run(ApiGroup.perfil, 'patchProvider', (a) => a.patchProvider(section, body));
  @override
  Future<CompareResult> compare(List<String> ids, {GeoPoint? at}) =>
      _run(ApiGroup.perfil, 'compare', (a) => a.compare(ids, at: at));

  @override
  Future<List<ServiceCategory>> categories() => _run(ApiGroup.descubrimiento, 'categories', (a) => a.categories());
  @override
  Future<FeedPage> feed({required GeoPoint at, String? cursor}) =>
      _run(ApiGroup.descubrimiento, 'feed', (a) => a.feed(at: at, cursor: cursor));
  @override
  Future<MapNearby> mapNearby({required GeoPoint at, required int radiusKm, required String kind}) =>
      _run(ApiGroup.descubrimiento, 'mapNearby', (a) => a.mapNearby(at: at, radiusKm: radiusKm, kind: kind));
  @override
  Future<SearchResult> searchProviders(SearchFilters f, {required GeoPoint at, required int radiusKm}) =>
      _run(ApiGroup.descubrimiento, 'searchProviders', (a) => a.searchProviders(f, at: at, radiusKm: radiusKm));
  @override
  Future<List<Suggestion>> suggest(String q, {required GeoPoint at}) =>
      _run(ApiGroup.descubrimiento, 'suggest', (a) => a.suggest(q, at: at));
  @override
  Future<LocationResult> setLocation(GeoPoint p, {required int radiusKm, String source = 'map'}) =>
      _run(ApiGroup.descubrimiento, 'setLocation', (a) => a.setLocation(p, radiusKm: radiusKm, source: source));

  @override
  Future<Work> createWork({
    required String category,
    required String title,
    required String text,
    String? tag,
    GeoPoint? location,
    List<String> imageUploadIds = const [],
  }) =>
      _run(
          ApiGroup.trabajos,
          'createWork',
          (a) => a.createWork(
              category: category,
              title: title,
              text: text,
              tag: tag,
              location: location,
              imageUploadIds: imageUploadIds));
  @override
  Future<void> deleteWork(String id) => _run(ApiGroup.trabajos, 'deleteWork', (a) => a.deleteWork(id));
  @override
  Future<Work> recommend(Work w, bool on) => _run(ApiGroup.trabajos, 'recommend', (a) => a.recommend(w, on));
  @override
  Future<List<Work>> providerWorks(String providerId) =>
      _run(ApiGroup.trabajos, 'providerWorks', (a) => a.providerWorks(providerId));

  @override
  Future<ServiceRequest> createRequest({
    required String category,
    required String title,
    required String description,
    required String urgency,
    required String contact,
    required GeoPoint location,
    String? imageUploadId,
    required String idempotencyKey,
  }) =>
      _run(
          ApiGroup.solicitudes,
          'createRequest',
          (a) => a.createRequest(
                category: category,
                title: title,
                description: description,
                urgency: urgency,
                contact: contact,
                location: location,
                imageUploadId: imageUploadId,
                idempotencyKey: idempotencyKey,
              ));
  @override
  Future<List<ServiceRequest>> myRequests() => _run(ApiGroup.solicitudes, 'myRequests', (a) => a.myRequests());
  @override
  Future<List<ServiceRequest>> opportunities(OppFilters f) =>
      _run(ApiGroup.solicitudes, 'opportunities', (a) => a.opportunities(f));
  @override
  Future<void> closeRequest(String id, {required String outcome, String? pickedProviderId}) => _run(
      ApiGroup.solicitudes,
      'closeRequest',
      (a) => a.closeRequest(id, outcome: outcome, pickedProviderId: pickedProviderId));

  @override
  Future<void> setInterest(String requestId, bool on, {String? note}) =>
      _run(ApiGroup.interes, 'setInterest', (a) => a.setInterest(requestId, on, note: note));
  @override
  Future<InterestedPage> interested(String requestId, {String sort = 'rate'}) =>
      _run(ApiGroup.interes, 'interested', (a) => a.interested(requestId, sort: sort));

  @override
  Future<Order> createOrder({
    required String providerId,
    String? requestId,
    required String category,
    required String description,
    required String attention,
    String? address,
    String? addressNote,
    GeoPoint? location,
    required String idempotencyKey,
  }) =>
      _run(
          ApiGroup.pedidos,
          'createOrder',
          (a) => a.createOrder(
                providerId: providerId,
                requestId: requestId,
                category: category,
                description: description,
                attention: attention,
                address: address,
                addressNote: addressNote,
                location: location,
                idempotencyKey: idempotencyKey,
              ));
  @override
  Future<OrdersPage> orders({required String role, String status = 'all'}) =>
      _run(ApiGroup.pedidos, 'orders', (a) => a.orders(role: role, status: status));
  @override
  Future<Order> order(String id) => _run(ApiGroup.pedidos, 'order', (a) => a.order(id));
  @override
  Future<Order> acceptOrder(Order o, {int? amountCents, String? includes}) =>
      _run(ApiGroup.pedidos, 'acceptOrder', (a) => a.acceptOrder(o, amountCents: amountCents, includes: includes));
  @override
  Future<Order> rejectOrder(Order o, {required String reason, String? note}) =>
      _run(ApiGroup.pedidos, 'rejectOrder', (a) => a.rejectOrder(o, reason: reason, note: note));
  @override
  Future<Order> cancelOrder(Order o, {required String reason}) =>
      _run(ApiGroup.pedidos, 'cancelOrder', (a) => a.cancelOrder(o, reason: reason));
  @override
  Future<Order> resolveOrder(Order o, {int? finalPriceCents, String? note}) =>
      _run(ApiGroup.pedidos, 'resolveOrder', (a) => a.resolveOrder(o, finalPriceCents: finalPriceCents, note: note));
  @override
  Future<Order> updateAddress(Order o, {required String address, String? addressNote, GeoPoint? location}) => _run(
      ApiGroup.pedidos,
      'updateAddress',
      (a) => a.updateAddress(o, address: address, addressNote: addressNote, location: location));

  @override
  Future<void> review({required String orderId, required int stars, required String text, required bool recommend}) =>
      _run(ApiGroup.opiniones, 'review',
          (a) => a.review(orderId: orderId, stars: stars, text: text, recommend: recommend));
  @override
  Future<ReviewsPage> reviews(String providerId) => _run(ApiGroup.opiniones, 'reviews', (a) => a.reviews(providerId));

  @override
  Future<(List<Conversation>, int)> conversations({required String role, String filter = 'all'}) =>
      _run(ApiGroup.mensajes, 'conversations', (a) => a.conversations(role: role, filter: filter));
  @override
  Future<String> openConversation({String? providerId, String? requestId}) => _run(
      ApiGroup.mensajes, 'openConversation', (a) => a.openConversation(providerId: providerId, requestId: requestId));
  @override
  Future<ChatThread> messages(String conversationId, {String? before}) =>
      _run(ApiGroup.mensajes, 'messages', (a) => a.messages(conversationId, before: before));
  @override
  Future<Message> sendMessage(String conversationId, {String? text, String? imageUploadId}) => _run(
      ApiGroup.mensajes, 'sendMessage', (a) => a.sendMessage(conversationId, text: text, imageUploadId: imageUploadId));
  @override
  Future<void> markRead(String conversationId, String upToMessageId) =>
      _run(ApiGroup.mensajes, 'markRead', (a) => a.markRead(conversationId, upToMessageId));
  @override
  Future<bool> block(String conversationId, bool blocked, {bool alsoReport = false}) =>
      _run(ApiGroup.mensajes, 'block', (a) => a.block(conversationId, blocked, alsoReport: alsoReport));

  @override
  Future<(List<SavedItem>, SavedCounts)> saved({String? kind}) =>
      _run(ApiGroup.guardados, 'saved', (a) => a.saved(kind: kind));
  @override
  Future<SavedCounts> setSaved(String kind, String id, bool on) =>
      _run(ApiGroup.guardados, 'setSaved', (a) => a.setSaved(kind, id, on));

  @override
  Future<PhoneReveal> revealPhone({required String targetId, required String targetType, required String context}) =>
      _run(ApiGroup.contacto, 'revealPhone',
          (a) => a.revealPhone(targetId: targetId, targetType: targetType, context: context));
  @override
  Future<String> report(
          {required String targetType, required String targetId, required String category, required String reason}) =>
      _run(ApiGroup.contacto, 'report',
          (a) => a.report(targetType: targetType, targetId: targetId, category: category, reason: reason));

  @override
  Future<(List<NotificationItem>, int)> notifications({String filter = 'all'}) =>
      _run(ApiGroup.notificaciones, 'notifications', (a) => a.notifications(filter: filter));
  @override
  Future<void> markNotificationsRead(List<String> ids) =>
      _run(ApiGroup.notificaciones, 'markNotificationsRead', (a) => a.markNotificationsRead(ids));

  @override
  Future<String> upload(PickedImage img, {required String purpose}) =>
      _run(ApiGroup.imagenes, 'upload', (a) => a.upload(img, purpose: purpose));

  @override
  Future<AssistDraft> assistDraft({
    required String kind,
    required String category,
    required String userText,
    int lengthLimit = 600,
  }) =>
      _run(ApiGroup.asistente, 'assistDraft',
          (a) => a.assistDraft(kind: kind, category: category, userText: userText, lengthLimit: lengthLimit));

  @override
  Future<String> registerDevice({required String fcmToken, required String appVersion}) => _run(
      ApiGroup.dispositivos, 'registerDevice', (a) => a.registerDevice(fcmToken: fcmToken, appVersion: appVersion));
  @override
  Future<void> removeDevice(String deviceId) =>
      _run(ApiGroup.dispositivos, 'removeDevice', (a) => a.removeDevice(deviceId));
}
