import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/features/intelligence/category_suggester.dart';

/// Spec 049 (función de ML): decisión sobre las etiquetas del modelo de
/// visión, con abstención cuando no hay confianza suficiente.
void main() {
  test('lavabo y llave → plomería con la confianza sumada', () {
    final g = guessFromLabels([('Sink', 0.72), ('Tap', 0.41), ('Room', 0.9)]);
    expect(g, isNotNull);
    expect(g!.category, 'plomeria');
    expect(g.confidence, closeTo(1.0, 1e-9), reason: 'se acota a 1');
    expect(g.labels, ['Sink', 'Tap']);
  });

  test('etiquetas sin relación con servicios → se abstiene', () {
    expect(guessFromLabels([('Dog', 0.95), ('Smile', 0.8)]), isNull);
  });

  test('confianza baja → se abstiene', () {
    expect(guessFromLabels([('Plant', 0.4)]), isNull);
  });

  test('dos categorías empatadas → se abstiene (margen mínimo)', () {
    expect(guessFromLabels([('Lamp', 0.7), ('Wood', 0.65)]), isNull);
  });

  test('ignora mayúsculas y espacios', () {
    expect(guessFromLabels([('  LOCK ', 0.8)])!.category, 'cerrajeria');
  });

  test('allowed limita a las categorías del prestador', () {
    final labels = [('Plant', 0.9), ('Paint', 0.6)];
    expect(guessFromLabels(labels)!.category, 'jardineria');
    expect(guessFromLabels(labels, allowed: {'pintura'})!.category, 'pintura');
  });

  test('valores inválidos del modelo no suman', () {
    expect(guessFromLabels([('Sink', double.nan), ('Sink', -1)]), isNull);
  });

  test('todas las categorías del mapa existen en el catálogo', () {
    const cats = {'plomeria', 'electricidad', 'carpinteria', 'pintura', 'jardineria', 'cerrajeria', 'otros'};
    expect(labelToCategory.values.toSet().difference(cats), isEmpty);
  });
}
