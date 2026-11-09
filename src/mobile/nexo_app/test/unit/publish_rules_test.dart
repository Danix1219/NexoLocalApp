import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/features/publish/publish_page.dart';

/// Spec 035/036: título automático a partir del texto.
void main() {
  test('toma la primera frase', () {
    expect(autoTitle('Fuga en el baño. Necesito que vengan hoy'), 'Fuga en el baño');
  });
  test('vacío y espacios', () {
    expect(autoTitle('   '), '');
  });
  test('primera frase muy corta usa el texto completo', () {
    expect(autoTitle('Ay. Se tapó el drenaje de la cocina'), 'Ay. Se tapó el drenaje de la cocina');
  });
  test('recorta a 90 caracteres con elipsis', () {
    final t = autoTitle('a' * 200);
    expect(t.length, lessThanOrEqualTo(90));
    expect(t.endsWith('…'), isTrue);
  });
}
