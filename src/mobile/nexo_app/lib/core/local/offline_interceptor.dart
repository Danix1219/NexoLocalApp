import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';

import '../network/api_exception.dart';
import 'local_store.dart';
import 'snapshot_cipher.dart';

/// Cabecera que marca una respuesta servida desde el teléfono.
const kCacheHeader = 'x-nexo-cache';

/// `Options.extra`: reintento desde la cola (no se vuelve a encolar).
const kReplay = 'nexo.replay';
const _kCached = 'nexo.cached';
const _kOwner = 'nexo.owner';
const _kSealed = 'sealed:';

/// Caché del cliente (requisito 9: caché en frontend) y cola sin conexión.
///
/// - Lecturas `GET /v1/…`: se guardan por cuenta; se revalidan con `ETag`
///   (`If-None-Match` → `304`) y, sin señal, se responde con lo guardado.
/// - Catálogo de categorías: se sirve del teléfono durante 1 h.
/// - `POST /v1/discovery/requests` sin señal: se guarda en la cola con su
///   `Idempotency-Key` y se envía al volver la conexión (spec 051).
class OfflineCacheInterceptor extends Interceptor {
  OfflineCacheInterceptor({
    required this.store,
    required this.account,
    this.onOffline,
    this.onOnline,
    this.onQueued,
    this.vault,
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  /// Sin cifrador no se guarda copia de lo excluido de la caché.
  final SnapshotCipher? vault;

  final Future<LocalStore> Function() store;

  /// Id de la cuenta actual (`guest` sin sesión).
  final String Function() account;
  final void Function(DateTime savedAt)? onOffline;
  final void Function()? onOnline;
  final void Function()? onQueued;
  final DateTime Function() _now;

  /// Datos que nunca se guardan en el teléfono.
  static const _never = [
    '/engagement/chat-keys',
    '/engagement/conversations',
    '/identity/me',
    '/discovery/places',
    '/discovery/me/location',
    '/discovery/providers',
    '/contacts/',
    '/uploads',
    '/discovery/me/cover',
    '/discovery/media',
    '/identity/devices',
    '/identity/email',
    '/identity/password',
    '/discovery/requests',
    '/discovery/works',
    '/discovery/map',
    '/discovery/search',
    '/reports',
  ];

  static const freshFor = {'/v1/discovery/categories': Duration(hours: 1)};

  static const queueable = {'POST /v1/discovery/requests'};

  static bool cacheable(RequestOptions o) =>
      o.method.toUpperCase() == 'GET' && o.uri.path.startsWith('/v1/') && !_never.any(o.uri.path.contains);

  /// Lecturas que la caché sin cifrar excluye, pero que hacen falta para ver
  /// la app sin señal. Solo se guardan cifradas, por cuenta, y solo se usan
  /// cuando no hay respuesta. Contacto, domicilios buscados, subidas, claves,
  /// hilos de chat y credenciales quedan fuera.
  static final _offline = [
    RegExp(r'^/v1/identity/me$'),
    RegExp(r'^/v1/discovery/me/(location|cover)$'),
    RegExp(r'^/v1/discovery/(providers|requests|works|search|map)(/|$)'),
    RegExp(r'^/v1/engagement/conversations$'),
  ];

  static bool snapshotable(RequestOptions o) =>
      o.method.toUpperCase() == 'GET' && !cacheable(o) && _offline.any((rule) => rule.hasMatch(o.uri.path));

  Future<void> _saveSnapshot(RequestOptions o, Map<dynamic, dynamic> data) async {
    final cipher = vault;
    final owner = o.extra[_kOwner];
    // Una respuesta que llega tras salir o cambiar de cuenta no se guarda.
    if (cipher == null || owner is! String || owner == 'guest' || owner != account()) return;
    try {
      final name = '$_kSealed${await cipher.label(keyOf(o), owner)}';
      final body = await cipher.seal(jsonEncode(data), '$owner|$name');
      if (owner != account()) return;
      await (await store()).write(owner, name, CachedResponse(body: body, savedAt: _now()));
    } catch (_) {}
  }

  Future<CachedResponse?> _readSnapshot(RequestOptions o) async {
    final cipher = vault;
    final owner = account();
    if (cipher == null || owner == 'guest') return null;
    try {
      final name = '$_kSealed${await cipher.label(keyOf(o), owner)}';
      final stored = await (await store()).read(owner, name);
      if (stored == null) return null;
      return CachedResponse(body: await cipher.open(stored.body, '$owner|$name'), savedAt: stored.savedAt);
    } catch (_) {
      return null;
    }
  }

  static bool canQueue(RequestOptions o) =>
      queueable.contains('${o.method.toUpperCase()} ${o.uri.path}') && o.extra[kReplay] != true;

  /// Clave estable: ruta + parámetros ordenados.
  static String keyOf(RequestOptions o) {
    final q = Map.of(o.uri.queryParameters)..removeWhere((_, v) => v.isEmpty);
    final keys = q.keys.toList()..sort();
    return keys.isEmpty ? o.uri.path : '${o.uri.path}?${keys.map((k) => '$k=${q[k]}').join('&')}';
  }

  static bool _noAnswer(DioException e) =>
      e.response == null && e.type != DioExceptionType.cancel && e.type != DioExceptionType.badCertificate;

  Response<dynamic> _fromCache(RequestOptions o, CachedResponse c, String how) => Response<dynamic>(
    requestOptions: o,
    statusCode: 200,
    data: jsonDecode(c.body),
    headers: Headers.fromMap({
      kCacheHeader: [how],
      Headers.contentTypeHeader: [Headers.jsonContentType],
    }),
  );

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final o = options;
    o.extra[_kOwner] = account();
    if (!cacheable(o)) return handler.next(o);
    try {
      final c = await (await store()).read(account(), keyOf(o));
      if (c != null) {
        final ttl = freshFor[o.uri.path];
        if (ttl != null && _now().difference(c.savedAt) < ttl) {
          return handler.resolve(_fromCache(o, c, 'fresh'));
        }
        o.extra[_kCached] = c;
        if (c.etag != null) o.headers['If-None-Match'] = c.etag;
      }
    } catch (_) {
      // Caché dañada o ilegible: se sigue con la red.
    }
    handler.next(o);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) async {
    final r = response;
    final o = r.requestOptions;
    if (r.headers.value(kCacheHeader) == null) onOnline?.call();
    if (snapshotable(o) && r.statusCode == 200 && r.data is Map) {
      // Sin esperar: la pantalla no se retrasa por guardar la copia.
      unawaited(_saveSnapshot(o, r.data as Map));
    }
    if (cacheable(o) && r.statusCode == 200 && r.data is Map && r.headers.value(kCacheHeader) == null) {
      try {
        await (await store()).write(
          account(),
          keyOf(o),
          CachedResponse(body: jsonEncode(r.data), etag: r.headers.value('etag'), savedAt: _now()),
        );
      } catch (_) {}
    }
    handler.next(r);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final e = err;
    final o = e.requestOptions;
    final cached = o.extra[_kCached];

    // 304: lo guardado sigue vigente.
    if (e.response?.statusCode == 304 && cached is CachedResponse) {
      onOnline?.call();
      try {
        await (await store()).write(
          account(),
          keyOf(o),
          CachedResponse(body: cached.body, etag: cached.etag, savedAt: _now()),
        );
      } catch (_) {}
      return handler.resolve(_fromCache(o, cached, 'revalidated'));
    }

    if (_noAnswer(e)) {
      if (snapshotable(o)) {
        final copy = await _readSnapshot(o);
        if (copy != null) {
          onOffline?.call(copy.savedAt);
          return handler.resolve(_fromCache(o, copy, 'offline'));
        }
      }
      if (cached is CachedResponse) {
        onOffline?.call(cached.savedAt);
        return handler.resolve(_fromCache(o, cached, 'offline'));
      }
      if (canQueue(o)) {
        try {
          final idem = '${o.headers['Idempotency-Key'] ?? ''}';
          if (idem.isNotEmpty) {
            await (await store()).enqueue(
              OutboxItem(
                account: account(),
                method: o.method.toUpperCase(),
                path: o.uri.path,
                body: jsonEncode(o.data),
                idempotencyKey: idem,
                createdAt: _now(),
              ),
            );
            onQueued?.call();
            return handler.reject(
              DioException(
                requestOptions: o,
                type: DioExceptionType.unknown,
                error: const ApiException(
                  code: kQueuedOffline,
                  detail: 'Sin señal: lo guardamos y se publicará en cuanto vuelva la conexión.',
                ),
              ),
            );
          }
        } catch (_) {}
      }
    }
    handler.next(e);
  }
}
