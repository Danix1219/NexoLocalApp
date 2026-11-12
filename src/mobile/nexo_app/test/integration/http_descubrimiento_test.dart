import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/data/http_nexo_api.dart';
import 'package:nexo_app/data/models.dart';

import '../support/fixtures.dart';
import '../support/mock_adapter.dart';

/// Specs 027/029/030 · grupo `descubrimiento`.
void main() {
  test('catálogo usa categories y especialidades reales del servidor', () async {
    final adapter = MockAdapter()
      ..on('GET', '/v1/discovery/categories', {
        'categories': [
          {
            'slug': 'plomeria',
            'name': 'Plomería',
            'icon': 'drop',
            'gradient': {'from': '#123456', 'to': '#654321'},
            'specialties': [
              {'slug': 'fugas', 'name': 'Fugas'}
            ]
          }
        ],
        'version': '2026-11-10'
      });
    final c = (await HttpNexoApi(testDio(adapter)).categories()).single;
    expect(c.slug, 'plomeria');
    expect(c.specialties.single.slug, 'fugas');
    expect(c.c1, '#123456');
  });

  late MockAdapter a;
  late HttpNexoApi api;
  const at = GeoPoint(20.05, -99.34);
  setUp(() {
    a = MockAdapter();
    api = HttpNexoApi(testDio(a));
  });

  test('feed paginado por cursor', () async {
    a.on('GET', '/v1/discovery/feed', {
      ...Fx.page([Fx.work()], next: 'c2'),
      'zoneLabel': 'Centro'
    });
    final f = await api.feed(at: at);
    expect(f.zoneLabel, 'Centro');
    expect(f.page.items.single.id, 'wrk_1');
    expect(f.page.hasMore, isTrue);
    expect(f.page.nextCursor, 'c2');
    final q = a.last('GET', '/v1/discovery/feed').query;
    expect(q['limit'], '20');
    expect(q.containsKey('cursor'), isFalse, reason: 'sin cursor no se manda vacío');
  });

  test('búsqueda manda solo los filtros activos', () async {
    a.on('GET', '/v1/discovery/search/providers', {
      ...Fx.page([Fx.provider()]),
      'total': 1,
      'outOfZone': false
    });
    final r = await api.searchProviders(
      const SearchFilters(q: ' fuga ', cat: 'plomeria', open: true, sort: 'near'),
      at: at,
      radiusKm: 10,
    );
    expect(r.items.single.id, 'prv_1');
    final q = a.last('GET', '/v1/discovery/search/providers').query;
    expect(q['q'], 'fuga');
    expect(q['cat'], 'plomeria');
    expect(q['open'], 'true');
    expect(q['sort'], 'near');
    expect(q.containsKey('free'), isFalse);
    expect(q.containsKey('attention'), isFalse);
  });

  test('aviso fuera de zona', () async {
    a.on('GET', '/v1/discovery/search/providers', {
      ...Fx.page([]),
      'outOfZone': true,
      'notice': {'text': 'Nadie atiende tu zona'},
    });
    final r = await api.searchProviders(const SearchFilters(), at: at, radiusKm: 10);
    expect(r.outOfZone, isTrue);
    expect(r.notice, 'Nadie atiende tu zona');
  });

  test('sugerencias, categorías y mapa', () async {
    a.on('GET', '/v1/discovery/search/suggest', {
      'suggestions': [
        {'kind': 'category', 'slug': 'plomeria', 'label': 'Plomería'},
      ],
    });
    a.on('GET', '/v1/discovery/categories', {
      'categories': [
        {
          'slug': 'plomeria',
          'name': 'Plomería',
          'icon': 'drop',
          'gradient': {'from': '#46A3F0', 'to': '#2B72D1'}
        },
      ]
    });
    a.on('GET', '/v1/discovery/map/nearby', {
      'summary': {'text': '3 prestadores'},
      'points': [
        {
          'id': 'prv_1',
          'point': {'lat': 20.05, 'lng': -99.34},
          'state': 'open',
          'title': 'Hernández'
        },
      ],
    });
    expect((await api.suggest('plo', at: at)).single.slug, 'plomeria');
    expect((await api.categories()).single.c1, '#46A3F0');
    final m = await api.mapNearby(at: at, radiusKm: 5, kind: 'providers');
    expect(m.summary, '3 prestadores');
    expect(m.points.single.state, 'open');
    expect(a.last('GET', '/v1/discovery/map/nearby').query['kind'], 'providers');
  });

  test('PUT /v1/discovery/me/location', () async {
    a.on('PUT', '/v1/discovery/me/location', {
      'zoneLabel': 'Jardines',
      'radiusKm': 5,
      'summary': {'text': '8 prestadores'}
    });
    final r = await api.setLocation(at, radiusKm: 5, source: 'gps');
    expect(r.zoneLabel, 'Jardines');
    expect(
        a.last('PUT', '/v1/discovery/me/location').body, {'lat': 20.05, 'lng': -99.34, 'radiusKm': 5, 'source': 'gps'});
  });
}
