import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/core/network/api_exception.dart';
import 'package:nexo_app/features/intelligence/assist_sheet.dart';
import 'package:nexo_app/features/intelligence/redact.dart';

/// Spec 049 / 013: la IA generativa no recibe teléfono, correo, enlaces ni
/// domicilio; un rechazo de moderación o el asistente caído no se ocultan.
void main() {
  test('quita teléfonos con y sin formato', () {
    expect(redactForAssist('Llámame al 771 123 4567 o al +52 (771) 555-12-34'), isNot(contains(RegExp(r'\d{3}'))));
    expect(redactForAssist('mi cel 7711234567'), 'mi cel [teléfono]');
  });

  test('conserva cantidades cortas que no son teléfonos', () {
    expect(redactForAssist('Son 2 llaves y 3 metros de tubo'), 'Son 2 llaves y 3 metros de tubo');
  });

  test('quita correos y enlaces', () {
    final r = redactForAssist('Escríbeme a ana.m+obra@correo.mx o ve https://mi-sitio.mx/x y www.otra.com');
    expect(r, isNot(contains('@')));
    expect(r, isNot(contains('http')));
    expect(r, isNot(contains('www.')));
    expect(r, contains('[correo]'));
    expect(r, contains('[enlace]'));
  });

  test('quita domicilios con calle y número', () {
    final r = redactForAssist('Vivo en Calle Hidalgo #45, cerca del centro. Fuga en Av. Juárez 120B.');
    expect(r, isNot(contains('Hidalgo')));
    expect(r, isNot(contains('120B')));
    expect(r, contains('[domicilio]'));
    expect(r, contains('cerca del centro'));
  });

  test('texto sin datos personales queda igual', () {
    const t = 'Gotea la llave del lavabo desde ayer y el piso está húmedo.';
    expect(redactForAssist(t), t);
  });

  test('moderación y asistente caído tienen mensaje claro', () {
    expect(assistErrorMessage(const ApiException(code: 'content.inappropriate', status: 403)),
        contains('reglas de la comunidad'));
    expect(
        assistErrorMessage(const ApiException(code: 'assist.unavailable', status: 503)), contains('escribir tu texto'));
    expect(assistErrorMessage(const ApiException(code: 'network')), contains('escribir tu texto'));
    expect(assistErrorMessage(const ApiException(code: 'x', status: 429)), contains('muchas veces'));
  });
}
