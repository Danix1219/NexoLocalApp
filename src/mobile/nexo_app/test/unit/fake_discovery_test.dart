import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/data/models.dart';

import '../support/fake_api.dart';

/// Specs 027/029/030/033: descubrimiento con los datos de la maqueta.
void main() {
  late FakeSession s;
  setUp(() => s = FakeSession());

  test('feed del Centro trae trabajos con prestador', () async {
    final f = await s.api.feed(at: centro);
    expect(f.zoneLabel, 'Centro');
    expect(f.page.items, isNotEmpty);
    expect(f.page.items.every((w) => w.provider.name.isNotEmpty), isTrue);
  });

  test('buscar "fuga" encuentra plomeros', () async {
    final r = await s.api.searchProviders(const SearchFilters(q: 'fuga'), at: centro, radiusKm: 10);
    expect(r.items, isNotEmpty);
    expect(r.items.every((p) => p.categories.contains('plomeria')), isTrue);
  });

  test('filtro "en su local" excluye a quien solo va a domicilio', () async {
    final r = await s.api.searchProviders(const SearchFilters(cat: 'cerrajeria', attention: 'shop'), at: centro, radiusKm: 10);
    expect(r.items, isNotEmpty);
    expect(r.items.any((p) => p.attention == 'home'), isFalse);
  });

  test('orden por recomendaciones', () async {
    final r = await s.api.searchProviders(const SearchFilters(sort: 'recs', expanded: true), at: centro, radiusKm: 20);
    final recs = r.items.map((p) => p.recs).toList();
    expect(recs, [...recs]..sort((a, b) => b.compareTo(a)));
  });

  test('sugerencias por categoría y especialidad', () async {
    final sg = await s.api.suggest('plom', at: centro);
    expect(sg.any((x) => x.kind == 'category' && x.slug == 'plomeria'), isTrue);
    expect(await s.api.suggest('  ', at: centro), isEmpty);
  });

  test('comparar marca al mejor en recomendaciones', () async {
    final c = await s.api.compare(['p1', 'p2']);
    expect(c.providers, hasLength(2));
    final recs = c.rows.firstWhere((r) => r.key == 'recs');
    expect(recs.best, 0);
  });

  test('mapa cercano de prestadores y de solicitudes', () async {
    final p = await s.api.mapNearby(at: centro, radiusKm: 10, kind: 'providers');
    expect(p.points, isNotEmpty);
    final r = await s.api.mapNearby(at: centro, radiusKm: 10, kind: 'requests');
    expect(r.points.every((x) => x.id.startsWith('r')), isTrue);
  });

  test('cambiar ubicación recalcula la zona', () async {
    final l = await s.api.setLocation(const GeoPoint(20.0790, -99.3300), radiusKm: 5);
    expect(l.zoneLabel, 'Jardines');
    expect(l.radiusKm, 5);
  });
}
