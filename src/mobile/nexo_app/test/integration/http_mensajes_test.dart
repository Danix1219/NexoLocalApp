import 'dart:convert';
import 'dart:typed_data';
import 'package:nexo_app/core/chat/chat_vault.dart';
import 'package:nexo_app/core/chat/signal_chat_crypto.dart';
import 'package:nexo_app/core/chat/encrypted_chat_transport.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/data/http_nexo_api.dart';

import '../support/mock_adapter.dart';

class UnusedHistoryVault implements ChatVault {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class HistoryCrypto extends SignalChatCrypto {
  HistoryCrypto() : super(UnusedHistoryVault(), 'me', 2);
  @override
  Future<Map<String, dynamic>> decrypt({
    required String conversation,
    required String sender,
    required Map<String, dynamic> envelope,
  }) async {
    if (envelope['messageId'] == 'bad') throw StateError('Invalid ciphertext');
    return {'kind': 'text', 'text': 'Mensaje nuevo', if (envelope['editOf'] != null) 'editOf': envelope['editOf']};
  }
}

class OwnHistoryTransport extends EncryptedChatTransport {
  OwnHistoryTransport(super.dio, super.crypto);
  @override
  Future<Map<String, dynamic>> readOwn(String serverId, String conversation, {String? operationId}) async => {
    'kind': 'text',
    'text': 'Copia local original',
  };
}

class AttachmentHistoryVault implements ChatVault {
  final state = <String, String>{};
  @override
  Future<T> transaction<T>(Future<T> Function(Map<String, String>) operation) => operation(state);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class CaptionTransport extends EncryptedChatTransport {
  CaptionTransport(super.dio, super.crypto);
  int uploads = 0;
  int retries = 0;
  Map<String, dynamic>? content;
  @override
  Future<Map<String, dynamic>> uploadAttachment(String conversation, Uint8List bytes, String type) async {
    uploads++;
    return {'id': 'file', 'type': type};
  }

  @override
  Future<String> send(
    String conversation,
    String peer,
    Map<String, dynamic> content, {
    String? retryId,
    String? editTarget,
  }) async {
    this.content = content;
    return 'confirmed';
  }

  @override
  Future<String> retryPending(String conversation, String peer) async {
    retries++;
    return 'confirmed';
  }
}

/// Spec 040 · grupo `mensajes`.
void main() {
  test('history accepts bound encrypted edits and renders server tombstones', () async {
    final adapter = MockAdapter();
    final dio = testDio(adapter);
    adapter.on('GET', '/v1/engagement/conversations/c/messages', {
      'encrypted': true,
      'peerAccountId': 'peer',
      'items': [
        {'messageId': 'deleted', 'kind': 'deleted', 'mine': false},
        {
          'messageId': 'target',
          'kind': 'encrypted',
          'mine': false,
          'senderId': 'peer',
          'editedAt': '2026-11-19T12:00:00Z',
          'encrypted': {
            'envelopes': [
              {'recipient': 'me', 'recipientDevice': 2, 'messageId': 'edit', 'editOf': 'target'},
            ],
          },
        },
        {
          'messageId': 'wrong-target',
          'kind': 'encrypted',
          'mine': false,
          'senderId': 'peer',
          'editedAt': '2026-11-19T12:00:00Z',
          'encrypted': {
            'envelopes': [
              {'recipient': 'me', 'recipientDevice': 2, 'messageId': 'other-edit', 'editOf': 'target'},
            ],
          },
        },
      ],
    });
    final api = HttpNexoApi(dio, encryptedChat: () async => EncryptedChatTransport(dio, HistoryCrypto()));
    final thread = await api.messages('c');
    expect(thread.messages.where((m) => m.id == 'target').single.text, 'Mensaje nuevo');
    expect(thread.messages.where((m) => m.id == 'target').single.editedAt, isNotNull);
    expect(thread.messages.where((m) => m.id == 'wrong-target').single.kind, 'unavailable');
    expect(thread.messages.where((m) => m.id == 'deleted').single.kind, 'deleted');
  });

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
    a.on('POST', '/v1/engagement/conversations/cnv_1/messages', {
      'messageId': 'm3',
      'kind': 'text',
      'text': 'hola',
      'mine': true,
    });
    a.on('POST', '/v1/engagement/conversations/cnv_1/read', null, status: 204);
    a.on('POST', '/v1/engagement/conversations/cnv_1/block', {'blocked': true});
    await api.sendMessage('cnv_1', text: 'hola');
    expect(a.last('POST', '/v1/engagement/conversations/cnv_1/messages').body, {'kind': 'text', 'text': 'hola'});
    await api.sendMessage('cnv_1', imageUploadId: 'upl_1');
    expect(a.last('POST', '/v1/engagement/conversations/cnv_1/messages').body, {
      'kind': 'image',
      'imageUploadId': 'upl_1',
    });
    await api.markRead('cnv_1', 'm3');
    expect(a.last('POST', '/v1/engagement/conversations/cnv_1/read').body, {'upToMessageId': 'm3'});
    expect(await api.block('cnv_1', true, alsoReport: true), isTrue);
    expect(a.last('POST', '/v1/engagement/conversations/cnv_1/block').body, {'blocked': true, 'alsoReport': true});
  });
  test('chat privado incompatible nunca envia texto por la ruta anterior', () async {
    a.on('GET', '/v1/engagement/conversations/private/messages', {
      'encrypted': true,
      'peerAccountId': 'peer',
      'items': [],
    });
    await expectLater(api.messages('private'), throwsStateError);
    await expectLater(api.sendMessage('private', text: 'Contenido privado'), throwsStateError);
  });
  test('historial privado conserva mensajes nuevos aunque los antiguos no esten disponibles', () async {
    final crypto = HistoryCrypto();
    api = HttpNexoApi(testDio(a), encryptedChat: () async => EncryptedChatTransport(testDio(a), crypto));
    Map<String, dynamic> encrypted(String id, int device) => {
      'messageId': id,
      'kind': 'encrypted',
      'senderId': 'peer',
      'mine': false,
      'encrypted': {
        'envelopes': [
          {'messageId': id, 'recipient': 'me', 'recipientDevice': device},
        ],
      },
    };
    a.on('GET', '/v1/engagement/conversations/c/messages', {
      'encrypted': true,
      'peerAccountId': 'peer',
      'canSend': true,
      'counterpart': {'id': 'peer', 'displayName': 'Contacto'},
      'items': [encrypted('new', 2), encrypted('bad', 2), encrypted('old', 1)],
    });
    final thread = await api.messages('c');
    expect(thread.encrypted, isTrue);
    expect(thread.canSend, isTrue);
    expect(thread.counterpart.displayName, 'Contacto');
    expect(thread.messages.map((m) => m.id), ['old', 'bad', 'new']);
    expect(thread.messages.map((m) => m.kind), ['unavailable', 'unavailable', 'text']);
    expect(thread.messages.last.text, 'Mensaje nuevo');
    expect(thread.messages.first.encryptedPayload, isNotNull);
  });
  test('mensaje propio prioriza copia local original sobre sobre de otro dispositivo', () async {
    api = HttpNexoApi(testDio(a), encryptedChat: () async => OwnHistoryTransport(testDio(a), HistoryCrypto()));
    a.on('GET', '/v1/engagement/conversations/c/messages', {
      'encrypted': true,
      'peerAccountId': 'peer',
      'items': [
        {
          'messageId': 'own',
          'kind': 'encrypted',
          'mine': true,
          'senderId': 'me',
          'encrypted': {
            'envelopes': [
              {'messageId': 'bad', 'recipient': 'me', 'recipientDevice': 2},
            ],
          },
        },
      ],
    });
    final thread = await api.messages('c');
    expect(thread.messages.single.kind, 'text');
    expect(thread.messages.single.text, 'Copia local original');
  });
  test('caption travels inside encrypted attachment content and retries reuse the same pending file', () async {
    final vault = AttachmentHistoryVault();
    final transport = CaptionTransport(testDio(a), SignalChatCrypto(vault, 'me', 1));
    api = HttpNexoApi(testDio(a), encryptedChat: () async => transport);
    a.on('GET', '/v1/engagement/conversations/c/messages', {'encrypted': true, 'peerAccountId': 'peer', 'items': []});
    await api.messages('c');
    final sent = await api.sendPrivateAttachment(
      'c',
      Uint8List.fromList([1, 2]),
      'image/jpeg',
      caption: 'Mi foto',
      clientMessageId: 'local-id',
    );
    expect(sent.text, 'Mi foto');
    expect(transport.content!['text'], 'Mi foto');
    expect(transport.content!['kind'], 'image');
    expect(transport.content!['clientId'], 'local-id');
    vault.state['pending:c'] = jsonEncode({'id': 'operation', 'content': jsonEncode(transport.content)});
    await api.sendPrivateAttachment(
      'c',
      Uint8List.fromList([1, 2]),
      'image/jpeg',
      caption: 'Mi foto',
      clientMessageId: 'local-id',
    );
    expect(transport.uploads, 1);
    expect(transport.retries, 1);
    await expectLater(
      api.sendPrivateAttachment('c', Uint8List.fromList([3]), 'image/jpeg', clientMessageId: 'other'),
      throwsStateError,
    );
    expect(transport.uploads, 1);
  });
  test('entrega usa un acuse explicito distinto de lectura', () async {
    a.on('POST', '/v1/engagement/conversations/c/delivered', {'marked': 1});
    await api.markDelivered('c', 'm');
    expect(a.last('POST', '/v1/engagement/conversations/c/delivered').body, {'upToMessageId': 'm'});
  });
}
