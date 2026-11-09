import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/core/network/api_exception.dart';

import '../support/fake_api.dart';

/// Specs 041/044/042: cuenta, modo prestador, celular, baja y guardados.
void main() {
  late FakeSession s;
  setUp(() => s = FakeSession());

  test('no se cambia a prestador sin perfil', () async {
    await expectLater(
      s.api.switchMode('provider'),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'mode.provider_profile_required')),
    );
  });

  test('alta de prestador deja perfil incompleto con pendientes', () async {
    expect(await s.api.myProvider(), isNull);
    await s.becomeProvider();
    final me = await s.api.myProvider();
    expect(me, isNotNull);
    expect(me!.completeness, inInclusiveRange(1, 99));
    expect(me.todo.any((t) => t.key == 'hours' && !t.done), isTrue);
    expect(await s.api.switchMode('provider'), isNull, reason: 'en modo de prueba el modo se guarda en el teléfono');
  });

  test('editar horario completa ese pendiente', () async {
    await s.becomeProvider();
    await s.api.patchProvider('hours', {
      'schedule': {
        'days': [
          {'open': '09:00', 'close': '18:00'},
          null,
          null,
          null,
          null,
          null,
          null,
        ],
        'urgent': true,
      },
    });
    final me = await s.api.myProvider();
    expect(me!.todo.firstWhere((t) => t.key == 'hours').done, isTrue);
    expect(me.profile.urgent, isTrue);
  });

  test('celular: se enmascara y el código es de 6 dígitos', () async {
    final masked = await s.api.addPhone('+527715550123');
    expect(masked, endsWith('0123'));
    expect(masked, isNot(contains('771555')));
    await expectLater(s.api.confirmPhone('12'), throwsA(isA<ApiException>()));
    await s.api.confirmPhone('123456');
    expect((await s.api.accountScreen()).phoneVerified, isTrue);
  });

  test('eliminación con contraseña y cancelación', () async {
    await expectLater(s.api.requestDeletion(password: 'x'), throwsA(isA<ApiException>()));
    await s.api.requestDeletion(password: 'Nexo2026ok');
    expect((await s.api.accountScreen()).pendingDeletion, isTrue);
    await s.api.cancelDeletion();
    expect((await s.api.accountScreen()).pendingDeletion, isFalse);
  });

  test('guardar y quitar actualiza los conteos', () async {
    var c = await s.api.setSaved('provider', 'p1', true);
    expect(c.provider, 1);
    c = await s.api.setSaved('work', 'w1', true);
    expect(c.total, 2);
    final (items, _) = await s.api.saved();
    expect(items.map((i) => i.targetId), containsAll(['p1', 'w1']));
    c = await s.api.setSaved('provider', 'p1', false);
    expect(c.provider, 0);
  });

  test('notificaciones demo y marcar leídas', () async {
    final (list, unread) = await s.api.notifications();
    expect(unread, list.length);
    await s.api.markNotificationsRead([list.first.id]);
    final (_, after) = await s.api.notifications();
    expect(after, unread - 1);
  });
}
