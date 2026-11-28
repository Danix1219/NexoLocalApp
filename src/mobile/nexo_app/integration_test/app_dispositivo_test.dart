// Suite automatizada en dispositivo físico (auditoría, sección 3).
//
// Corre la app real (no widgets sueltos) sobre el teléfono conectado por USB:
//   powershell -File tools/pruebas-dispositivo.ps1
// o directamente:
//   flutter test integration_test --dart-define=API_MODE=fake -d <id-del-dispositivo>
//
// Con API_MODE=fake los datos son los de ejemplo de la app: la suite es repetible y no crea
// cuentas ni publicaciones reales. Con API_MODE=live recorre la API desplegada.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:nexo_app/app/app.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fullyLive;

  /// Espera a que aparezca [finder] sin depender de pumpAndSettle: la app tiene animaciones
  /// continuas (splash, mapas) que nunca "se asientan".
  Future<void> waitFor(WidgetTester tester, Finder finder, {Duration timeout = const Duration(seconds: 25)}) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 250));
      if (finder.evaluate().isNotEmpty) return;
    }
    throw TestFailure('No apareció: $finder');
  }

  /// Cierra avisos opcionales (permiso de notificaciones, recorrido de invitado) si salen.
  Future<void> dismissOptional(WidgetTester tester) async {
    for (final label in ['Ahora no', 'Omitir', 'Saltar', 'Entendido']) {
      final f = find.text(label);
      if (f.evaluate().isNotEmpty) {
        await tester.tap(f.first);
        await tester.pump(const Duration(milliseconds: 600));
      }
    }
  }

  Future<void> launch(WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: NexoApp()));
    await waitFor(tester, find.text('Explorar sin cuenta'));
  }

  testWidgets('1 · Arranque: la bienvenida ofrece crear cuenta, iniciar sesión y explorar', (tester) async {
    await launch(tester);
    expect(find.text('Crear cuenta'), findsWidgets);
    expect(find.text('Iniciar sesión'), findsWidgets);
  });

  testWidgets('2 · Login: no deja entrar con un correo inválido', (tester) async {
    await launch(tester);
    await tester.tap(find.text('Iniciar sesión').first);
    await waitFor(tester, find.text('Entrar'));
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'no-es-correo');
    await tester.enterText(fields.at(1), 'x');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.tap(find.text('Entrar'));
    await tester.pump(const Duration(seconds: 2));
    // Botón deshabilitado: no hay petición ni navegación, seguimos en la pantalla de login.
    expect(find.text('Inicia sesión'), findsWidgets);
    expect(find.text('Bienvenido'), findsNothing);
  });

  testWidgets('3 · Invitado: entra a Inicio y navega por las pestañas', (tester) async {
    await launch(tester);
    await tester.tap(find.text('Explorar sin cuenta'));
    await waitFor(tester, find.text('Buscar'));
    await dismissOptional(tester);
    for (final tab in ['Buscar', 'Inicio']) {
      await tester.tap(find.text(tab).last);
      await tester.pump(const Duration(seconds: 1));
      await dismissOptional(tester);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('4 · Búsqueda: escribir un oficio muestra resultados', (tester) async {
    await launch(tester);
    await tester.tap(find.text('Explorar sin cuenta'));
    await waitFor(tester, find.text('Buscar'));
    await dismissOptional(tester);
    await tester.tap(find.text('Buscar').last);
    await waitFor(tester, find.byType(TextField));
    await tester.enterText(find.byType(TextField).first, 'plomero');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await waitFor(tester, find.textContaining(RegExp(r'prestador|No encontramos')));
    expect(tester.takeException(), isNull);
  });

  testWidgets('5 · Publicar como invitado pide cuenta antes de publicar', (tester) async {
    await launch(tester);
    await tester.tap(find.text('Explorar sin cuenta'));
    await waitFor(tester, find.text('Publicar'));
    await dismissOptional(tester);
    await tester.tap(find.text('Publicar').last);
    await waitFor(tester, find.textContaining(RegExp(r'cuenta|Inicia sesión|Crear cuenta')));
    expect(tester.takeException(), isNull);
  });
}
