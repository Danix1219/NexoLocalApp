import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/core/auth/auth_tokens.dart';
import 'package:nexo_app/core/network/api_exception.dart';
import 'package:nexo_app/features/auth/presentation/auth_messages.dart';

String _jwt(Map<String, dynamic> claims) {
  String part(Object o) => base64Url.encode(utf8.encode(jsonEncode(o))).replaceAll('=', '');
  return '${part({'alg': 'ES256'})}.${part(claims)}.firma';
}

DioException _error(int status, Object data, {Map<String, List<String>>? headers}) {
  final req = RequestOptions(path: '/x');
  return DioException(
    requestOptions: req,
    response: Response(
      requestOptions: req,
      statusCode: status,
      data: data,
      headers: Headers.fromMap(headers ?? {}),
    ),
  );
}

void main() {
  group('TokenClaims', () {
    test('lee sub, mode y has_provider', () {
      final c = TokenClaims.decode(_jwt({'sub': 'abc', 'mode': 'provider', 'has_provider': true}));
      expect(c.sub, 'abc');
      expect(c.mode, 'provider');
      expect(c.hasProvider, isTrue);
    });
    test('un token ilegible no truena y queda en modo cliente', () {
      final c = TokenClaims.decode('basura');
      expect(c.mode, 'client');
      expect(c.hasProvider, isFalse);
    });
  });

  group('ApiException', () {
    test('usa code de Problem Details', () {
      final e = ApiException.fromDio(_error(400, {'code': 'email.code_invalid'}));
      expect(e.code, 'email.code_invalid');
      expect(e.status, 400);
    });
    test('cae a error OAuth y lee Retry-After', () {
      final e = ApiException.fromDio(_error(
        423,
        {'error': 'auth.account_locked'},
        headers: {
          'retry-after': ['600']
        },
      ));
      expect(e.code, 'auth.account_locked');
      expect(e.retryAfter, const Duration(minutes: 10));
      expect(authErrorMessage(e), contains('10 minutos'));
    });
    test('lee el código de Nexo en error_uri de /connect/token', () {
      final e = ApiException.fromDio(_error(400, {
        'error': 'invalid_grant',
        'error_uri': 'nexo:auth.account_locked',
      }));
      expect(e.code, 'auth.account_locked');
    });
    test('sin respuesta es error de red', () {
      final e = ApiException.fromDio(DioException(requestOptions: RequestOptions(path: '/x')));
      expect(e.isNetwork, isTrue);
    });
  });

  test('credenciales inválidas: un solo mensaje (sin enumeración)', () {
    const a = ApiException(code: 'auth.invalid_credentials', status: 401);
    const b = ApiException(code: 'invalid_grant', status: 400);
    expect(authErrorMessage(a), authErrorMessage(b));
  });
}
