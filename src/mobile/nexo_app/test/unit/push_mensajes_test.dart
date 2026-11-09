import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/features/push/push_gateway.dart';

/// Spec 050: lectura del aviso push (`deepLink` del contrato de notificaciones).
void main() {
  test('usa deepLink del contrato', () {
    final m = PushMessage.fromData({'deepLink': 'nexolocal://orders/ord_1', 'title': 'Pedido aceptado'});
    expect(m.link, 'nexolocal://orders/ord_1');
    expect(m.title, 'Pedido aceptado');
  });

  test('acepta link como respaldo y prioriza la notificación visible', () {
    final m = PushMessage.fromData({'link': 'nexolocal://chat/c1', 'title': 'x'}, title: 'Nuevo mensaje', body: 'Laura te escribió');
    expect(m.link, 'nexolocal://chat/c1');
    expect(m.title, 'Nuevo mensaje');
    expect(m.body, 'Laura te escribió');
  });

  test('sin datos no falla', () {
    final m = PushMessage.fromData(const {});
    expect(m.link, isNull);
    expect(m.title, isNull);
  });

  test('sin Firebase configurado el proveedor vacío no rompe', () async {
    const g = NoPushGateway();
    expect(await g.init(), isFalse);
    expect(await g.token(), isNull);
    expect(await g.initialMessage(), isNull);
  });
}
