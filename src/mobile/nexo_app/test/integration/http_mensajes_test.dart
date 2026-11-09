import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/data/http_nexo_api.dart';

import '../support/mock_adapter.dart';

/// Spec 040 · grupo `mensajes`.
void main() {
  late MockAdapter a;
  late HttpNexoApi api;
  setUp(() {
    a = MockAdapter();
    api = HttpNexoApi(testDio(a));
  });

  test('bandeja por rol con total sin leer', () async {
    a.on('GET', '/v1/engagement/conversations', {
      'items': [
        {
          'conversationId': 'cnv_1',
          'counterpart': {'id': 'prv_1', 'displayName': 'Hernández', 'kind': 'provider'},
          'lastPreview': 'Hola',
          'unread': 2,
        },
      ],
      'totalUnread': 2,
    });
    final (list, unread) = await api.conversations(role: 'client', filter: 'unread');
    expect(unread, 2);
    expect(list.single.counterpart.providerId, 'prv_1');
    expect(a.last('GET', '/v1/engagement/conversations').query['filter'], 'unread');
  });

  test('abrir conversación con prestador', () async {
    a.on('POST', '/v1/engagement/conversations', {'conversationId': 'cnv_7'}, status: 201);
    expect(await api.openConversation(providerId: 'prv_1'), 'cnv_7');
    expect(a.last('POST', '/v1/engagement/conversations').body, {'providerId': 'prv_1'});
  });

  test('historial llega del más nuevo al más viejo y se invierte', () async {
    a.on('GET', '/v1/engagement/conversations/cnv_1/messages', {
      'items': [
        {'messageId': 'm2', 'kind': 'text', 'text': 'segundo', 'mine': true, 'createdAt': '2026-11-06T18:01:00Z'},
        {'messageId': 'm1', 'kind': 'text', 'text': 'primero', 'mine': false, 'createdAt': '2026-11-06T18:00:00Z'},
      ],
      'counterpart': {'id': 'prv_1', 'displayName': 'Hernández', 'kind': 'provider'},
      'canSend': true,
      'quickReplies': ['¿Cuánto cuesta?'],
    });
    final t = await api.messages('cnv_1');
    expect(t.messages.map((m) => m.id), ['m1', 'm2']);
    expect(t.quickReplies.single, '¿Cuánto cuesta?');
  });

  test('enviar texto o imagen, leer y bloquear', () async {
    a.on('POST', '/v1/engagement/conversations/cnv_1/messages',
        {'messageId': 'm3', 'kind': 'text', 'text': 'hola', 'mine': true});
    a.on('POST', '/v1/engagement/conversations/cnv_1/read', null, status: 204);
    a.on('POST', '/v1/engagement/conversations/cnv_1/block', {'blocked': true});
    await api.sendMessage('cnv_1', text: 'hola');
    expect(a.last('POST', '/v1/engagement/conversations/cnv_1/messages').body, {'kind': 'text', 'text': 'hola'});
    await api.sendMessage('cnv_1', imageUploadId: 'upl_1');
    expect(a.last('POST', '/v1/engagement/conversations/cnv_1/messages').body,
        {'kind': 'image', 'imageUploadId': 'upl_1'});
    await api.markRead('cnv_1', 'm3');
    expect(a.last('POST', '/v1/engagement/conversations/cnv_1/read').body, {'upToMessageId': 'm3'});
    expect(await api.block('cnv_1', true, alsoReport: true), isTrue);
    expect(a.last('POST', '/v1/engagement/conversations/cnv_1/block').body, {'blocked': true, 'alsoReport': true});
  });
}
