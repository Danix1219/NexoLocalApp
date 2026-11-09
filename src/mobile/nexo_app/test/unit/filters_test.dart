import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/data/models.dart';

/// Spec 029/028: filtros de búsqueda y de oportunidades.
void main() {
  test('SearchFilters cuenta solo lo activo', () {
    const f = SearchFilters();
    expect(f.count, 0);
    final g = f.copyWith(cat: 'plomeria', open: true, sort: 'near');
    expect(g.count, 3);
    expect(g.q, '');
  });

  test('copyWith distingue "no cambiar" de "quitar"', () {
    final f = const SearchFilters().copyWith(cat: 'pintura', attention: 'home');
    expect(f.copyWith(open: true).cat, 'pintura');
    expect(f.copyWith(cat: null).cat, isNull);
    expect(f.copyWith(attention: null).attention, isNull);
  });

  test('OppFilters: fuera de radio cuenta como filtro', () {
    const f = OppFilters();
    expect(f.inRadius, isTrue);
    expect(f.count, 0);
    expect(f.copyWith(inRadius: false).count, 1);
    expect(f.copyWith(today: true, myServiceOnly: true, cat: 'pintura').count, 3);
  });
}
