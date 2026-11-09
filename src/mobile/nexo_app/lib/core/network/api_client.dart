import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/env.dart';
import '../auth/auth_tokens.dart';
import '../auth/session_controller.dart';
import '../auth/token_storage.dart';
import '../local/offline_interceptor.dart';
import '../local/sync_controller.dart';

/// Marca en `Options.extra` para pedir el header Authorization.
const kAuth = 'nexo.auth';
const _kRetried = 'nexo.retried';

BaseOptions _baseOptions() => BaseOptions(
      baseUrl: Env.apiBaseUrl,
      // Corto: si el backend no contesta, el modo auto pasa a la maqueta (spec 045).
      connectTimeout: const Duration(seconds: 6),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Accept': 'application/json'},
    );

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(_baseOptions());
  dio.interceptors
    ..add(AuthInterceptor(ref, dio))
    // Caché por cuenta y cola sin señal (spec 051). Va después del de
    // autenticación: un 401 se renueva antes de decidir si hay red.
    ..add(OfflineCacheInterceptor(
      store: () => ref.read(localStoreProvider),
      account: () => accountKey(ref.read(sessionProvider)),
      onOffline: (t) => ref.read(syncProvider.notifier).markOffline(t),
      onOnline: () => ref.read(syncProvider.notifier).markOnline(),
      onQueued: () => ref.read(syncProvider.notifier).queued(),
    ));
  return dio;
});

/// Pide `grant_type=refresh_token`. Devuelve null si el servidor rechazó el
/// refresh (reusado, vencido, revocado) y lanza si fue un fallo de red.
Future<AuthTokens?> refreshTokens(String refreshToken) async {
  try {
    final res = await Dio(_baseOptions()).post<Map<String, dynamic>>(
      '/connect/token',
      data: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        if (Env.oauthClientId.isNotEmpty) 'client_id': Env.oauthClientId,
      },
      options: Options(contentType: Headers.formUrlEncodedContentType),
    );
    return AuthTokens.fromOAuth(res.data!, fallbackRefresh: refreshToken);
  } on DioException catch (e) {
    final s = e.response?.statusCode;
    if (s == 400 || s == 401 || s == 403) return null;
    rethrow;
  }
}

/// Agrega el JWT y, ante un 401, renueva UNA sola vez aunque varias
/// peticiones fallen a la vez (spec 004: refresh concurrente sin bucles).
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._ref, this._dio);

  final Ref _ref;
  final Dio _dio;
  Future<AuthTokens?>? _refreshing;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    if (options.extra[kAuth] == true) {
      final t = await _ref.read(tokenStorageProvider).read();
      if (t != null) options.headers['Authorization'] = 'Bearer ${t.accessToken}';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final o = err.requestOptions;
    if (err.response?.statusCode != 401 ||
        o.extra[kAuth] != true ||
        o.extra[_kRetried] == true) {
      handler.next(err);
      return;
    }
    AuthTokens? fresh;
    try {
      fresh = await _refresh();
    } catch (_) {
      // Sin red: no se cierra la sesión, solo se informa el error.
      handler.next(err);
      return;
    }
    if (fresh == null) {
      await _ref.read(sessionProvider.notifier).signOutLocal();
      handler.next(err);
      return;
    }
    try {
      o.extra[_kRetried] = true;
      handler.resolve(await _dio.fetch<dynamic>(o));
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  Future<AuthTokens?> _refresh() {
    return _refreshing ??= _doRefresh().whenComplete(() => _refreshing = null);
  }

  Future<AuthTokens?> _doRefresh() async {
    final current = await _ref.read(tokenStorageProvider).read();
    if (current == null) return null;
    final t = await refreshTokens(current.refreshToken);
    if (t != null) await _ref.read(sessionProvider.notifier).updateTokens(t);
    return t;
  }
}
