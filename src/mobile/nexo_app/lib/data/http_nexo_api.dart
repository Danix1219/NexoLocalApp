import 'dart:convert';
import 'dart:typed_data';
import '../core/chat/encrypted_chat_transport.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kReleaseMode, kDebugMode, debugPrint;
import 'package:uuid/uuid.dart';

import '../app/env.dart';
import '../core/auth/auth_tokens.dart';
import '../core/network/api_client.dart';
import '../core/network/api_exception.dart';
import 'models.dart';
import 'provider_contract.dart';
import 'nexo_api.dart';

/// Implementación contra el backend (.NET en Azure). Rutas y campos tal cual
/// `docs/endpoints`. Todas las llamadas llevan el Bearer (el interceptor lo
/// renueva solo).
class HttpNexoApi implements NexoApi {
  @override
  Future<List<GeoPlace>> searchPlaces(String query, {GeoPoint? at}) async {
    final data = await _publicPlaces('/v1/discovery/places/search', {'q': query, ..._at(at)});
    return (data['items'] as List).map((p) => GeoPlace.fromJson(Map<String, dynamic>.from(p as Map))).toList();
  }

  @override
  Future<GeoPlace?> reversePlace(GeoPoint point) async {
    final data = await _publicPlaces('/v1/discovery/places/reverse', _at(point));
    return data['place'] == null ? null : GeoPlace.fromJson(Map<String, dynamic>.from(data['place'] as Map));
  }

  @override
  Future<LocationResult?> getLocation() => _call(() async {
    final response = await _dio.get('/v1/discovery/me/location', options: _auth());
    if (response.data == null || response.data == '') return null;
    return LocationResult.fromJson(Map<String, dynamic>.from(response.data as Map));
  });

  Future<Json> _publicPlaces(String path, Map<String, dynamic> query) => _call(() async {
    final response = await _dio.get<dynamic>(
      path,
      queryParameters: query,
      options: Options(extra: const {kAuth: false}),
    );
    if (response.data is! Map) throw const ApiException(code: 'client.unexpected_response');
    return Json.from(response.data as Map);
  });

  HttpNexoApi(this._dio, {Dio? uploadDio, this.refreshToken, this.encryptedChat}) : _uploadDio = uploadDio ?? Dio();

  final Dio _dio;
  final Future<EncryptedChatTransport> Function()? encryptedChat;
  final Map<String, String> _privatePeers = {};
  final Set<String> _privateConversations = {};
  @override
  Future<void> retryPrivateMessage(String id) async {
    final peer = _privatePeers[id];
    if (peer == null || encryptedChat == null) throw StateError('Abre primero el chat privado');
    await (await encryptedChat!()).retryPending(id, peer);
  }

  @override
  Future<void> enablePrivateChat(String conversationId) async {
    final factory = encryptedChat;
    if (factory == null) throw StateError('Esta compilaci\u00f3n no tiene chat privado');
    await (await factory()).enable(conversationId);
    _privateConversations.add(conversationId);
  }

  @override
  Future<Message> sendPrivateAttachment(
    String conversationId,
    Uint8List bytes,
    String type, {
    String? caption,
    String? clientMessageId,
  }) async {
    if (caption != null && caption.length > 1000) throw StateError('Texto demasiado largo');
    final peer = _privatePeers[conversationId];
    if (peer == null || encryptedChat == null) throw StateError('Abre primero la conversacion privada');
    final transport = await encryptedChat!();
    final pending = await transport.crypto.vault.transaction((state) async => state['pending:$conversationId']);
    if (pending != null) {
      final saved = jsonDecode(pending) as Map<String, dynamic>;
      final content = jsonDecode(saved['content'] as String) as Map<String, dynamic>;
      if (clientMessageId == null || content['clientId'] != clientMessageId) {
        throw StateError('Reintenta primero el mensaje pendiente');
      }
      final id = await transport.retryPending(conversationId, peer);
      return Message(
        id: id,
        kind: '${content['kind']}',
        text: content['text'] as String? ?? '',
        mine: true,
        privateAttachment: Map<String, dynamic>.from(content['file'] as Map),
      );
    }
    final file = await transport.uploadAttachment(conversationId, bytes, type);
    final kind = type.startsWith('image/') ? 'image' : 'audio';
    if (type == 'audio/wav' && bytes.length >= 44) file['durationMs'] = ((bytes.length - 44) * 1000 / 32000).round();
    final id = await transport.send(conversationId, peer, {
      'kind': kind,
      'file': file,
      if (clientMessageId != null) 'clientId': clientMessageId,
      if (caption != null && caption.trim().isNotEmpty) 'text': caption.trim(),
    });
    return Message(id: id, kind: kind, text: caption?.trim() ?? '', mine: true, privateAttachment: file);
  }

  final Future<String> Function()? refreshToken;

