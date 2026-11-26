import 'package:nexo_app/features/common/actions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/app/router.dart';

/// Spec 043/046 · H: un aviso o enlace no puede llevar fuera de la app ni a
/// rutas no previstas.
void main() {
  test('shared profiles and publications use only real application routes', () {
    expect(shareableAppLink('/p/profile-id'), 'nexolocal://provider/profile-id');
    final work = shareableAppLink('/provider/profile-id/work/work-id');
    expect(work, 'nexolocal://provider/profile-id/work/work-id');
    expect(Routes.fromDeepLink(work), '/provider/profile-id/work/work-id');
    expect(shareableAppLink('/w/work-id'), isNull);
    expect(shareableAppLink('https://nexolocal.mx/p/id'), isNull);
    expect(Routes.fromDeepLink('nexolocal://provider/id/unexpected/path'), isNull);
  });
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
