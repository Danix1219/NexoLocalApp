import 'dart:convert';

import 'package:dio/dio.dart';

import '../network/api_exception.dart';
import 'local_store.dart';

/// Cabecera que marca una respuesta servida desde el teléfono.
const kCacheHeader = 'x-nexo-cache';

/// `Options.extra`: reintento desde la cola (no se vuelve a encolar).
const kReplay = 'nexo.replay';
const _kCached = 'nexo.cached';

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
    DateTime Function()? clock,
  }) : _now = clock ?? DateTime.now;

  final Future<LocalStore> Function() store;

  /// Id de la cuenta actual (`guest` sin sesión).
  final String Function() account;
  final void Function(DateTime savedAt)? onOffline;
  final void Function()? onOnline;
  final void Function()? onQueued;
  final DateTime Function() _now;

  /// Datos que nunca se guardan en el teléfono.
  static const _never = [
    '/contacts/',
    '/uploads',
    '/identity/devices',
    '/identity/email',
    '/identity/password',
    '/reports'
  ];

  static const freshFor = {'/v1/discovery/categories': Duration(hours: 1)};

  static const queueable = {'POST /v1/discovery/requests'};

  static bool cacheable(RequestOptions o) =>
      o.method.toUpperCase() == 'GET' && o.uri.path.startsWith('/v1/') && !_never.any(o.uri.path.contains);

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
  void onRequest(RequestOptions o, RequestInterceptorHandler handler) async {
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
  void onResponse(Response<dynamic> r, ResponseInterceptorHandler handler) async {
    final o = r.requestOptions;
    if (r.headers.value(kCacheHeader) == null) onOnline?.call();
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
  void onError(DioException e, ErrorInterceptorHandler handler) async {
    final o = e.requestOptions;
    final cached = o.extra[_kCached];

    // 304: lo guardado sigue vigente.
    if (e.response?.statusCode == 304 && cached is CachedResponse) {
      onOnline?.call();
      try {
        await (await store())
            .write(account(), keyOf(o), CachedResponse(body: cached.body, etag: cached.etag, savedAt: _now()));
      } catch (_) {}
      return handler.resolve(_fromCache(o, cached, 'revalidated'));
    }

    if (_noAnswer(e)) {
      if (cached is CachedResponse) {
        onOffline?.call(cached.savedAt);
        return handler.resolve(_fromCache(o, cached, 'offline'));
      }
      if (canQueue(o)) {
        try {
          final idem = '${o.headers['Idempotency-Key'] ?? ''}';
          if (idem.isNotEmpty) {
            await (await store()).enqueue(OutboxItem(
              account: account(),
              method: o.method.toUpperCase(),
              path: o.uri.path,
              body: jsonEncode(o.data),
              idempotencyKey: idem,
              createdAt: _now(),
            ));
            onQueued?.call();
            return handler.reject(DioException(
              requestOptions: o,
              type: DioExceptionType.unknown,
              error: const ApiException(
                code: kQueuedOffline,
                detail: 'Sin señal: lo guardamos y se publicará en cuanto vuelva la conexión.',
              ),
            ));
          }
        } catch (_) {}
      }
    }
    handler.next(e);
  }
}