  /// Cliente sin interceptores ni baseUrl para la URL firmada del
  /// almacenamiento: nunca debe llevar el Bearer de Nexo (spec 046).
  final Dio _uploadDio;
  static const _uuid = Uuid();

  Options _auth({String? idem, int? ifMatch}) => Options(
    extra: const {kAuth: true},
    headers: {if (idem != null) 'Idempotency-Key': idem, if (ifMatch != null) 'If-Match': '"$ifMatch"'},
  );

  Future<T> _call<T>(Future<T> Function() f) async {
    try {
      return await f();
    } on DioException catch (e) {
      // La cola sin conexión (spec 051) ya trae su propio error de Nexo.
      if (e.error is ApiException) throw e.error as ApiException;
      throw ApiException.fromDio(e);
    } on ApiException {
      rethrow;
    } catch (_) {
      throw const ApiException(code: 'client.unexpected_response');
    }
  }

  Future<Json> _get(String path, [Map<String, dynamic>? q]) => _call(() async {
    q?.removeWhere((_, v) => v == null || v == '');
    final r = await _dio.get<dynamic>(path, queryParameters: q, options: _auth());
    // Una lectura de Nexo siempre es un objeto JSON; HTML o texto significa
    // que esa ruta todavía no es la del backend (spec 045).
    if (r.data is! Map) throw const ApiException(code: 'client.unexpected_response');
    return Json.from(r.data as Map);
  });

  Future<Json> _send(String method, String path, {Object? body, String? idem, int? ifMatch}) => _call(() async {
    final o = _auth(idem: idem, ifMatch: ifMatch)..method = method;
    final r = await _dio.request<dynamic>(path, data: body, options: o);
    if (r.data is Map) return Json.from(r.data as Map);
    // 201/204 sin cuerpo es válido; texto o HTML no lo es.
    if (r.data == null || (r.data is String && (r.data as String).trim().isEmpty)) return <String, dynamic>{};
    throw const ApiException(code: 'client.unexpected_response');
  });

  Map<String, dynamic> _at(GeoPoint? p) => p == null ? {} : {'lat': p.lat, 'lng': p.lng};

  List<T> _items<T>(Json j, T Function(Json) f) =>
      (j['items'] is List ? j['items'] as List : const []).whereType<Map>().map((e) => f(Json.from(e))).toList();

  // ---------------- cuenta ----------------
  @override
  Future<AccountScreen> accountScreen() async => AccountScreen.fromJson(await _get('/v1/identity/me'));

  @override
  Future<String> shareProfile() async {
    final result = await _send('POST', '/v1/identity/me/profile-share');
    final id = result['shareId']?.toString();
    if (id == null || !RegExp(r'^[a-fA-F0-9-]{36}$').hasMatch(id)) {
      throw const ApiException(code: 'client.unexpected_response');
    }
    return 'nexolocal://profile/$id';
  }

  @override
  Future<Json> sharedProfile(String id) => _get('/v1/identity/profiles/$id');

  @override
  Future<void> updateMe({String? name, String? photoUploadId}) => _send(
    'PATCH',
    '/v1/identity/me',
    body: {if (name != null) 'name': name, if (photoUploadId != null) 'photoUploadId': photoUploadId},
  );

  @override
  Future<AuthTokens?> switchMode(String mode) async => _switchMode(mode);

