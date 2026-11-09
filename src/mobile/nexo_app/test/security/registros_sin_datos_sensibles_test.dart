import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/core/network/api_exception.dart';

/// Spec 046 · Constitución §6: los registros de depuración no incluyen
/// contraseñas, tokens ni el cuerpo enviado.
void main() {
  late List<String> logs;
  late DebugPrintCallback original;

  setUp(() {
    logs = [];
    original = debugPrint;
    debugPrint = (String? m, {int? wrapWidth}) => logs.add(m ?? '');
  });
  tearDown(() => debugPrint = original);

  DioException fail(int? status, Object? data) {
    final req = RequestOptions(
      path: '/connect/token',
      method: 'POST',
      baseUrl: 'https://api.nexo.test',
      data: {'username': 'ana@x.mx', 'password': 'Secreto2026'},
      headers: {'Authorization': 'Bearer eyJhbGciOi.secreto.firma'},
    );
    return DioException(
      requestOptions: req,
      response: status == null ? null : Response(requestOptions: req, statusCode: status, data: data),
      type: status == null ? DioExceptionType.connectionError : DioExceptionType.badResponse,
    );
  }

  test('error con respuesta', () {
    ApiException.fromDio(fail(400, {'error': 'invalid_grant', 'error_uri': 'nexo:auth.invalid_credentials'}));
    final all = logs.join('\n');
    expect(all, isNot(contains('Secreto2026')));
    expect(all, isNot(contains('Bearer')));
    expect(all, isNot(contains('ana@x.mx')));
  });

  test('error sin red', () {
    ApiException.fromDio(fail(null, null));
    final all = logs.join('\n');
    expect(all, isNot(contains('Secreto2026')));
    expect(all, isNot(contains('Bearer')));
  });

  test('toString de la excepción no expone el detalle', () {
    const e = ApiException(code: 'auth.invalid_credentials', status: 401, detail: 'Usuario ana@x.mx bloqueado');
    expect(e.toString(), isNot(contains('ana@x.mx')));
  });
}
