import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/app/router.dart';

/// Spec 043/046 · H: un aviso o enlace no puede llevar fuera de la app ni a
/// rutas no previstas.
void main() {
  test('acepta el esquema propio hacia secciones conocidas', () {
    expect(Routes.fromDeepLink('nexolocal://orders/ord_1'), '/orders/ord_1');
    expect(Routes.fromDeepLink('nexolocal://requests/ra1/interested'), '/requests/ra1/interested');
    expect(Routes.fromDeepLink('/chat/cnv_9'), '/chat/cnv_9');
  });

  test('rechaza otros esquemas, hosts y rutas', () {
    for (final bad in [
      'https://evil.example/orders/1',
      'http://nexolocal.mx/orders/1',
      'javascript:alert(1)',
      '//evil.example/orders/1',
      'nexolocal://admin/users',
      'nexolocal://orders/../account',
      'nexolocal://orders/1%2F..',
      'nexolocal://orders/<script>',
      'nexolocal://orders//1',
      '',
      null,
      'nexolocal://orders/${'a' * 300}',
    ]) {
      expect(Routes.fromDeepLink(bad), isNull, reason: '$bad');
    }
  });
}