  Future<AuthTokens?> _switchMode(String mode) async {
    final result = await _send('POST', '/v1/identity/me/mode', body: {'mode': mode});
    if (result['tokenRefreshRequired'] != true) return AuthTokens.tryFromAccount(result);
    final response = await _dio.post<Map<String, dynamic>>(
      '/connect/token',
      data: {'grant_type': 'refresh_token', 'refresh_token': await refreshToken!()},
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    return AuthTokens.fromOAuth(response.data!);
  }

  @override
  Future<String> requestDeletion({required String password, String? reason}) async {
    final j = await _send('POST', '/v1/identity/me/deletion', body: {'password': password, 'reason': reason});
    final d = j['daysRemaining'];
    return d == null ? 'Tu cuenta se eliminará en 30 días.' : 'Tu cuenta se eliminará en $d días.';
  }

  @override
  Future<void> cancelDeletion() => _send('DELETE', '/v1/identity/me/deletion');

  @override
  Future<String> addPhone(String phone) async =>
      '${(await _send('POST', '/v1/identity/me/phone', body: {'phone': phone}))['phone'] ?? phone}';

  @override
  Future<void> confirmPhone(String code) async => throw const ApiException(code: 'phone.verification_retired');

  // ---------------- perfil prestador ----------------
  @override
  Future<ProviderProfile> provider(String id, {GeoPoint? at}) async =>
      ProviderProfile.fromJson(await _get('/v1/discovery/providers/$id', _at(at)));

  @override
  Future<MyProvider?> myProvider() async {
    try {
      return MyProvider.fromJson(await _get('/v1/discovery/providers/me'));
    } on ApiException catch (e) {
      if (e.status == 404 && e.code == 'provider.not_found') return null;
      rethrow;
    }
  }

  @override
  Future<String> createProvider(ProviderDraft d, {required String idempotencyKey}) async {
    final j = await _send(
      'POST',
      '/v1/discovery/providers',
      idem: idempotencyKey,
      body: {
        'kind': d.kind,
        'name': d.name,
        if (d.kind == 'business') 'owner': d.owner,
        if (d.kind == 'business') 'sector': d.sector,
        if (d.kind == 'business') 'activity': d.activity,
        if (d.bio.isNotEmpty) 'bio': d.bio,
        'experience': d.experience ?? 0,
        'crew': d.crew,
        if (d.kind == 'business' && d.crew == 'team' && d.teamSize != null) 'teamSize': d.teamSize,
        if (d.kind == 'trade') 'trades': d.trades,
        'attention': d.kind == 'trade' ? 'home' : d.attention,
        'categories': d.categories,
        'specialties': providerSpecialtySlugs(d.categories, d.specialties),
        'location': d.location?.toJson(),
        'radiusKm': d.attention == 'shop' ? 0 : d.radiusKm,
        'photoUploadId': d.photoUploadId,
        'coverUploadId': d.coverUploadId,
        'acceptedRules': d.acceptedRules,
      },
    );
    final id = j['providerId'];
    if (id is! String || id.isEmpty) throw const ApiException(code: 'client.unexpected_response');
    return id;
  }

  @override
  Future<void> patchProvider(String section, Json body) async {
    await _send('PATCH', '/v1/discovery/providers/me/$section', body: body);
  }

  @override
  Future<CompareResult> compare(List<String> ids, {GeoPoint? at}) async =>
      CompareResult.fromJson(await _get('/v1/discovery/providers/compare', {'ids': ids.join(','), ..._at(at)}));

  // ---------------- descubrimiento ----------------
  @override
  Future<List<ServiceCategory>> categories() async => _call(() async {
    final j = await _get('/v1/discovery/categories');
    return (j['categories'] as List).map((v) => ServiceCategory.fromJson(Json.from(v as Map))).toList();
  });

  @override
  Future<FeedPage> feed({required GeoPoint at, String? cursor}) async {
    final j = await _get('/v1/discovery/feed', {..._at(at), 'cursor': cursor, 'limit': 20});
    return FeedPage(
      zoneLabel: '${j['zoneLabel'] ?? ''}',
      guest: j['guest'] == true,
      page: CursorPage(
        _items(j, (w) => Work.fromJson(w)),
        nextCursor: j['nextCursor']?.toString(),
        hasMore: j['hasMore'] == true,
      ),
    );
  }

  @override
  Future<MapNearby> mapNearby({required GeoPoint at, required int radiusKm, required String kind}) async {
    final j = await _get('/v1/discovery/map/nearby', {..._at(at), 'radiusKm': radiusKm, 'kind': kind});
    final pts = (j['points'] is List ? j['points'] as List : const [])
        .whereType<Map>()
        .map((e) => MapPoint.fromJson(Json.from(e)))
        .toList();
    final s = j['summary'];
    return MapNearby(points: pts, summary: s is Map ? '${s['text'] ?? ''}' : '${s ?? ''}');
  }

  @override
  Future<SearchResult> searchProviders(SearchFilters f, {required GeoPoint at, required int radiusKm}) async {
    final j = await _get('/v1/discovery/search/providers', {
      'q': f.q.trim(),
      'cat': f.cat,
      ..._at(at),
      'radiusKm': radiusKm,
      if (f.open) 'open': true,
      if (f.free) 'free': true,
      if (f.prices) 'prices': true,
      if (f.urgent) 'urgent': true,
      'attention': f.attention,
      'sort': f.sort,
      if (f.expanded) 'expanded': true,
      'limit': 30,
    });
    return SearchResult(
      items: _items(j, ProviderProfile.fromJson),
      total: (j['total'] as num?)?.toInt() ?? 0,
      outOfZone: j['outOfZone'] == true,
      notice: j['notice'] is Map ? '${(j['notice'] as Map)['text'] ?? ''}' : j['notice']?.toString(),
      interpretedLabel: j['interpreted'] is Map ? (j['interpreted'] as Map)['label']?.toString() : null,
    );
  }

  @override
  Future<List<Suggestion>> suggest(String q, {required GeoPoint at}) async {
    final j = await _get('/v1/discovery/search/suggest', {'q': q, ..._at(at), 'limit': 8});
    return (j['suggestions'] is List ? j['suggestions'] as List : const [])
        .whereType<Map>()
        .map((s) => Suggestion('${s['kind'] ?? ''}', '${s['slug'] ?? ''}', '${s['label'] ?? ''}'))
        .toList();
  }

  @override
  Future<LocationResult> setLocation(GeoPoint p, {required int radiusKm, String source = 'map'}) async {
    final j = await _send(
      'PUT',
      '/v1/discovery/me/location',
      body: {'lat': p.lat, 'lng': p.lng, 'radiusKm': radiusKm, 'source': source},
    );
    final s = j['summary'];
    return LocationResult(
      point: p,
      zoneLabel: '${j['zoneLabel'] ?? 'Tu zona'}',
      radiusKm: (j['radiusKm'] as num?)?.toInt() ?? radiusKm,
      summary: s is Map ? '${s['text'] ?? ''}' : '${s ?? ''}',
    );
  }

  // ---------------- trabajos ----------------
  @override
  Future<Work> createWork({
    required String category,
    required String title,
    required String text,
    String? tag,
    GeoPoint? location,
    List<String> imageUploadIds = const [],
    String? idempotencyKey,
  }) async => Work.fromJson(
    await _send(
      'POST',
      '/v1/discovery/works',
      idem: idempotencyKey ?? _uuid.v4(),
      body: {
        'category': category,
        'title': title,
        'text': text,
        if (tag != null) 'tag': tag,
        if (location != null) 'location': location.toJson(),
        'imageUploadIds': imageUploadIds,
      },
    ),
  );

  @override
  Future<Work> editWork(
    Work original, {
    required String title,
    required String text,
    String? tag,
    required List<String> imageUploadIds,
  }) async => Work.fromJson(
    await _send(
      'PATCH',
      '/v1/discovery/works/${original.id}',
      body: {'title': title, 'text': text, 'tag': tag, 'imageUploadIds': imageUploadIds},
    ),
    provider: original.provider,
  );
  @override
  Future<void> deleteWork(String id) => _send('DELETE', '/v1/discovery/works/$id');

  @override
  Future<Work> recommend(Work w, bool on) async {
    final j = await _send(on ? 'POST' : 'DELETE', '/v1/discovery/works/${w.id}/recommend');
    return w.copyWith(recommended: j['recommended'] == true, recs: (j['recs'] as num?)?.toInt() ?? w.recs);
  }

  @override
  Future<List<Work>> providerWorks(String providerId) =>
      _allPages('/v1/discovery/providers/$providerId/works', {'limit': 50}, Work.fromJson);

  // Preserve all records for existing list providers and reject cursor loops.
  Future<List<T>> _allPages<T>(String path, Map<String, dynamic> query, T Function(Json) parse) async {
    final items = <T>[];
    final seen = <String>{};
    String? cursor;
    do {
      final page = await _get(path, {...query, if (cursor != null) 'cursor': cursor});
      items.addAll(
        _items(
          page,
          (j) => parse({...j, if (page['interestSummaryAvailable'] == false) 'interestSummaryAvailable': false}),
        ),
      );
      cursor = page['nextCursor']?.toString();
      if (page['hasMore'] != true) break;
      if (cursor == null || cursor.isEmpty || !seen.add(cursor)) {
        throw const ApiException(code: 'client.unexpected_response');
      }
    } while (true);
    return items;
  }

  // ---------------- solicitudes ----------------
  @override
  Future<ServiceRequest> createRequest({
    required String category,
    required String title,
    required String description,
    required String urgency,
    required String contact,
    required GeoPoint location,
    List<String> imageUploadIds = const [],
    required String idempotencyKey,
  }) async => ServiceRequest.fromJson(
    await _send(
      'POST',
      '/v1/discovery/requests',
      idem: idempotencyKey,
      body: {
        'category': category,
        'title': title,
        'description': description,
        'urgency': urgency,
        'contact': contact,
        'location': location.toJson(),
        'imageUploadIds': imageUploadIds,
      },
    ),
    mine: true,
  );

  @override
  Future<ServiceRequest> editRequest(
    String id, {
    required String title,
    required String description,
    required String urgency,
    required String contact,
    required List<String> imageUploadIds,
  }) async => ServiceRequest.fromJson(
    await _send(
      'PATCH',
      '/v1/discovery/requests/$id',
      body: {
        'title': title,
        'description': description,
        'urgency': urgency,
        'contact': contact,
        'imageUploadIds': imageUploadIds,
      },
    ),
    mine: true,
  );
  @override
  Future<List<ServiceRequest>> myRequests() => _allPages('/v1/discovery/requests/mine', {
    'status': 'all',
    'limit': 50,
  }, (j) => ServiceRequest.fromJson(j, mine: true));

  @override
  Future<List<ServiceRequest>> opportunities(OppFilters f) => _allPages('/v1/discovery/requests/opportunities', {
    'cat': f.cat,
    'today': f.today,
    'inRadius': f.inRadius,
    'myServiceOnly': f.myServiceOnly,
    'q': f.q.trim(),
    'limit': 50,
  }, ServiceRequest.fromJson);

  @override
  Future<void> deleteRequest(String id) => _send('DELETE', '/v1/discovery/requests/$id');
  @override
  Future<void> closeRequest(String id, {required String outcome, String? pickedProviderId}) => _send(
    'POST',
    '/v1/discovery/requests/$id/close',
    body: {'outcome': outcome, if (pickedProviderId != null) 'pickedProviderId': pickedProviderId},
  );

  // ---------------- interés ----------------
  @override
  Future<void> setInterest(String requestId, bool on, {String? note}) => _send(
    on ? 'POST' : 'DELETE',
    '/v1/engagement/requests/$requestId/interest',
    body: on ? {if (note != null && note.isNotEmpty) 'note': note} : null,
  );

  @override
  Future<InterestedPage> interested(String requestId, {String sort = 'rate'}) async {
    final path = '/v1/engagement/requests/$requestId/interested';
    var page = await _get(path, {'sort': sort, 'limit': 50});
    final title = '${page['requestTitle'] ?? ''}';
    final status = '${page['requestStatus'] ?? 'open'}';
    final items = <Interested>[];
    final seen = <String>{};
    while (true) {
      items.addAll(_items(page, Interested.fromJson));
      if (page['hasMore'] != true) break;
      final cursor = page['nextCursor']?.toString();
      if (cursor == null || cursor.isEmpty || !seen.add(cursor)) {
        throw const ApiException(code: 'client.unexpected_response');
      }
      page = await _get(path, {'sort': sort, 'limit': 50, 'cursor': cursor});
    }
    return InterestedPage(requestId: requestId, title: title, status: status, items: items);
  }

  // ---------------- pedidos ----------------
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
  }) async => Order.fromJson(
    await _send(
      'POST',
      '/v1/engagement/orders',
      idem: idempotencyKey,
      body: {
        'providerId': providerId,
        if (requestId != null) 'requestId': requestId,
        'origin': requestId == null ? 'direct' : 'post',
        // El servidor solo la conserva si el prestador ofrece esa categoría.
        'category': category,
        'description': description,
        'attention': attention,
        if (address != null) 'address': address,
        if (addressNote != null) 'addressNote': addressNote,
        if (location != null) 'location': location.toJson(),
      },
    ),
  );

  @override
  Future<OrdersPage> orders({required String role, String status = 'all'}) async {
    final j = await _get('/v1/engagement/orders', {'role': role, 'status': status, 'limit': 50});
    final c = j['counts'] is Map ? j['counts'] as Map : const {};
    int n(String k) => (c[k] as num?)?.toInt() ?? 0;
    return OrdersPage(
      _items(j, Order.fromJson),
      pending: n('pending'),
      accepted: n('accepted'),
      resolved: n('resolved'),
    );
  }

  @override
  Future<Order> order(String id) async => Order.fromJson(await _get('/v1/engagement/orders/$id'));

  Future<Order> _action(Order o, String action, Json body) async {
    await _send('POST', '/v1/engagement/orders/${o.id}/$action', body: body, ifMatch: o.version);
    return order(o.id);
  }

  @override
  Future<Order> acceptOrder(Order o, {int? amountCents, String? includes}) => _action(o, 'accept', {
    if (amountCents != null) 'agreedPrice': {'amountCents': amountCents, if (includes != null) 'includes': includes},
  });

  @override
  Future<Order> rejectOrder(Order o, {required String reason, String? note}) =>
      _action(o, 'reject', {'reason': reason, if (note != null && note.isNotEmpty) 'note': note});

  @override
  Future<Order> cancelOrder(Order o, {required String reason}) => _action(o, 'cancel', {'reason': reason});

  @override
  Future<Order> resolveOrder(Order o, {int? finalPriceCents, String? note}) => _action(o, 'resolve', {
    if (finalPriceCents != null) 'finalPrice': {'amountCents': finalPriceCents},
    if (note != null && note.isNotEmpty) 'note': note,
  });

  @override
  Future<Order> updateAddress(Order o, {required String address, String? addressNote, GeoPoint? location}) async {
    await _send(
      'PUT',
      '/v1/engagement/orders/${o.id}/address',
      ifMatch: o.version,
      body: {
        'address': address,
        if (addressNote != null) 'addressNote': addressNote,
        if (location != null) 'location': location.toJson(),
      },
    );
    return order(o.id);
  }

  // ---------------- opiniones ----------------
  @override
  Future<void> review({required String orderId, required int stars, required String text, required bool recommend}) =>
      _send(
        'POST',
        '/v1/engagement/reviews',
        idem: _uuid.v4(),
        body: {'orderId': orderId, 'stars': stars, 'text': text, 'recommend': recommend},
      );

  @override
  Future<ReviewsPage> reviews(String providerId) async =>
      ReviewsPage.fromJson(await _get('/v1/engagement/providers/$providerId/reviews', {'limit': 30}));

  // ---------------- mensajes ----------------
  @override
  Future<(List<Conversation>, int)> conversations({required String role, String filter = 'all'}) async {
    final j = await _get('/v1/engagement/conversations', {'role': role, 'filter': filter, 'limit': 50});
    return (_items(j, Conversation.fromJson), (j['totalUnread'] as num?)?.toInt() ?? 0);
  }

  @override
  Future<String> openConversation({String? providerId, String? requestId}) async {
    final j = await _send(
      'POST',
      '/v1/engagement/conversations',
      idem: _uuid.v4(),
      body: {if (providerId != null) 'providerId': providerId, if (requestId != null) 'requestId': requestId},
    );
    return '${j['conversationId']}';
  }

  @override
  Future<ChatThread> messages(String conversationId, {String? before}) async {
    final j = await _get('/v1/engagement/conversations/$conversationId/messages', {'before': before, 'limit': 30});
    final cp = j['counterpart'] is Map ? Json.from(j['counterpart'] as Map) : null;
    final encrypted = j['encrypted'] == true;
    if (encrypted) _privateConversations.add(conversationId);
    if (!encrypted && _privateConversations.contains(conversationId)) {
      throw StateError('Se rechazo un cambio a chat sin cifrar');
    }
    var messages = _items(j, Message.fromJson).reversed.toList();
    if (encrypted) {
      final peer = j['peerAccountId'] as String?;
      final factory = encryptedChat;
      if (peer == null || factory == null) {
        throw StateError('Actualiza la aplicaci\u00f3n para abrir este chat privado');
      }
      final transport = await factory();
      _privatePeers[conversationId] = peer;
      final decoded = <Message>[];
      for (final message in messages) {
        if (message.kind != 'encrypted') {
          decoded.add(message);
          continue;
        }
        try {
          Map<String, dynamic> content;
          final envelopes = message.encryptedPayload?['envelopes'] as List? ?? [];
          final selected = envelopes
              .whereType<Map>()
              .where(
                (e) => e['recipient'] == transport.crypto.account && e['recipientDevice'] == transport.crypto.deviceId,
              )
              .firstOrNull;
          Map<String, dynamic>? ownContent;
          if (message.mine) {
            try {
              ownContent = await transport.readOwn(
                message.id,
                conversationId,
                operationId: envelopes.whereType<Map>().firstOrNull?['messageId'] as String?,
              );
            } on StateError {
              // A different originating device may instead have an envelope for this one.
            }
          }
          if (ownContent != null) {
            content = ownContent;
          } else {
            if (selected == null || message.senderId == null) {
              throw StateError('El mensaje no est\u00e1 disponible para este dispositivo');
            }
            content = await transport.crypto.decrypt(
              conversation: conversationId,
              sender: message.senderId!,
              envelope: Map<String, dynamic>.from(selected),
            );
          }
          if (message.editedAt != null && content['editOf'] != message.id) {
            throw StateError('La edicion no corresponde a este mensaje');
          }
          decoded.add(
            Message(
              editedAt: message.editedAt,
              id: message.id,
              kind: '${content['kind']}',
              text: content['text'] as String? ?? '',
              privateAttachment: content['file'] is Map ? Json.from(content['file'] as Map) : null,
              mine: message.mine,
              createdAt: message.createdAt,
              encryptedPayload: message.encryptedPayload,
              senderId: message.senderId,
              readAt: message.readAt,
              deliveredAt: message.deliveredAt,
            ),
          );
        } catch (error) {
          if (kDebugMode) {
            final reason = error is StateError ? error.message : error.runtimeType.toString();
            debugPrint('[CHAT] private message unavailable: $reason');
          }
          // Keep unavailable ciphertext intact; never reset sessions or invent plaintext.
          decoded.add(
            Message(
              id: message.id,
              kind: 'unavailable',
              text:
                  'Este mensaje privado no est\u00e1 disponible en este dispositivo. Pide que te lo env\u00eden de nuevo.',
              mine: message.mine,
              createdAt: message.createdAt,
              encryptedPayload: message.encryptedPayload,
              senderId: message.senderId,
            ),
          );
        }
      }
      messages = decoded;
    }
    return ChatThread(
      encrypted: encrypted,
      peerAccountId: j['peerAccountId'] as String?,
      id: conversationId,
      counterpart: Counterpart.fromJson(cp),
      // El API devuelve del más nuevo al más viejo.
      messages: messages,
      activeOrder: ActiveOrder.fromJson(j['activeOrder'] is Map ? Json.from(j['activeOrder'] as Map) : null),
      blocked: j['blocked'] == true,
      canSend: j['canSend'] != false,
      quickReplies: (j['quickReplies'] is List ? j['quickReplies'] as List : const []).map((e) => '$e').toList(),
      hasMore: j['hasMore'] == true,
      nextCursor: j['nextCursor']?.toString(),
    );
  }

  @override
  Future<void> editMessage(String conversationId, String messageId, String text) async {
    final value = text.trim();
    if (value.isEmpty || value.length > 1000) throw StateError('Escribe entre 1 y 1000 caracteres.');
    final peer = _privatePeers[conversationId];
    if (peer == null || encryptedChat == null) throw StateError('Abre el chat privado antes de editar.');
    await (await encryptedChat!()).send(conversationId, peer, {
      'kind': 'text',
      'text': value,
      'editOf': messageId,
    }, editTarget: messageId);
  }

  @override
  Future<void> deleteMessage(String conversationId, String messageId) async {
    if (!_privateConversations.contains(conversationId)) throw StateError('Abre el chat privado antes de eliminar.');
    await _send(
      'DELETE',
      '/v1/engagement/chat-keys/conversations/$conversationId/messages/$messageId',
      idem: _uuid.v4(),
    );
    if (encryptedChat != null) await (await encryptedChat!()).discardDeletedEdit(conversationId, messageId);
  }

  @override
  Future<Message> sendMessage(String conversationId, {String? text, String? imageUploadId}) async {
    if (_privateConversations.contains(conversationId) &&
        (_privatePeers[conversationId] == null || encryptedChat == null)) {
      throw StateError('El chat requiere cifrado; no se enviara texto sin proteccion');
    }
    if (_privatePeers[conversationId] case final String peer) {
      if (imageUploadId != null) throw StateError('Las fotos privadas requieren el transporte de adjuntos cifrados');
      final transport = await encryptedChat!();
      final id = await transport.send(conversationId, peer, {'kind': 'text', 'text': text});
      return Message(id: id, kind: 'text', text: text ?? '', mine: true);
    }
    return Message.fromJson(
      await _send(
        'POST',
        '/v1/engagement/conversations/$conversationId/messages',
        idem: _uuid.v4(),
        body: imageUploadId != null
            ? {'kind': 'image', 'imageUploadId': imageUploadId}
            : {'kind': 'text', 'text': text},
      ),
    );
  }

  @override
  Future<void> markDelivered(String conversationId, String upToMessageId) =>
      _send('POST', '/v1/engagement/conversations/$conversationId/delivered', body: {'upToMessageId': upToMessageId});

  @override
  Future<void> markRead(String conversationId, String upToMessageId) =>
      _send('POST', '/v1/engagement/conversations/$conversationId/read', body: {'upToMessageId': upToMessageId});

  @override
  Future<bool> block(String conversationId, bool blocked, {bool alsoReport = false}) async {
    final j = await _send(
      'POST',
      '/v1/engagement/conversations/$conversationId/block',
      body: {'blocked': blocked, 'alsoReport': alsoReport},
    );
    return j['blocked'] == true;
  }

  // ---------------- guardados ----------------
  @override
  Future<(List<SavedItem>, SavedCounts)> saved({String? kind}) async {
    final j = await _get('/v1/discovery/saved', {'kind': kind, 'limit': 50});
    final rows = <dynamic>[...?j['items'] as List?];
    var page = j;
    final seen = <String>{};
    while (page['hasMore'] == true) {
      final cursor = page['nextCursor']?.toString();
      if (cursor == null || cursor.isEmpty || !seen.add(cursor)) {
        throw const ApiException(code: 'client.unexpected_response');
      }
      page = await _get('/v1/discovery/saved', {'kind': kind, 'limit': 50, 'cursor': cursor});
      rows.addAll(page['items'] as List? ?? const []);
    }
    final items = _items({...j, 'items': rows}, (s) {
      final p = s['provider'], w = s['work'], r = s['request'];
      return SavedItem(
        kind: '${s['kind']}',
        targetId: '${s['targetId']}',
        available: s['available'] != false,
        provider: p is Map ? ProviderProfile.fromJson(Json.from(p)) : null,
        work: w is Map ? Work.fromJson({...Json.from(w), 'saved': true}) : null,
        request: r is Map ? ServiceRequest.fromJson({...Json.from(r), 'saved': true}) : null,
      );
    });
    return (items, SavedCounts.fromJson(j['counts'] is Map ? Json.from(j['counts'] as Map) : null));
  }

  @override
  Future<SavedCounts> setSaved(String kind, String id, bool on) async {
    final j = await _send(on ? 'POST' : 'DELETE', '/v1/discovery/saved/$kind/$id');
    return SavedCounts.fromJson(j['savedCounts'] is Map ? Json.from(j['savedCounts'] as Map) : null);
  }

  // ---------------- contacto y reportes ----------------
  @override
  Future<PhoneReveal> revealPhone({
    required String targetId,
    required String targetType,
    required String context,
  }) async {
    final j = await _send(
      'POST',
      '/v1/engagement/contacts/phone',
      body: {'targetId': targetId, 'targetType': targetType, 'context': context},
    );
    return PhoneReveal('${j['displayPhone'] ?? j['phone'] ?? ''}', '${j['targetName'] ?? ''}');
  }

  @override
  Future<String> report({
    required String targetType,
    required String targetId,
    required String category,
    required String reason,
  }) async {
    final j = await _send(
      'POST',
      '/v1/engagement/reports',
      idem: _uuid.v4(),
      body: {'targetType': targetType, 'targetId': targetId, 'category': category, 'reason': reason},
    );
    return '${j['message'] ?? 'Recibimos tu reporte.'}';
  }

  // ---------------- notificaciones ----------------
  @override
  Future<(List<NotificationItem>, int)> notifications({String filter = 'all'}) async {
    final j = await _get('/v1/engagement/notifications', {'filter': filter, 'limit': 30});
    return (_items(j, NotificationItem.fromJson), (j['unreadCount'] as num?)?.toInt() ?? 0);
  }

  @override
  Future<void> markNotificationsRead(List<String> ids) =>
      _send('POST', '/v1/engagement/notifications/read', body: {'notificationIds': ids});

  @override
  Future<String?> myCover() async => (await _get('/v1/discovery/me/cover'))['url'] as String?;
  @override
  Future<String> setMyCover(String uploadId) async =>
      (await _send('PUT', '/v1/discovery/me/cover', body: {'uploadId': uploadId}))['url'] as String;

  // ---------------- imágenes ----------------
  @override
  Future<String> upload(PickedImage img, {required String purpose}) => _call(() async {
    if (img.bytes.isEmpty || img.bytes.length > 5242880) throw const ApiException(code: 'upload.too_large');
    if (!{'image/jpeg', 'image/png', 'image/webp'}.contains(img.contentType)) {
      throw const ApiException(code: 'upload.content_type_invalid');
    }
    final t = await _send(
      'POST',
      '/v1/discovery/uploads',
      body: {
        'purpose': purpose,
        'contentType': img.contentType,
        'size': img.bytes.length,
        if (img.width != null) 'width': img.width,
        if (img.height != null) 'height': img.height,
      },
    );
    final id = t['uploadId'];
    final uri = Uri.tryParse('${t['uploadUrl']}');
    if (id is! String ||
        id.isEmpty ||
        uri == null ||
        !Env.isSecureBaseUrl(uri.toString(), release: kReleaseMode) ||
        uri.userInfo.isNotEmpty ||
        t['method'] != null && t['method'] != 'PUT') {
      throw const ApiException(code: 'client.unexpected_response');
    }
    final headers = <String, dynamic>{};
    if (t['headers'] is Map) {
      (t['headers'] as Map).forEach((k, v) => headers['$k'] = '$v');
    }
    // La URL firmada va directo al almacenamiento: sin Bearer ni baseUrl.
    await _uploadDio.put<dynamic>(
      '${t['uploadUrl']}',
      data: Stream.fromIterable([img.bytes]),
      options: Options(headers: {...headers, Headers.contentLengthHeader: img.bytes.length}),
    );
    var state = await _send('POST', '/v1/discovery/uploads/$id/complete');
    for (var n = 0; n < 40; n++) {
      if (state['status'] == 'approved') return id;
      if (state['status'] == 'rejected') throw const ApiException(code: 'upload.rejected_by_moderation');
      if (state['status'] != 'processing' && state['status'] != 'uploaded' && state['status'] != 'pending') {
        throw const ApiException(code: 'client.unexpected_response');
      }
      if (n > 0) await Future<void>.delayed(const Duration(seconds: 2));
      state = await _get('/v1/discovery/uploads/$id');
    }
    throw const ApiException(
      code: 'upload.processing_timeout',
      detail: 'La foto sigue en revisión. Espera un momento y vuelve a intentarlo.',
    );
  });

  // ---------------- asistente (IA generativa, EP-082) ----------------
  @override
  Future<AssistDraft> assistDraft({
    required String kind,
    required String category,
    required String userText,
    int lengthLimit = 600,
  }) async {
    final j = await _send(
      'POST',
      '/v1/assist/draft',
      body: {'kind': kind, 'categoryId': category, 'userText': userText, 'lengthLimit': lengthLimit},
    );
    final d = j['draft'];
    final text = d is Map ? '${d['text'] ?? d['description'] ?? ''}' : '${d ?? ''}';
    if (text.trim().isEmpty) throw const ApiException(code: 'client.unexpected_response');
    return AssistDraft(
      text: text.trim(),
      title: d is Map && d['title'] != null ? '${d['title']}' : null,
      modelVersion: '${j['modelVersion'] ?? ''}',
    );
  }

  // ---------------- dispositivos (push) ----------------
  @override
  Future<String> registerDevice({required String fcmToken, required String appVersion}) async {
    final j = await _send(
      'POST',
      '/v1/identity/devices',
      body: {'fcmToken': fcmToken, 'platform': 'android', 'appVersion': appVersion},
    );
    return '${j['deviceId'] ?? ''}';
  }

  @override
  Future<void> removeDevice(String deviceId) => _send('DELETE', '/v1/identity/devices/$deviceId');
}
