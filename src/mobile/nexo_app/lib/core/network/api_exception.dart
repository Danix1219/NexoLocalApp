import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// Error de la API normalizado. Lee `code` (Problem Details de Nexo) y, si no
/// existe, `error` (formato OAuth de /connect/token). También entiende el
/// `ValidationProblemDetails` de ASP.NET (`errors: { campo: [mensajes] }`).
class ApiException implements Exception {
  const ApiException({required this.code, this.status, this.detail, this.retryAfter});

  final String code;
  final int? status;
  final String? detail;
  final Duration? retryAfter;

  bool get isNetwork => code == 'network';

  factory ApiException.fromDio(DioException e) {
    final res = e.response;
    final locationRequest = e.requestOptions.uri.path.startsWith('/v1/discovery/') ||
        e.requestOptions.uri.queryParameters.keys.any((k) => k.toLowerCase() == 'sig');
    final safeUri = locationRequest ? e.requestOptions.uri.path : e.requestOptions.uri;

    if (res == null) {
      if (kDebugMode) {
        debugPrint('[API] ${e.requestOptions.method} $safeUri -> '
            'sin respuesta (${e.type.name}): ${locationRequest ? 'ubicación omitida' : e.message}');
      }
      return const ApiException(code: 'network');
    }
    var data = res.data;
    if (data is String && data.trim().startsWith('{')) {
      try {
        data = jsonDecode(data);
      } catch (_) {}
    }
    String? code;
    String? detail;
    if (data is Map) {
      // /connect/token (OpenIddict) manda el código de Nexo en error_uri:
      // {"error":"invalid_grant","error_uri":"nexo:auth.account_locked"}.
      final uri = data['error_uri']?.toString();
      final nexoUri = uri != null && uri.startsWith('nexo:') ? uri.substring(5) : null;
      code = (data['code'] ?? nexoUri ?? data['error'])?.toString();
      detail = (data['detail'] ?? data['error_description'])?.toString();
      final errors = data['errors'];
      if (detail == null && errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        detail = first is List && first.isNotEmpty ? first.first.toString() : first.toString();
      }
      detail ??= data['title']?.toString();
    }
    if (kDebugMode) {
      // Solo en debug y solo la respuesta de error: nunca el cuerpo enviado
      // (podría traer contraseñas).
      debugPrint('[API] ${e.requestOptions.method} $safeUri -> '
          '${res.statusCode} ${locationRequest ? 'ubicación omitida' : data is Map ? jsonEncode(data) : data}');
    }
    final secs = int.tryParse(res.headers.value('retry-after') ?? '');
    return ApiException(
      code: code ?? 'http_${res.statusCode}',
      status: res.statusCode,
      detail: detail,
      retryAfter: secs == null ? null : Duration(seconds: secs),
    );
  }

  @override
  String toString() => 'ApiException($status, $code)';
}
