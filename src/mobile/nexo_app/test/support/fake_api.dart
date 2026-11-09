import 'package:nexo_app/data/fake/fake_nexo_api.dart';
import 'package:nexo_app/data/models.dart';
import 'package:nexo_app/data/nexo_api.dart';

const centro = GeoPoint(20.0535, -99.3425);

/// API de la maqueta con una sesión controlada por la prueba.
class FakeSession {
  String name = 'Ana Demo';
  String mode = 'client';
  final events = <String>[];
  late final api = FakeNexoApi(FakeContext(name: () => name, mode: () => mode, notify: events.add));

  /// Crea el perfil de prestador de la cuenta y cambia a modo prestador.
  Future<void> becomeProvider({String cat = 'plomeria'}) async {
    final d = ProviderDraft()
      ..kind = 'trade'
      ..name = 'Luis Demo'
      ..bio = 'Plomero con experiencia en fugas y boilers.'
      ..categories = [cat]
      ..location = centro
      ..radiusKm = 10
      ..acceptedRules = true;
    await api.createProvider(d, idempotencyKey: 'idem-test');
    mode = 'provider';
  }
}
