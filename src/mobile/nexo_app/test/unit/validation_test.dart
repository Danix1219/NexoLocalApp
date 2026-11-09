import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/core/validation.dart';

void main() {
  group('pwOk (regla pwOK de la maqueta y del contrato)', () {
    test('acepta 8+ caracteres con letra y número', () {
      expect(pwOk('Nexo2026ok'), isTrue);
      expect(pwOk('abcdefg1'), isTrue);
    });
    test('rechaza cortas, sin número, sin letra o de más de 64', () {
      expect(pwOk('abc123'), isFalse);
      expect(pwOk('abcdefgh'), isFalse);
      expect(pwOk('12345678'), isFalse);
      expect(pwOk('a1${'x' * 63}'), isFalse);
    });
  });

  group('correo', () {
    test('normaliza a minúsculas y sin espacios', () {
      expect(normalizeEmail('  Ana.Lopez@Example.COM '), 'ana.lopez@example.com');
    });
    test('valida formato básico', () {
      expect(emailOk('ana@example.com'), isTrue);
      expect(emailOk('ana@example'), isFalse);
      expect(emailOk('ana example.com'), isFalse);
    });
  });

  test('nombre: mínimo 2, no solo dígitos', () {
    expect(personNameOk('Ana'), isTrue);
    expect(personNameOk(' A '), isFalse);
    expect(personNameOk('12345'), isFalse);
  });

  test('código: exactamente 6 dígitos', () {
    expect(codeOk('481902'), isTrue);
    expect(codeOk('48190'), isFalse);
    expect(codeOk('48a902'), isFalse);
  });
}
