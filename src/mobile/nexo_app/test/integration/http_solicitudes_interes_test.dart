import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/data/http_nexo_api.dart';
import 'package:nexo_app/data/models.dart';

import '../support/fixtures.dart';
import '../support/mock_adapter.dart';

/// Specs 035/038/036 · grupos `solicitudes`, `interes` y `trabajos`.
void main() {
  late MockAdapter a;
  late HttpNexoApi api;
  setUp(() {
    a = MockAdapter();
    api = HttpNexoApi(testDio(a));
  });

  test('POST /v1/discovery/requests con Idempotency-Key', () async {
    a.on('POST', '/v1/discovery/requests', Fx.request(id: 'req_9'), status: 201);
    final r = await api.createRequest(
      category: 'plomeria',
      title: 'Fuga',
      description: 'Fuga debajo del lavabo, el piso está mojado.',
      urgency: 'today',
      contact: 'chat',
      location: const GeoPoint(20.05, -99.34),
      idempotencyKey: 'idem-req',
    );
    expect(r.id, 'req_9');
    expect(r.mine, isTrue);
    final c = a.last('POST', '/v1/discovery/requests');
    expect(c.header('Idempotency-Key'), 'idem-req');
    expect((c.body as Map)['urgency'], 'today');
    expect((c.body as Map).containsKey('imageUploadId'), isFalse);
  });

  test('mis solicitudes y oportunidades', () async {
    a.on('GET', '/v1/discovery/requests/mine', Fx.page([Fx.request(mine: true)]));
    a.on('GET', '/v1/discovery/requests/opportunities', Fx.page([Fx.request()]));
    expect((await api.myRequests()).single.mine, isTrue);
    final o = await api.opportunities(const OppFilters(q: 'fuga', today: true, myServiceOnly: true));
    expect(o.single.matchesMyService, isTrue);
    final q = a.last('GET', '/v1/discovery/requests/opportunities').query;
    expect(q['today'], 'true');
    expect(q['inRadius'], 'true');
    expect(q['myServiceOnly'], 'true');
    expect(q['q'], 'fuga');
  });

  test('cerrar solicitud con resultado', () async {
    a.on('POST', '/v1/discovery/requests/req_1/close', {'status': 'closed'});
    await api.closeRequest('req_1', outcome: 'solvedHere', pickedProviderId: 'prv_1');
    expect(a.last('POST', '/v1/discovery/requests/req_1/close').body,
        {'outcome': 'solvedHere', 'pickedProviderId': 'prv_1'});
  });

  test('interés: POST con nota y DELETE para retirar', () async {
    a.on('POST', '/v1/engagement/requests/req_1/interest', {'interested': true}, status: 201);
    a.on('DELETE', '/v1/engagement/requests/req_1/interest', null, status: 204);
    await api.setInterest('req_1', true, note: 'Puedo hoy');
    expect(a.last('POST', '/v1/engagement/requests/req_1/interest').body, {'note': 'Puedo hoy'});
    await api.setInterest('req_1', false);
    expect(a.calls.last.method, 'DELETE');
  });

  test('interesados ordenados', () async {
    a.on('GET', '/v1/engagement/requests/req_1/interested', {
      ...Fx.page([
        {
          ...Fx.provider(),
          'note': 'Puedo hoy',
          'conversationId': 'cnv_1',
          'actions': {'canMessage': true, 'canOrder': true}
        },
      ]),
      'requestTitle': 'Fuga',
      'requestStatus': 'open',
    });
    final p = await api.interested('req_1', sort: 'recs');
    expect(p.title, 'Fuga');
    expect(p.items.single.note, 'Puedo hoy');
    expect(p.items.single.canOrder, isTrue);
    expect(a.last('GET', '/v1/engagement/requests/req_1/interested').query['sort'], 'recs');
  });

  test('trabajos: publicar, recomendar y borrar', () async {
    a.on('POST', '/v1/discovery/works', Fx.work(id: 'wrk_9'), status: 201);
    a.on('POST', '/v1/discovery/works/wrk_9/recommend', {'recommended': true, 'recs': 13});
    a.on('DELETE', '/v1/discovery/works/wrk_9', null, status: 204);
    final w = await api.createWork(
      category: 'plomeria',
      title: 'Cambio de llave',
      text: 'Sustituimos la llave de la cocina y sellamos la fuga.',
      location: const GeoPoint(20.05, -99.34),
      imageUploadIds: ['upl_1'],
    );
    expect(w.id, 'wrk_9');
    expect(a.last('POST', '/v1/discovery/works').header('Idempotency-Key'), isNotEmpty);
    final r = await api.recommend(w, true);
    expect(r.recommended, isTrue);
    expect(r.recs, 13);
    await api.deleteWork('wrk_9');
  });
}
