import 'package:nexo_app/features/publish/publish_page.dart';
import 'package:nexo_app/core/widgets/toast.dart';
import 'package:nexo_app/features/publish/publish_option_row.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:nexo_app/features/auth/application/email_flow.dart';
import 'package:nexo_app/features/auth/data/auth_repository.dart';
import 'package:nexo_app/features/auth/presentation/register_done_page.dart';
import 'package:nexo_app/features/common/cards.dart';
import 'package:nexo_app/features/common/carousel.dart';
import 'package:nexo_app/core/widgets/ui.dart';
import 'package:nexo_app/core/widgets/photo_feedback.dart';
import 'package:nexo_app/features/requests/request_author_page.dart';
import 'package:nexo_app/features/location/location_picker_page.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:nexo_app/app/router.dart';
import 'package:nexo_app/core/auth/session_controller.dart';
import 'package:nexo_app/core/local/sync_controller.dart';
import 'package:nexo_app/features/push/push_controller.dart';
import 'package:nexo_app/features/provider/edit_sheets.dart';
import 'package:nexo_app/data/http_nexo_api.dart';
import '../support/mock_adapter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/core/network/api_exception.dart';
import 'package:nexo_app/core/widgets/nexo_button.dart';
import 'package:nexo_app/core/widgets/nexo_motion.dart';
import 'package:nexo_app/core/widgets/nexo_navigation.dart';
import 'package:nexo_app/data/api_provider.dart';
import 'package:nexo_app/data/models.dart';
import 'package:nexo_app/features/account/my_profile_page.dart';

Widget host(Widget child, {bool reduced = false}) =>
    MaterialApp(home: MediaQuery(data: MediaQueryData(disableAnimations: reduced), child: Scaffold(body: child)));

class DraftBody extends StatefulWidget {
  const DraftBody({super.key});
  @override
  State<DraftBody> createState() => _DraftBodyState();
}

class _DraftBodyState extends State<DraftBody> {
  final controller = TextEditingController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(controller: controller);
}

class TestLocation extends SearchLocationController {
  @override
  SearchLocation build() => const SearchLocation(GeoPoint(20.05, -99.34), 'Zona elegida', 5);
}

class VisualSession extends SessionController {
  @override
  SessionState build() => const SessionState(status: SessionStatus.signedIn, accountId: 'visual', name: 'Cuenta Real');
  @override
  Future<void> setName(String name) async {}
}

class VisualPush extends PushController {
  @override
  PushState build() => const PushState();
  @override
  Future<bool> shouldAsk() async => false;
}

class VisualSync extends SyncController {
  @override
  SyncState build() => const SyncState();
}

class SignedOutVisualSession extends SessionController {
  @override
  SessionState build() => const SessionState.signedOut();
}

class LocationSessionSwitch extends SessionController {
  @override
  SessionState build() => const SessionState(status: SessionStatus.signedIn, accountId: 'location-a');
  void changeAccount() => state = const SessionState(status: SessionStatus.signedIn, accountId: 'location-b');
}

