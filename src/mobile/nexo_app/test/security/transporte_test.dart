import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/app/env.dart';

/// Spec 046/048: el APK de release solo habla HTTPS con el backend.
void main() {
  test('release exige https', () {
    expect(Env.isSecureBaseUrl('https://nexolocal.azurewebsites.net', release: true), isTrue);
    expect(Env.isSecureBaseUrl('http://nexolocal.azurewebsites.net', release: true), isFalse);
    expect(Env.isSecureBaseUrl('http://10.0.2.2:8080', release: true), isFalse);
  });

  test('en desarrollo solo http local', () {
    expect(Env.isSecureBaseUrl('http://10.0.2.2:8080', release: false), isTrue);
    expect(Env.isSecureBaseUrl('http://192.168.1.20:8080', release: false), isTrue);
    expect(Env.isSecureBaseUrl('http://api.ejemplo.com', release: false), isFalse);
  });

  test('rechaza credenciales en la URL y valores rotos', () {
    expect(Env.isSecureBaseUrl('https://user:pass@api.nexo.mx', release: true), isFalse);
    expect(Env.isSecureBaseUrl('api.nexo.mx', release: true), isFalse);
    expect(Env.isSecureBaseUrl('', release: true), isFalse);
    expect(Env.isSecureBaseUrl('ftp://api.nexo.mx', release: false), isFalse);
  });
}
