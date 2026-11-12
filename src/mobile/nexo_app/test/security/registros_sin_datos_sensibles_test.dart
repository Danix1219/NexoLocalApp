import 'package:nexo_app/core/local/offline_interceptor.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/core/network/api_exception.dart';

/// Spec 046 · Constitución §6: los registros de depuración no incluyen
/// contraseñas, tokens ni el cuerpo enviado.
void main() {
  test('fallo de Blob no imprime SAS de escritura', () {
    final output = <String>[];
    final previous = debugPrint;
    debugPrint = (String? m, {int? wrapWidth}) => output.add(m ?? '');
    try {
      final o = RequestOptions(path: 'https://storage.test/incoming/u?sig=clave-privada', method: 'PUT');
      ApiException.fromDio(
          DioException(requestOptions: o, message: 'https://storage.test/incoming/u?sig=clave-privada'));
      expect(output.join(), isNot(contains('clave-privada')));
    } finally {
      debugPrint = previous;
    }
  });

  test('búsquedas y mapas no imprimen coordenadas o consultas privadas', () {
    final output = <String>[];
    final previous = debugPrint;
    debugPrint = (String? message, {int? wrapWidth}) => output.add(message ?? '');
    try {
      final o = RequestOptions(
          path: '/v1/discovery/search/providers', queryParameters: {'lat': 20.123456, 'q': 'Calle Privada 123'});
      ApiException.fromDio(DioException(requestOptions: o, message: 'Calle Privada 123'));
      expect(output.join(), isNot(contains('20.123456')));
      expect(output.join(), isNot(contains('Calle Privada')));
      expect(OfflineCacheInterceptor.cacheable(o), false);
    } finally {
      debugPrint = previous;
    }
  });

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

  test('direcciones y coordenadas no aparecen en logs de geocodificación', () {
    final options = RequestOptions(
        path: '/v1/discovery/places/search',
        queryParameters: {'q': 'Calle Privada 123', 'lat': 20.12345, 'lng': -99.12345});
    ApiException.fromDio(DioException(
        requestOptions: options,
        response: Response(requestOptions: options, statusCode: 503, data: {'detail': 'Calle Privada 123'})));
    ApiException.fromDio(DioException(requestOptions: options, message: 'Calle Privada 123'));
    expect(logs.join(' '), isNot(contains('Calle Privada')));
    expect(logs.join(' '), isNot(contains('20.12345')));
    expect(OfflineCacheInterceptor.cacheable(options), isFalse);
    expect(OfflineCacheInterceptor.cacheable(RequestOptions(path: '/v1/discovery/places/reverse', method: 'GET')),
        isFalse);
    expect(
        OfflineCacheInterceptor.cacheable(RequestOptions(path: '/v1/discovery/me/location', method: 'GET')), isFalse);
  });

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