void main() {
  testWidgets('la revision muestra skeleton en avatar y portada sin texto sobre la foto', (tester) async {
    await tester.pumpWidget(host(const Column(children: [
      SizedBox(width: 88, height: 88, child: PhotoProcessingOverlay(circular: true)),
      SizedBox(width: 300, height: 120, child: PhotoProcessingOverlay()),
    ])));
    expect(find.byType(PhotoProcessingOverlay), findsNWidgets(2));
    expect(find.text('Revisando?'), findsNothing);
    await tester.pump(const Duration(milliseconds: 250));
    expect(tester.takeException(), isNull);
  });

  testWidgets('perfil de quien publica muestra solo datos publicos reales', (tester) async {
    const request = ServiceRequest(
        id: 'r-publica',
        category: 'plomeria',
        title: 'Fuga en la cocina',
        description: 'Necesito reparar una fuga',
        zoneLabel: 'Tula, Hidalgo',
        clientName: 'K. D.');
    await tester.pumpWidget(host(const RequestAuthorPage(request: request)));
    expect(find.text('K. D.'), findsOneWidget);
    expect(find.text('Fuga en la cocina'), findsOneWidget);
    expect(find.textContaining('Tula, Hidalgo'), findsOneWidget);
  });

  testWidgets('publicacion extensa muestra texto completo al pulsar Ver mas y se puede contraer', (tester) async {
    final longText = ('Necesito una reparacion detallada en mi domicilio. ' * 14).trim();
    await tester.pumpWidget(
        host(SingleChildScrollView(child: SizedBox(width: 260, child: ExpandablePublicationText(longText)))));
    expect(find.text('Ver m\u00e1s'), findsOneWidget);
    expect(tester.widget<Text>(find.text(longText)).maxLines, 3);
    await tester.tap(find.text('Ver m\u00e1s'));
    await tester.pump();
    expect(tester.widget<Text>(find.text(longText)).maxLines, isNull);
    expect(find.text('Ver menos'), findsOneWidget);
    await tester.ensureVisible(find.text('Ver menos'));
    await tester.tap(find.text('Ver menos'));
    await tester.pump();
    expect(tester.widget<Text>(find.text(longText)).maxLines, 3);
  });

  testWidgets('publicacion breve no ofrece Ver mas', (tester) async {
    await tester.pumpWidget(host(const SizedBox(width: 260, child: ExpandablePublicationText('Texto breve.'))));
    expect(find.text('Ver m\u00e1s'), findsNothing);
  });

  testWidgets('publicación 503 conserva borrador y explica solicitud, no perfil', (tester) async {
    final adapter = MockAdapter()
      ..on('GET', '/v1/discovery/categories', {
        'categories': [
          {'slug': 'plomeria', 'name': 'Plomería', 'icon': 'drop'}
        ]
      })
      ..on('POST', '/v1/discovery/requests',
          problem('server.dependency_unavailable', 503, 'No se pudo comprobar el contenido.'),
          status: 503);
    await tester.pumpWidget(ProviderScope(overrides: [
      sessionProvider.overrideWith(VisualSession.new),
      searchLocationProvider.overrideWith(TestLocation.new),
      apiProvider.overrideWithValue(HttpNexoApi(testDio(adapter))),
    ], child: MaterialApp(scaffoldMessengerKey: rootMessengerKey, home: const Scaffold(body: PublishPage()))));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Elegir'));
    await tester.tap(find.text('Elegir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Plomería'));
    await tester.pumpAndSettle();
    const draft = 'Necesito reparar una fuga en la tubería de la cocina.';
    await tester.enterText(find.byType(TextField).first, draft);
    await tester.pump();
    final publish = tester.widget<NexoButton>(find.byWidgetPredicate((w) => w is NexoButton && w.label == 'Publicar'));
    expect(publish.onPressed, isNotNull);
    publish.onPressed!();
    await tester.pumpAndSettle();
    expect(find.text(draft), findsOneWidget);
    expect(find.textContaining('Tu texto sigue aquí'), findsOneWidget);
    expect(find.textContaining('guardar tu perfil'), findsNothing);
    expect(adapter.calls.where((c) => c.path == '/v1/discovery/requests'), hasLength(1));
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0]) {
    testWidgets('Publicar mantiene columnas alineadas y opciones tocables a $width', (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var taps = 0;
      await tester.pumpWidget(host(Column(children: [
        PublishOptionRow(icon: 'hammer', label: 'Servicio', value: 'Elegir', onTap: () => taps++),
        PublishOptionRow(icon: 'pin', label: 'Ubicación', value: 'Santa María Magdalena, Hidalgo', onTap: () => taps++),
        PublishOptionRow(icon: 'clock', label: '¿Para cuándo?', value: 'Esta semana', onTap: () => taps++),
        PublishOptionRow(icon: 'chat', label: 'Te contactan por', value: 'Solo chat', onTap: () => taps++),
      ])));
      final x = tester.getTopLeft(find.text('Elegir')).dx;
      for (final value in ['Santa María Magdalena, Hidalgo', 'Esta semana', 'Solo chat']) {
        expect(tester.getTopLeft(find.text(value)).dx, closeTo(x, .1));
        await tester.tap(find.text(value));
      }
      expect(x, lessThan(width * .65));
      expect(taps, 3);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('recomendación del trabajo usa POST y DELETE reales y contador del servidor', (tester) async {
    final adapter = MockAdapter()
      ..on('POST', '/v1/discovery/works/w/recommend', {'recommended': true, 'recs': 8})
      ..on('DELETE', '/v1/discovery/works/w/recommend', {'recommended': false, 'recs': 7});
    await tester.pumpWidget(ProviderScope(
        overrides: [
          sessionProvider.overrideWith(VisualSession.new),
          apiProvider.overrideWithValue(HttpNexoApi(testDio(adapter))),
        ],
        child: host(const SingleChildScrollView(
            child: WorkCard(
                work: Work(
                    id: 'w',
                    provider: ProviderMini(id: 'p', name: 'Prestador real'),
                    category: 'plomeria',
                    title: 'Trabajo real',
                    recs: 7))))));
    await tester.tap(find.bySemanticsLabel('Recomendar'));
    await tester.pumpAndSettle();
    expect(adapter.calls.single.method, 'POST');
    await tester.tap(find.bySemanticsLabel('Recomendar'));
    await tester.pumpAndSettle();
    expect(adapter.calls.last.method, 'DELETE');
    expect(tester.takeException(), isNull);
  });

  testWidgets('trabajo sin fotos no inventa carrusel ni imagen demo', (tester) async {
    await tester.pumpWidget(host(const PhotoCarousel(images: [], category: 'plomeria')));
    expect(find.byType(PageView), findsNothing);
    expect(find.byType(NexoImage), findsNothing);
  });

  testWidgets('restaura zona del servidor y limpia la selección al cambiar de cuenta', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    final adapter = MockAdapter();
    adapter.on('GET', '/v1/discovery/me/location', {
      'searchLocation': {'lat': 20.05, 'lng': -99.34},
      'zoneLabel': 'Zona real A',
      'radiusKm': 5
    });
    final container = ProviderContainer(overrides: [
      sessionProvider.overrideWith(LocationSessionSwitch.new),
      apiProvider.overrideWithValue(HttpNexoApi(testDio(adapter)))
    ]);
    await tester.pumpWidget(UncontrolledProviderScope(
        container: container,
        child:
            MaterialApp(home: Consumer(builder: (_, ref, __) => Text(ref.watch(searchLocationProvider).zoneLabel)))));
    await tester.pumpAndSettle();
    expect(find.text('Zona real A'), findsOneWidget);
    expect(container.read(searchLocationProvider).radiusKm, 5);
    adapter.on('GET', '/v1/discovery/me/location', {
      'searchLocation': {'lat': 20.15, 'lng': -99.44},
      'zoneLabel': 'Zona real B',
      'radiusKm': 20
    });
    (container.read(sessionProvider.notifier) as LocationSessionSwitch).changeAccount();
    expect(container.read(searchLocationProvider).hasSelection, isFalse);
    await tester.pumpAndSettle();
    expect(find.text('Zona real A'), findsNothing);
    expect(find.text('Zona real B'), findsOneWidget);
    expect(container.read(searchLocationProvider).point.lat, 20.15);
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    FlutterSecureStorage.setMockInitialValues({});
  });

  for (final signedIn in [true, false]) {
    testWidgets('cuenta creada siempre muestra confirmación con sesión $signedIn', (tester) async {
      final container = ProviderContainer(overrides: [
        sessionProvider.overrideWith(signedIn ? VisualSession.new : SignedOutVisualSession.new),
        searchLocationProvider.overrideWith(TestLocation.new),
      ]);
      container
          .read(signupFlowProvider.notifier)
          .accountCreated(const CreatedAccount(name: 'Nueva Cuenta', nextStep: 'home', tokens: null));
      final router = container.read(routerProvider);
      router.go(signedIn ? Routes.home : Routes.registerDone);
      await tester
          .pumpWidget(UncontrolledProviderScope(container: container, child: MaterialApp.router(routerConfig: router)));
      await tester.pumpAndSettle();
      expect(find.byType(RegisterDonePage), findsOneWidget);
      expect(find.textContaining('Tu cuenta está lista'), findsOneWidget);
      expect(find.text(signedIn ? 'Empezar a explorar' : 'Iniciar sesión'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      router.dispose();
      container.dispose();
    });
  }

  testWidgets('dirección real elegida devuelve coordenadas y no asigna el centro inicial', (tester) async {
    final adapter = MockAdapter();
    adapter.on('GET', '/v1/discovery/places/search', {
      'items': [
        {'lat': 20.0489, 'lng': -99.3729, 'label': 'Tula de Allende, Hidalgo', 'zoneLabel': 'Tula de Allende, Hidalgo'}
      ]
    });
    LocationPick? selected;
    await tester.pumpWidget(ProviderScope(
        overrides: [apiProvider.overrideWithValue(HttpNexoApi(testDio(adapter)))],
        child: MaterialApp(
            home: Builder(
                builder: (context) => Scaffold(
                    body: TextButton(
                        child: const Text('Elegir'),
                        onPressed: () async {
                          selected = await Navigator.of(context).push<LocationPick>(
                              MaterialPageRoute(builder: (_) => const LocationPickerPage(args: LocationPickerArgs())));
                        }))))));
    await tester.tap(find.text('Elegir'));
    await tester.pumpAndSettle();
    expect(
        tester
            .widget<NexoButton>(find.byWidgetPredicate((w) => w is NexoButton && w.label == 'Usar esta ubicación'))
            .onPressed,
        isNull);
    await tester.enterText(find.byType(TextField), 'Tula de Allende');
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Tula de Allende, Hidalgo'));
    await tester.tap(find.text('Tula de Allende, Hidalgo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Usar esta ubicación'));
    await tester.pumpAndSettle();
    expect(selected!.point.lat, 20.0489);
    expect(selected!.point.lng, -99.3729);
    expect(selected!.source, 'search');
    expect(selected!.zoneLabel, 'Tula de Allende, Hidalgo');
    expect(adapter.last('GET', '/v1/discovery/places/search').query['q'], 'Tula de Allende');
    expect(tester.takeException(), isNull);
  });

  testWidgets('falla de geocodificación muestra aviso y conserva selección manual', (tester) async {
    final adapter = MockAdapter();
    adapter.on('GET', '/v1/discovery/places/search', {'code': 'server.dependency_unavailable'}, status: 503);
    adapter.on('GET', '/v1/discovery/places/reverse', {'place': null});
    await tester.pumpWidget(ProviderScope(overrides: [
      apiProvider.overrideWithValue(HttpNexoApi(testDio(adapter)))
    ], child: const MaterialApp(home: LocationPickerPage(args: LocationPickerArgs(initial: GeoPoint(20.05, -99.34))))));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Una dirección');
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No pudimos buscar direcciones.'), findsOneWidget);
    expect(
        tester
            .widget<NexoButton>(find.byWidgetPredicate((w) => w is NexoButton && w.label == 'Usar esta ubicación'))
            .onPressed,
        isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('feed ocupa todo el ancho con imagen cuadrada como la maqueta', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(ProviderScope(
        child: host(const SingleChildScrollView(
            child: WorkCard(
                work: Work(
      id: 'visual-work',
      provider: ProviderMini(id: 'provider', name: 'Prestador'),
      category: 'plomeria',
      title: 'Trabajo publicado',
      images: [Img('demo://plomeria/0')],
    ))))));
    await tester.pumpAndSettle();
    final image = tester.getSize(find.byType(PhotoCarousel));
    expect(image.width, 390);
    expect(image.height, image.width);
    expect(find.text('Contactar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la cabecera permanece fija al desplazar el contenido', (tester) async {
    await tester.pumpWidget(host(PinnedHeaderList(children: [
      const ScreenTitleBar('Cabecera fija'),
      for (var i = 0; i < 30; i++) SizedBox(height: 80, child: Text('Fila $i')),
    ])));
    final position = tester.getTopLeft(find.text('Cabecera fija'));
    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(find.text('Cabecera fija')), position);
    expect(find.text('Fila 0').hitTestable(), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('fuentes reales registran cinco pesos sin usar el valor variable 200', (tester) async {
    final manifest = jsonDecode(await rootBundle.loadString('FontManifest.json')) as List;
    for (final family in ['NunitoSans', 'PlusJakartaSans']) {
      final entry = manifest.cast<Map<String, dynamic>>().singleWhere((e) => e['family'] == family);
      final faces = (entry['fonts'] as List).cast<Map<String, dynamic>>();
      expect(faces.map((f) => f['weight']).toList(), [400, 500, 600, 700, 800]);
      for (final face in faces) {
        expect((await rootBundle.load(face['asset'] as String)).lengthInBytes, greaterThan(10000));
      }
    }
  });

  for (final width in [320.0, 390.0]) {
    testWidgets('Cuenta abre Mi perfil con una sola barra a $width px', (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const account = AccountScreen(name: 'Cuenta Real', emailVerified: true);
      final container = ProviderContainer(overrides: [
        sessionProvider.overrideWith(VisualSession.new),
        pushProvider.overrideWith(VisualPush.new),
        syncProvider.overrideWith(VisualSync.new),
        accountProvider.overrideWith((ref) async => account),
        myProviderProvider.overrideWith((ref) async => null),
        searchLocationProvider.overrideWith(TestLocation.new),
        myRequestsProvider.overrideWith((ref) async => const <ServiceRequest>[]),
        savedProvider.overrideWith((ref) async => throw const ApiException(code: 'http_404', status: 404)),
        inboxProvider.overrideWith((ref, role) async => (const <Conversation>[], 0)),
      ]);
      final router = container.read(routerProvider);
      router.go(Routes.account);
      await tester
          .pumpWidget(UncontrolledProviderScope(container: container, child: MaterialApp.router(routerConfig: router)));
      await tester.pumpAndSettle();
      expect(find.byType(NexoNavigation), findsOneWidget);
      await tester.tap(find.text('Ver perfil'));
      await tester.pumpAndSettle();
      expect(find.byType(MyProfilePage), findsOneWidget);
      expect(find.byType(NexoNavigation), findsOneWidget);
      expect(find.text('Inicio'), findsOneWidget);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 300));
      await tester.pumpAndSettle();
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 600));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar datos de mi perfil'));
      await tester.pumpAndSettle();
      expect(find.text('Tu cuenta'), findsOneWidget);
      expect(find.text('Guardar'), findsOneWidget);
      router.pop();
      await tester.pumpAndSettle();
      router.pop();
      await tester.pumpAndSettle();
      expect(find.byType(MyProfilePage), findsNothing);
      expect(find.byType(NexoNavigation), findsOneWidget);
      final selection = router.push<LocationPick>(Routes.location);
      await tester.pumpAndSettle();
      expect(find.byType(LocationPickerPage), findsOneWidget);
      expect(tester.getSize(find.byType(LocationPickerPage)).height, lessThan(844));
      await tester.tap(find
          .descendant(of: find.byType(LocationPickerPage), matching: find.bySemanticsLabel('Cerrar ubicación'))
          .last);
      await tester.pumpAndSettle();
      expect(await selection, isNull);
      expect(find.byType(NexoNavigation), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
      router.dispose();
      container.dispose();
    });
  }

  testWidgets('pulsacion cancela el efecto sin ejecutar la accion', (tester) async {
    var calls = 0;
    await tester.pumpWidget(host(NexoButton(label: 'Guardar', onPressed: () => calls++)));
    final gesture = await tester.startGesture(tester.getCenter(find.text('Guardar')));
    await tester.pump();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, .98);
    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    expect(calls, 0);
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(calls, 1);
  });

  testWidgets('boton deshabilitado no se comprime ni ejecuta acciones', (tester) async {
    await tester.pumpWidget(host(const NexoButton(label: 'Guardar', onPressed: null)));
    final gesture = await tester.startGesture(tester.getCenter(find.text('Guardar')));
    await tester.pump();
    expect(tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale, 1);
    await gesture.cancel();
  });

  testWidgets('movimiento reducido omite entrada y escala pero conserva la accion', (tester) async {
    var calls = 0;
    await tester
        .pumpWidget(host(NexoEnter(child: NexoButton(label: 'Continuar', onPressed: () => calls++)), reduced: true));
    expect(tester.widget<Opacity>(find.byType(Opacity).first).opacity, 1);
    final gesture = await tester.startGesture(tester.getCenter(find.text('Continuar')));
    await tester.pump();
    final scale = tester.widget<AnimatedScale>(find.byType(AnimatedScale));
    expect(scale.scale, 1);
    expect(scale.duration, Duration.zero);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(calls, 1);
  });

  testWidgets('reanimar una pestaña conserva el borrador del formulario', (tester) async {
    await tester.pumpWidget(host(const NexoEnter(trigger: 0, child: DraftBody())));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Mi solicitud sin publicar');
    await tester.pumpWidget(host(const NexoEnter(trigger: 1, child: DraftBody())));
    await tester.pumpAndSettle();
    expect(find.text('Mi solicitud sin publicar'), findsOneWidget);
  });

  testWidgets('barra accesible navega a la opcion seleccionada en pantalla estrecha', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    int? selected;
    await tester.pumpWidget(host(Align(
        alignment: Alignment.bottomCenter,
        child: NexoNavigation(current: 0, onSelected: (index) => selected = index))));
    final semantics = tester.ensureSemantics();
    final node = tester.getSemantics(find.bySemanticsLabel('Cuenta'));
    expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    node.owner!.performAction(node.id, SemanticsAction.tap);
    semantics.dispose();
    await tester.pumpAndSettle();
    expect(selected, 4);
    expect(tester.takeException(), isNull);
  });

  testWidgets('barra comparte cinco destinos y conserva el contador real', (tester) async {
    int? selected;
    await tester.pumpWidget(host(Align(
        alignment: Alignment.bottomCenter,
        child: NexoNavigation(current: 4, unread: 3, onSelected: (index) => selected = index))));
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Cuenta'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();
    expect(selected, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('perfil muestra nombre real y proximamente sin inventar actividad', (tester) async {
    const account = AccountScreen(name: 'Cuenta Real', email: 'cuenta@example.test', emailVerified: true);
    var edits = 0;
    await tester.pumpWidget(ProviderScope(overrides: [
      accountProvider.overrideWith((ref) async => account),
      searchLocationProvider.overrideWith(TestLocation.new),
      myRequestsProvider.overrideWith((ref) async => throw const ApiException(code: 'http_404', status: 404)),
      savedProvider.overrideWith((ref) async => throw const ApiException(code: 'http_404', status: 404)),
    ], child: MaterialApp(home: MyProfilePage(initial: account, onEdit: (_) => edits++))));
    await tester.pumpAndSettle();
    expect(find.text('Cuenta Real'), findsOneWidget);
    expect(find.text('Correo verificado'), findsOneWidget);
    await tester.tap(find.text('Editar datos de mi perfil'));
    await tester.pumpAndSettle();
    expect(edits, 1);
    expect(find.text('—'), findsNWidgets(3));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -450));
    await tester.pumpAndSettle();
    expect(find.text('Próximamente'), findsOneWidget);
    await tester.tap(find.text('Experiencias').last);
    await tester.pumpAndSettle();
    expect(find.text('Aquí aparecerán tus experiencias con los prestadores.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('carrusel de solicitud muestra contador actualizado', (tester) async {
    await tester.pumpWidget(host(const SizedBox(
        width: 320,
        child: PhotoCarousel(
          category: 'plomeria',
          images: [Img('demo://plomeria/0'), Img('demo://plomeria/1'), Img('demo://plomeria/2')],
        ))));
    expect(find.text('1/3'), findsOneWidget);
    expect(find.byTooltip('Foto anterior'), findsNothing);
    expect(find.byTooltip('Foto siguiente'), findsNothing);
    await tester.drag(find.byType(PageView), const Offset(-270, 0));
    await tester.pumpAndSettle();
    expect(find.text('2/3'), findsOneWidget);
    await tester.drag(find.byType(PageView), const Offset(-270, 0));
    await tester.pumpAndSettle();
    expect(find.text('3/3'), findsOneWidget);
  });

  test('solicitud decodifica varias fotos y conserva imagen antigua', () {
    const base = {'requestId': 'r1', 'category': 'plomeria', 'title': 'Fuga', 'description': 'Texto'};
    final multi = ServiceRequest.fromJson({
      ...base,
      'imageUrls': ['https://test/1', 'https://test/2'],
      'contact': 'chatCall'
    });
    expect(multi.photos, ['https://test/1', 'https://test/2']);
    expect(multi.contact, 'chatCall');
    final legacy = ServiceRequest.fromJson({...base, 'imageUrl': 'https://test/old'});
    expect(legacy.photos, ['https://test/old']);
  });

  test('editar trabajo envía PATCH con el texto y las imágenes', () async {
    final adapter = MockAdapter();
    adapter.on('PATCH', '/v1/discovery/works/w1', {
      'workId': 'w1',
      'category': 'plomeria',
      'title': 'Trabajo nuevo',
      'text': 'Descripción completa del trabajo',
      'images': <Object>[],
    });
    final api = HttpNexoApi(testDio(adapter));
    const original = Work(
        id: 'w1', provider: ProviderMini(id: 'p1', name: 'Persona'), category: 'plomeria', title: 'Trabajo anterior');
    final updated = await api.editWork(original,
        title: 'Trabajo nuevo',
        text: 'Descripción completa del trabajo',
        tag: 'Finalizado',
        imageUploadIds: ['a', 'b']);
    expect(updated.title, 'Trabajo nuevo');
    expect(adapter.last('PATCH', '/v1/discovery/works/w1').body, {
      'title': 'Trabajo nuevo',
      'text': 'Descripción completa del trabajo',
      'tag': 'Finalizado',
      'imageUploadIds': ['a', 'b'],
    });
  });

  test('editar solicitud envía PATCH con todas las fotos', () async {
    final adapter = MockAdapter();
    adapter.on('PATCH', '/v1/discovery/requests/r1', {
      'requestId': 'r1',
      'category': 'plomeria',
      'title': 'Título nuevo',
      'description': 'Descripción actualizada',
      'imageUrls': <String>[],
    });
    final api = HttpNexoApi(testDio(adapter));
    await api.editRequest('r1',
        title: 'Título nuevo',
        description: 'Descripción actualizada',
        urgency: 'week',
        contact: 'chat',
        imageUploadIds: ['a', 'b']);
    expect(adapter.last('PATCH', '/v1/discovery/requests/r1').body, {
      'title': 'Título nuevo',
      'description': 'Descripción actualizada',
      'urgency': 'week',
      'contact': 'chat',
      'imageUploadIds': ['a', 'b'],
    });
  });

  testWidgets('editar nombre envía basic sin biografía de otra sección', (tester) async {
    final adapter = MockAdapter();
    adapter.on('PATCH', '/v1/discovery/providers/me/basic', {'providerId': 'real'});
    await tester.pumpWidget(ProviderScope(
        overrides: [apiProvider.overrideWithValue(HttpNexoApi(testDio(adapter)))],
        child: MaterialApp(
            home: Consumer(
                builder: (context, ref, _) => Scaffold(
                        body: TextButton(
                      onPressed: () => showBasicSheet(
                          context,
                          ref,
                          const ProviderProfile(
                              id: 'real', name: 'Nombre Real', bio: 'Descripción real del servicio.')),
                      child: const Text('Editar'),
                    ))))));
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    expect(find.text('Acerca de ti'), findsNothing);
    await tester.enterText(find.byType(TextField).first, 'Nombre Editado');
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    expect(adapter.last('PATCH', '/v1/discovery/providers/me/basic').body, {'name': 'Nombre Editado'});
    expect(tester.takeException(), isNull);
  });
  testWidgets('condiciones conserva slugs reales al guardar sin editar', (tester) async {
    final adapter = MockAdapter();
    adapter.on('PATCH', '/v1/discovery/providers/me/terms', {'providerId': 'real'});
    await tester.pumpWidget(ProviderScope(
        overrides: [apiProvider.overrideWithValue(HttpNexoApi(testDio(adapter)))],
        child: MaterialApp(
            home: Consumer(
                builder: (context, ref, _) => Scaffold(
                        body: TextButton(
                      onPressed: () => showTermsEditSheet(
                          context,
                          ref,
                          const ProviderProfile(
                              id: 'real', name: 'Nombre Real', payment: ['cash', 'transfer'], responseTime: 'sameDay')),
                      child: const Text('Condiciones'),
                    ))))));
    await tester.tap(find.text('Condiciones'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Guardar'));
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();
    final body = adapter.last('PATCH', '/v1/discovery/providers/me/terms').body as Map;
    expect(body['payment'], ['cash', 'transfer']);
    expect(body['responseTime'], 'sameDay');
    expect(body['invoice'], isFalse);
    expect(tester.takeException(), isNull);
  });
}
