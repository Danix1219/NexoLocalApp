import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Spec 046 · Constitución §6: sin secretos ni URLs inseguras en el código.
void main() {
  final files = Directory('lib')
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  test('hay código que revisar', () => expect(files, isNotEmpty));

  final patterns = <String, RegExp>{
    'llave privada': RegExp(r'-----BEGIN [A-Z ]*PRIVATE KEY-----'),
    'Google API key': RegExp(r'AIza[0-9A-Za-z\-_]{35}'),
    'token de GitHub': RegExp(r'gh[pousr]_[0-9A-Za-z]{30,}'),
    'llave de AWS': RegExp(r'AKIA[0-9A-Z]{16}'),
    'JWT incrustado': RegExp(r'eyJ[A-Za-z0-9_-]{10,}\.eyJ[A-Za-z0-9_-]{10,}\.'),
    'cadena de conexión': RegExp(r'(AccountKey|SharedAccessKey|Password)=', caseSensitive: false),
    'contraseña asignada': RegExp(r'''(password|contrasena|secret)\s*[:=]\s*['"][^'"]{6,}['"]''', caseSensitive: false),
  };

  for (final e in patterns.entries) {
    test('sin ${e.key}', () {
      final hits = [
        for (final f in files)
          if (e.value.hasMatch(f.readAsStringSync())) f.path,
      ];
      expect(hits, isEmpty);
    });
  }

  test('solo HTTPS, salvo el localhost del emulador como valor de desarrollo', () {
    final http = RegExp(r'''['"]http://([^'"/:]+)''');
    // www.w3.org es el espacio de nombres XML de los íconos SVG (no hay red).
    const allowed = {'10.0.2.2', 'localhost', '127.0.0.1', 'www.w3.org'};
    final hits = <String>[];
    for (final f in files) {
      for (final m in http.allMatches(f.readAsStringSync())) {
        if (!allowed.contains(m.group(1))) hits.add('${f.path}: ${m.group(0)}');
      }
    }
    expect(hits, isEmpty);
  });

  test('no se imprime con print() (solo debugPrint en debug)', () {
    final hits = [
      for (final f in files)
        if (RegExp(r'(^|[^\w.])print\(').hasMatch(f.readAsStringSync())) f.path,
    ];
    expect(hits, isEmpty);
  });
}
