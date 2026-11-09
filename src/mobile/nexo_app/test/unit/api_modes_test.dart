import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/core/network/api_exception.dart';
import 'package:nexo_app/data/api_provider.dart';
import 'package:nexo_app/data/nexo_api.dart';

/// Spec 045: selección de modo por grupo y clasificación de fallas.
void main() {
  group('groupModes', () {
    test('de fábrica todo en auto', () {
      final m = groupModes(mode: 'auto', live: '', fake: '');
      expect(m.values.toSet(), {GroupMode.auto});
      expect(m.length, ApiGroup.values.length);
    });
    test('LIVE y FAKE fuerzan grupos', () {
      final m = groupModes(mode: 'auto', live: 'cuenta, perfil', fake: 'mensajes');
      expect(m[ApiGroup.cuenta], GroupMode.live);
      expect(m[ApiGroup.perfil], GroupMode.live);
      expect(m[ApiGroup.mensajes], GroupMode.fake);
      expect(m[ApiGroup.pedidos], GroupMode.auto);
    });
    test('all y modo global', () {
      expect(groupModes(mode: 'auto', live: 'all', fake: '').values.toSet(), {GroupMode.live});
      expect(groupModes(mode: 'fake', live: '', fake: '').values.toSet(), {GroupMode.fake});
      expect(groupModes(mode: 'LIVE', live: '', fake: '').values.toSet(), {GroupMode.live});
    });
    test('auth no es un grupo de esta capa', () {
      expect(groupModes(mode: 'auto', live: 'auth', fake: '').values.toSet(), {GroupMode.auto});
    });
  });

  group('isUnavailable', () {
    test('sin señal, ruta inexistente y 5xx sin código: no disponible', () {
      expect(isUnavailable(const ApiException(code: 'network')), isTrue);
      expect(isUnavailable(const ApiException(code: 'http_404', status: 404)), isTrue);
      expect(isUnavailable(const ApiException(code: 'http_405', status: 405)), isTrue);
      expect(isUnavailable(const ApiException(code: 'http_501', status: 501)), isTrue);
      expect(isUnavailable(const ApiException(code: 'http_503', status: 503)), isTrue);
      expect(isUnavailable(const ApiException(code: 'client.unexpected_response')), isTrue);
      expect(isUnavailable(const FormatException('html')), isTrue);
    });
    test('errores de negocio de Nexo sí se muestran', () {
      expect(isUnavailable(const ApiException(code: 'provider.not_found', status: 404)), isFalse);
      expect(isUnavailable(const ApiException(code: 'order.version_conflict', status: 412)), isFalse);
      expect(isUnavailable(const ApiException(code: 'order.already_active', status: 409)), isFalse);
      expect(isUnavailable(const ApiException(code: 'http_401', status: 401)), isFalse);
      expect(isUnavailable(const ApiException(code: 'http_403', status: 403)), isFalse);
      expect(isUnavailable(const ApiException(code: 'http_400', status: 400)), isFalse);
      expect(isUnavailable(const ApiException(code: 'server.error', status: 500)), isFalse);
      expect(isUnavailable(StateError('bug')), isFalse);
    });
  });
}
