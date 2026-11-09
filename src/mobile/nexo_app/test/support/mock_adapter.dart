import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Llamada HTTP registrada por [MockAdapter].
class Recorded {
  Recorded(this.options);
  final RequestOptions options;

  String get method => options.method;
  String get path => options.uri.path;
  String get host => options.uri.host;
  Map<String, String> get query => options.uri.queryParameters;
  dynamic get body => options.data;

  /// Header sin distinguir mayúsculas.
  String? header(String name) {
    for (final e in options.headers.entries) {
      if (e.key.toLowerCase() == name.toLowerCase()) return e.value?.toString();
    }
    return null;
  }
}

typedef Responder = ResponseBody Function(RequestOptions o);

/// Adaptador de Dio que responde sin red con lo que diga cada prueba.
/// Las rutas no registradas responden 404 sin cuerpo (como un endpoint que
/// el backend todavía no publica).
class MockAdapter implements HttpClientAdapter {
  final List<Recorded> calls = [];
  final Map<String, Responder> _routes = {};
  Responder? fallback;

  /// Registra `METHOD /ruta` → JSON con estado.
  void on(String method, String path, Object? json, {int status = 200, Map<String, List<String>> headers = const {}}) {
    _routes['$method $path'] = (_) => jsonBody(json, status: status, headers: headers);
  }

  void onRaw(String method, String path, Responder r) => _routes['$method $path'] = r;

  /// Sin señal: todas las rutas fallan, también las registradas.
  bool isOffline = false;
  void offline() => isOffline = true;

  /// Vuelve la señal.
  void online() => isOffline = false;

  Recorded last(String method, String path) =>
      calls.lastWhere((c) => c.method == method && c.path == path, orElse: () => throw StateError('No hubo $method $path'));

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    calls.add(Recorded(options));
    if (isOffline) {
      throw DioException(
        requestOptions: options,
        type: DioExceptionType.connectionError,
        message: 'sin señal (prueba)',
      );
    }
    final r = _routes['${options.method} ${options.uri.path}'] ?? fallback;
    if (r == null) return ResponseBody.fromString('', 404);
    return r(options);
  }

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(Object? json, {int status = 200, Map<String, List<String>> headers = const {}}) {
  if (json == null) return ResponseBody.fromString('', status, headers: headers);
  return ResponseBody.fromString(
    jsonEncode(json),
    status,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
      ...headers,
    },
  );
}

/// Dio de prueba apuntando a un backend ficticio con HTTPS.
Dio testDio(MockAdapter a) => Dio(BaseOptions(baseUrl: 'https://api.nexo.test'))..httpClientAdapter = a;

/// Problem Details de Nexo.
Map<String, Object?> problem(String code, int status, [String? detail]) =>
    {'type': 'about:blank', 'title': code, 'status': status, 'code': code, 'detail': detail, 'traceId': '00-test'};
