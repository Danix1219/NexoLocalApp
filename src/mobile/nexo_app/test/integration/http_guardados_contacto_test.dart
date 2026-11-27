import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/data/http_nexo_api.dart';

import '../support/fixtures.dart';
import '../support/mock_adapter.dart';

/// Specs 042/034/043 · grupos `guardados`, `contacto` y `notificaciones`.
void main() {
  late MockAdapter a;
  late HttpNexoApi api;
  setUp(() {
    a = MockAdapter();
    api = HttpNexoApi(testDio(a));
  });

  test('guardados con tipos mezclados y conteos', () async {
    a.on('GET', '/v1/discovery/saved', {
      'items': [
        {'kind': 'provider', 'targetId': 'prv_1', 'provider': Fx.provider()},
        {'kind': 'work', 'targetId': 'wrk_x', 'available': false},
      ],
      'counts': {'provider': 1, 'work': 1, 'request': 0},
    });
    final (items, counts) = await api.saved();
    expect(items.first.provider!.name, 'Hernández Plomería');
    expect(items.last.available, isFalse);
    expect(counts.total, 2);
  });

  test('saved publications keep author data, saved state and later pages', () async {
    a.onRaw(
      'GET',
      '/v1/discovery/saved',
      (o) => jsonBody({
        'counts': {'work': 2},
        'items': [
          {
            'kind': 'work',
            'targetId': 'w',
            'work': {
              ...Fx.work(),
              'provider': {'providerId': 'p', 'name': 'Autor real', 'photoUrl': 'https://media.test/avatar.webp'},
            },
          },
        ],
        'hasMore': o.queryParameters['cursor'] == null,
        'nextCursor': o.queryParameters['cursor'] == null ? 'next' : null,
      }),
    );
    final (items, counts) = await api.saved();
    expect(items, hasLength(2));
    expect(items.first.work!.provider.name, 'Autor real');
    expect(items.first.work!.provider.photoUrl, 'https://media.test/avatar.webp');
    expect(items.first.work!.saved, isTrue);
    expect(counts.total, 2);
  });

  test('shared client profile uses a resolvable random id, not private account data', () async {
    const id = 'a98cb637-4cc0-4ab5-bd27-c5bfa3cedb63';
    a.on('POST', '/v1/identity/me/profile-share', {'shareId': id});
    a.on('GET', '/v1/identity/profiles/$id', {'name': 'Solicitante', 'photoUrl': null});
    expect(await api.shareProfile(), 'nexolocal://profile/$id');
    expect((await api.sharedProfile(id))['name'], 'Solicitante');
  });

  test('guardar y quitar con POST/DELETE /saved/{kind}/{id}', () async {
    a.on('POST', '/v1/discovery/saved/provider/prv_1', {
      'savedCounts': {'provider': 1},
    });
    a.on('DELETE', '/v1/discovery/saved/provider/prv_1', {
      'savedCounts': {'provider': 0},
    });
    expect((await api.setSaved('provider', 'prv_1', true)).provider, 1);
    expect((await api.setSaved('provider', 'prv_1', false)).provider, 0);
  });

  test('ver número y reportar', () async {
    a.on('POST', '/v1/engagement/contacts/phone', {'displayPhone': '771 555 0101', 'targetName': 'Hernández'});
    a.on('POST', '/v1/engagement/reports', {'message': 'Recibimos tu reporte.'}, status: 201);
    final r = await api.revealPhone(targetId: 'prv_1', targetType: 'provider', context: 'profile');
    expect(r.displayPhone, '771 555 0101');
    final msg = await api.report(
      targetType: 'work',
      targetId: 'wrk_1',
      category: 'scam',
      reason: 'Pide anticipo por fuera',
    );
    expect(msg, 'Recibimos tu reporte.');
    final c = a.last('POST', '/v1/engagement/reports');
    expect(c.header('Idempotency-Key'), isNotEmpty);
    expect((c.body as Map)['category'], 'scam');
  });

  test('notificaciones y marcar leídas', () async {
    a.on('GET', '/v1/engagement/notifications', {
      'items': [
        {'notificationId': 'n1', 'title': 'Te hicieron un pedido', 'deepLink': 'nexolocal://orders/ord_1'},
      ],
      'unreadCount': 1,
    });
    a.on('POST', '/v1/engagement/notifications/read', null, status: 204);
    final (list, unread) = await api.notifications();
    expect(unread, 1);
    expect(list.single.read, isFalse);
    await api.markNotificationsRead(['n1']);
    expect(a.last('POST', '/v1/engagement/notifications/read').body, {
      'notificationIds': ['n1'],
    });
  });
}
