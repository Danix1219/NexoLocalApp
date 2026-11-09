import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/core/network/api_exception.dart';

import '../support/fake_api.dart';

/// Spec 040: conversaciones, envío, leídos y bloqueo.
void main() {
  late FakeSession s;
  setUp(() => s = FakeSession());

  test('bandeja demo con no leídos', () async {
    final (list, unread) = await s.api.conversations(role: 'client');
    expect(list, isNotEmpty);
    expect(unread, greaterThanOrEqualTo(1));
  });

  test('abrir la misma conversación no duplica', () async {
    final a = await s.api.openConversation(providerId: 'p3');
    final b = await s.api.openConversation(providerId: 'p3');
    expect(a, b);
  });

  test('enviar mensaje y marcar leído', () async {
    final id = await s.api.openConversation(providerId: 'p4');
    final m = await s.api.sendMessage(id, text: 'Hola, ¿cuándo podrías venir?');
    expect(m.mine, isTrue);
    final t = await s.api.messages(id);
    expect(t.messages.last.text, contains('cuándo'));
    await s.api.markRead(id, m.id);
    final (list, _) = await s.api.conversations(role: 'client');
    expect(list.firstWhere((c) => c.id == id).unread, 0);
  });

  test('conversación bloqueada no permite enviar', () async {
    final id = await s.api.openConversation(providerId: 'p5');
    expect(await s.api.block(id, true), isTrue);
    final t = await s.api.messages(id);
    expect(t.canSend, isFalse);
    await expectLater(s.api.sendMessage(id, text: 'hola'), throwsA(isA<ApiException>()));
    expect(await s.api.block(id, false), isFalse);
  });
}
