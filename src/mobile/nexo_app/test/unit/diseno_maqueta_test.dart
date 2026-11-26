import 'package:nexo_app/features/shell/guest_tour.dart';
import 'package:nexo_app/features/common/publication_actions_ui.dart';
import 'package:nexo_app/features/messages/voice_composer.dart';
import 'package:nexo_app/features/provider/hours_sheet.dart';
import 'package:go_router/go_router.dart';
import 'package:nexo_app/features/requests/interested_page.dart' as interested_ui;
import 'package:nexo_app/features/provider/compare_page.dart';
import 'package:nexo_app/features/provider/provider_page.dart';
import 'package:nexo_app/features/common/request_editor.dart';
import 'package:nexo_app/core/widgets/map_view.dart';
import 'package:nexo_app/features/search/search_page.dart';
import 'package:nexo_app/features/common/actions.dart';
import 'package:nexo_app/features/messages/chat_message_actions.dart';
import 'package:nexo_app/features/messages/chat_backdrop.dart';
import 'package:nexo_app/core/network/api_client.dart';
import 'dart:io';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:ui' as ui;
import 'dart:async';
import 'package:nexo_app/features/messages/chat_experience.dart';
import 'package:nexo_app/features/messages/chat_page.dart';
import 'package:nexo_app/features/messages/private_chat_media.dart';
import 'package:nexo_app/core/chat/chat_vault.dart';
import 'package:nexo_app/data/nexo_api.dart';
import 'package:nexo_app/features/messages/inbox_page.dart';
import 'package:nexo_app/features/messages/message_receipt.dart';
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
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:nexo_app/features/intelligence/category_suggester.dart';
import 'package:nexo_app/features/intelligence/ml_kit_suggester.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_app/core/network/api_exception.dart';
import 'package:nexo_app/core/widgets/nexo_button.dart';
import 'package:nexo_app/core/widgets/nexo_motion.dart';
import 'package:nexo_app/core/widgets/nexo_navigation.dart';
import 'package:nexo_app/data/api_provider.dart';
import 'package:nexo_app/data/models.dart';
import 'package:nexo_app/features/account/my_profile_page.dart';

Widget host(Widget child, {bool reduced = false}) => MaterialApp(
  home: MediaQuery(
    data: MediaQueryData(disableAnimations: reduced),
    child: Scaffold(body: child),
  ),
);

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

class FakeVoiceCapture implements VoiceCapture {
  StreamController<Uint8List>? _audio;
  void speak(int bytes) => _audio?.add(Uint8List(bytes));
  @override
  Future<bool> hasPermission() async => true;
  @override
  Future<Stream<Uint8List>> start() async => (_audio = StreamController<Uint8List>(sync: true)).stream;
  @override
  Future<void> pause() async {}
  @override
  Future<void> resume() async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}
}

class DeniedVoiceCapture extends FakeVoiceCapture {
  int starts = 0;
  bool released = false;
  @override
  Future<bool> hasPermission() async => false;
  @override
  Future<Stream<Uint8List>> start() {
    starts++;
    return super.start();
  }

  @override
  Future<void> dispose() async => released = true;
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

class DeletingSession extends VisualSession {
  static int signOuts = 0;
  @override
  Future<void> signOutLocal() async => signOuts++;
}

class RecoverySession extends VisualSession {
  @override
  SessionState build() =>
      const SessionState(status: SessionStatus.signedIn, accountId: 'visual', name: 'Cuenta Real', recoveryOnly: true);
}

class GuestVisualSession extends SessionController {
  @override
  SessionState build() => const SessionState.guest();
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

class MemoryChatHistory implements ChatVault {
  final values = <String, String>{};
  @override
  Future<T> transaction<T>(Future<T> Function(Map<String, String>) operation) => operation(values);
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class OptimisticChatApi implements NexoApi {
  Completer<Message>? gate;
  bool fail = false;
  int sends = 0;
  String? caption;
  String? clientId;
  final history = <Message>[];
  ChatThread get thread => ChatThread(
    id: 'c',
    counterpart: const Counterpart(id: 'peer', displayName: 'Contacto'),
    messages: List.of(history),
    encrypted: true,
  );
  @override
  Future<ChatThread> messages(String id, {String? before}) async => thread;
  @override
  Future<Message> sendMessage(String id, {String? text, String? imageUploadId}) async {
    sends++;
    if (fail) throw StateError('Network unavailable');
    if (gate != null) return gate!.future;
    final message = Message(id: 'server-$sends', kind: 'text', text: text ?? '', mine: true);
    history.add(message);
    return message;
  }

  @override
  Future<Message> sendPrivateAttachment(
    String id,
    Uint8List bytes,
    String type, {
    String? caption,
    String? clientMessageId,
  }) async {
    this.caption = caption;
    clientId = clientMessageId;
    final message = Message(
      id: 'attachment',
      kind: 'image',
      text: caption ?? '',
      mine: true,
      privateAttachment: {'id': 'file', 'type': type},
    );
    history.add(message);
    return message;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class ReadReceiptChatApi extends OptimisticChatApi {
  final reads = <String>[];
  int inboxLoads = 0;
  @override
  Future<void> markDelivered(String id, String message) async {}
  @override
  Future<void> markRead(String id, String message) async {
    reads.add(message);
  }

  @override
  Future<(List<Conversation>, int)> conversations({required String role, String filter = 'all'}) async {
    inboxLoads++;
    return (<Conversation>[], reads.isEmpty ? 1 : 0);
  }
}

void main() {
  testWidgets('interest action uses live HTTP for express and withdraw', (tester) async {
    final adapter = MockAdapter();
    adapter.on('POST', '/v1/engagement/requests/r1/interest', {'interested': true}, status: 201);
    adapter.on('DELETE', '/v1/engagement/requests/r1/interest', {'interested': false});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(VisualSession.new),
          apiProvider.overrideWithValue(HttpNexoApi(testDio(adapter))),
        ],
        child: host(
          Consumer(
            builder: (context, ref, _) => Column(
              children: [
                TextButton(
                  onPressed: () =>
                      toggleInterest(context, ref, const ServiceRequest(category: 'plomeria', title: 'Test', id: 'r1')),
                  child: const Text('Express'),
                ),
                TextButton(
                  onPressed: () => toggleInterest(
                    context,
                    ref,
                    const ServiceRequest(category: 'plomeria', title: 'Test', id: 'r1', iAmInterested: true),
                  ),
                  child: const Text('Withdraw'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Express'));
    await tester.pumpAndSettle();
    expect(adapter.last('POST', '/v1/engagement/requests/r1/interest').body, <String, dynamic>{});
    await tester.tap(find.text('Withdraw'));
    await tester.pumpAndSettle();
    expect(adapter.last('DELETE', '/v1/engagement/requests/r1/interest').method, 'DELETE');
    expect(tester.takeException(), isNull);
  });

  testWidgets('profile viewer exposes sharing to visitors without edit and one pencil to owner', (tester) async {
    for (final own in [false, true]) {
      await tester.pumpWidget(
        host(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showPhotoViewer(
                context,
                null,
                title: 'Photo',
                name: 'Public profile',
                circular: true,
                profileLink: 'nexolocal://provider/p1',
                onChange: own ? () {} : null,
              ),
              child: const Text('Open photo'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open photo'));
      await tester.pumpAndSettle();
      expect(find.text('Compartir perfil'), findsOneWidget);
      expect(find.text('Copiar enlace'), findsOneWidget);
      expect(find.text('Editar foto de perfil'), findsNothing);
      expect(find.byTooltip('Editar foto de perfil'), own ? findsOneWidget : findsNothing);
      await tester.pumpWidget(const SizedBox.shrink());
    }
  });

  testWidgets('client profile viewer offers all actions without publishing on open', (tester) async {
    var prepared = 0;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showPhotoViewer(
              context,
              null,
              title: 'Photo',
              name: 'Cliente',
              circular: true,
              requestProfileLink: () async {
                prepared++;
                return 'nexolocal://profile/shared';
              },
            ),
            child: const Text('Client photo'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Client photo'));
    await tester.pumpAndSettle();
    expect(find.text('Compartir perfil'), findsOneWidget);
    expect(find.text('Copiar enlace'), findsOneWidget);
    expect(prepared, 0);
    await tester.tap(find.text('C\u00f3digo QR'));
    await tester.pumpAndSettle();
    expect(prepared, 1);
    expect(tester.widget<ProfileQrCard>(find.byType(ProfileQrCard)).link, 'nexolocal://profile/shared');
    expect(Routes.fromDeepLink('nexolocal://profile/shared'), '/profile/shared');
    expect(tester.takeException(), isNull);
  });

  testWidgets('request menu offers actions before editor and editor has no title field', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: host(
          Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () => showRequestOptions(
                context,
                ref,
                const ServiceRequest(
                  id: 'r',
                  category: 'plomeria',
                  title: 'Hidden headline',
                  description: 'Contenido de solicitud',
                  mine: true,
                ),
              ),
              child: const Text('Options'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Options'));
    await tester.pumpAndSettle();
    expect(find.text('Editar solicitud'), findsOneWidget);
    expect(find.text('Eliminar publicaci\u00f3n'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('Editar solicitud'));
    await tester.pumpAndSettle();
    expect(find.text('T\u00edtulo'), findsNothing);
    expect(find.text('Contenido de solicitud'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Guardar cambios'), 250, scrollable: find.byType(Scrollable).last);
    expect(find.text('Guardar cambios'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('copy feedback is visible inside the photo viewer', (tester) async {
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (_) async => null);
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showPhotoViewer(
              context,
              null,
              title: 'Profile',
              circular: true,
              profileLink: 'nexolocal://profile/public',
              name: 'Nombre',
            ),
            child: const Text('Photo'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Photo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copiar enlace'));
    await tester.pumpAndSettle();
    expect(find.text('Enlace de perfil copiado').hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, null);
  });

  test('map tiles have a fallback and supported native zoom', () {
    final tiles = nexoTiles();
    expect(tiles.fallbackUrl, contains('openstreetmap.org'));
    expect(tiles.maxNativeZoom, 19);
  });

  testWidgets('message actions validate edits and require explicit deletion', (tester) async {
    ChatMessageAction? result;
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () async {
                result = await showChatMessageActions(
                  context,
                  text: 'Original',
                  canEdit: true,
                  style: 'night',
                  kind: 'text',
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('Original'), findsOneWidget);
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    expect(result?.kind, 'edit');
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    result = null;
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    // Borrar exige una segunda confirmación.
    expect(result, isNull);
    expect(find.text('\u00bfEliminar mensaje?'), findsOneWidget);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
    expect(result, isNull);
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar para todos'));
    await tester.pumpAndSettle();
    expect(result?.kind, 'delete');
    expect(tester.takeException(), isNull);
  });
  test('chat palettes coordinate backgrounds with readable message colors', () {
    final palettes = chatBackgrounds.map((s) => ChatPalette.forStyle(s.$1)).toList();
    expect(palettes.map((p) => p.sent).toSet().length, chatBackgrounds.length);
    for (final p in palettes) {
      expect(1.05 / (p.sent.computeLuminance() + .05), greaterThanOrEqualTo(4.5));
      final a = p.ink.computeLuminance();
      final b = p.received.computeLuminance();
      expect(((a > b ? a : b) + .05) / ((a < b ? a : b) + .05), greaterThanOrEqualTo(4.5));
    }
    expect(ChatPalette.forStyle('unknown').sent, palettes.first.sent);
  });
  testWidgets('chat customization previews options and returns them only when applied', (tester) async {
    String? selected;
    await tester.binding.setSurfaceSize(const Size(320, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              selected = await chooseChatBackground(context, 'linen');
            },
            child: const Text('Fondos'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Fondos'));
    await tester.pumpAndSettle();
    expect(find.byType(ChatBackdrop), findsOneWidget);
    for (final option in ['Noche', 'Grande', 'Rectas', 'Patr\u00f3n de fondo']) {
      await tester.ensureVisible(find.text(option));
      await tester.pumpAndSettle();
      await tester.tap(find.text(option));
      await tester.pumpAndSettle();
    }
    expect(selected, isNull);
    await tester.tap(find.text('Aplicar'));
    await tester.pumpAndSettle();
    expect(selected, 'night|plain|large|square');
    expect(tester.takeException(), isNull);
  });

  test('chat style keeps previously saved themes and round-trips options', () {
    expect(ChatStyle.decode('night').encode(), 'night');
    expect(ChatStyle.decode(null).encode(), 'linen');
    expect(ChatStyle.decode('unknown|large').encode(), 'linen|large');
    const custom = ChatStyle(theme: 'lilac', pattern: false, textSize: 'compact', rounded: false);
    expect(ChatStyle.decode(custom.encode()).encode(), custom.encode());
  });

  testWidgets('received messages only offer copying', (tester) async {
    ChatMessageAction? result;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              result = await showChatMessageActions(
                context,
                text: 'Recibido',
                canEdit: false,
                canDelete: false,
                mine: false,
                style: 'linen',
                kind: 'text',
              );
            },
            child: const Text('Abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Editar'), findsNothing);
    expect(find.text('Eliminar'), findsNothing);
    await tester.tap(find.text('Copiar'));
    await tester.pumpAndSettle();
    expect(result?.kind, 'copy');
    expect(tester.takeException(), isNull);
  });

  testWidgets('edited and deleted bubbles render distinct states without retaining deleted content', (tester) async {
    Widget bubbleHost(Widget child) => host(
      MediaQuery(
        data: const MediaQueryData(size: Size(390, 800)),
        child: child,
      ),
    );
    await tester.pumpWidget(
      bubbleHost(
        ChatMessageBubble(
          privateConversation: true,
          conversation: 'c',
          m: Message(id: 'm', kind: 'text', text: 'Texto actualizado', mine: true, editedAt: DateTime(2026, 11, 19)),
          showDay: false,
        ),
      ),
    );
    expect(find.text('Editado'), findsOneWidget);
    expect(find.text('Texto actualizado'), findsOneWidget);
    await tester.pumpWidget(
      bubbleHost(
        const ChatMessageBubble(
          privateConversation: true,
          conversation: 'c',
          m: Message(
            id: 'm',
            kind: 'deleted',
            text: 'Contenido anterior privado',
            imageUrl: 'https://unused.example/a.png',
            mine: true,
          ),
          showDay: false,
        ),
      ),
    );
    expect(find.text('Mensaje eliminado'), findsOneWidget);
    expect(find.text('Contenido anterior privado'), findsNothing);
    expect(find.byType(PrivateChatMedia), findsNothing);
    expect(find.byType(MessageReceipt), findsNothing);
  });

  test('confirmed mutation keeps position and cached tombstone without media', () async {
    final vault = MemoryChatHistory();
    final api = OptimisticChatApi();
    api.history.add(
      const Message(id: 'target', kind: 'image', text: 'Caption', mine: true, privateAttachment: {'id': 'file'}),
    );
    final experience = ChatExperience(api: () => api, vault: () async => vault, prepare: (_) async => api.thread);
    experience.remember(api.thread);
    experience.cacheMedia('c:file', Uint8List.fromList([1, 2, 3]));
    experience.confirmMutation('c', 'target', text: 'Actualizado');
    expect(experience.thread('c')!.messages.single.id, 'target');
    expect(experience.thread('c')!.messages.single.editedAt, isNotNull);
    experience.confirmMutation('c', 'target');
    final message = experience.thread('c')!.messages.single;
    expect(message.kind, 'deleted');
    expect(message.text, isEmpty);
    expect(message.privateAttachment, isNull);
    final restored = ChatExperience.decodeHistory('c', ChatExperience.encodeHistory(experience.thread('c')!));
    expect(restored.messages.single.kind, 'deleted');
    experience.dispose();
  });

  testWidgets('inline editing cancels without losing an existing draft', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    final api = ReadReceiptChatApi();
    api.history.add(
      const Message(id: 'editable', kind: 'text', text: 'Original editable', mine: true, encryptedPayload: {}),
    );
    final vault = MemoryChatHistory();
    final experience = ChatExperience(api: () => api, vault: () async => vault, prepare: (_) async => api.thread);
    experience.remember(api.thread);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(VisualSession.new),
          apiProvider.overrideWithValue(api),
          chatExperienceProvider.overrideWithValue(experience),
          dioProvider.overrideWithValue(testDio(MockAdapter())),
        ],
        child: const MaterialApp(home: ChatPage(id: 'c')),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.enterText(find.byType(TextField), 'My draft');
    await tester.longPress(find.text('Original editable'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'Original editable');
    expect(find.byTooltip('Enviar una foto'), findsNothing);
    expect(find.byKey(const ValueKey('voice-mic')), findsNothing);
    await tester.enterText(find.byType(TextField), 'A changed message');
    await tester.tap(find.byTooltip('Cancelar edici\u00f3n'));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text, 'My draft');
    expect(api.sends, 0);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    experience.dispose();
  });

  testWidgets('opening cached chat clears unread after an old unavailable message', (tester) async {
    FlutterSecureStorage.setMockInitialValues({});
    final api = ReadReceiptChatApi();
    api.history.add(const Message(id: 'old', kind: 'unavailable', mine: false));
    for (var i = 0; i < 35; i++) {
      api.history.add(Message(id: 'recent-$i', kind: 'text', text: 'Mensaje visible $i', mine: false));
    }
    final vault = MemoryChatHistory();
    final experience = ChatExperience(api: () => api, vault: () async => vault, prepare: (_) async => api.thread);
    experience.remember(api.thread);
    final container = ProviderContainer(
      overrides: [
        sessionProvider.overrideWith(VisualSession.new),
        apiProvider.overrideWithValue(api),
        chatExperienceProvider.overrideWithValue(experience),
        dioProvider.overrideWithValue(testDio(MockAdapter())),
      ],
    );
    final subscription = container.listen(inboxProvider('client'), (_, __) {});
    await container.read(inboxProvider('client').future);
    expect(container.read(inboxProvider('client')).value?.$2, 1);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ChatPage(id: 'c')),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    expect(api.reads, ['recent-34']);
    expect(find.text('Mensaje visible 34').hitTestable(), findsOneWidget);
    expect(container.read(inboxProvider('client')).value?.$2, 0);
    expect(api.inboxLoads, greaterThanOrEqualTo(2));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    subscription.close();
    container.dispose();
    experience.dispose();
  });

  test('old unavailable messages do not block newer incoming read receipts', () {
    const old = Message(id: 'old', kind: 'unavailable', mine: false);
    const recent = Message(id: 'recent', kind: 'text', text: 'Visible', mine: false);
    const own = Message(id: 'own', kind: 'text', text: 'Reply', mine: true);
    expect(latestReadableIncoming([old, recent, own])?.id, 'recent');
    expect(latestReadableIncoming([old]), isNull);
    expect(latestReadableIncoming([own]), isNull);
    expect(latestReadableIncoming([recent, old])?.id, 'recent');
  });

  TestWidgetsFlutterBinding.ensureInitialized();
  for (final width in [320.0, 390.0]) {
    testWidgets('QR card preserves the public link and readable layout at $width', (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(size: Size(width, 700), textScaler: const TextScaler.linear(1.4)),
            child: const Scaffold(
              body: ProfileQrCard(name: 'Un nombre de perfil bastante largo', link: 'nexolocal://provider/profile-id'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final qr = tester.widget<QrImageView>(find.byType(QrImageView));
      expect(qr.key, const ValueKey('nexolocal://provider/profile-id'));
      expect(qr.errorCorrectionLevel, QrErrorCorrectLevel.Q);
      final modules = QrValidator.validate(
        data: 'nexolocal://provider/profile-id',
        errorCorrectionLevel: QrErrorCorrectLevel.Q,
      ).qrCode!.moduleCount;
      expect(qr.padding.left / ((qr.size! - qr.padding.horizontal) / modules), closeTo(4, .001));
      final output = Platform.environment['QR_ARTIFACT_DIR'];
      if (output != null) {
        await tester.ensureVisible(find.byKey(const ValueKey('profile-qr-artifact')));
        await tester.pumpAndSettle();
        final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(const ValueKey('profile-qr-artifact')));
        await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 3);
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          await Directory(output).create(recursive: true);
          await File('$output/profile-qr-${width.toInt()}.png').writeAsBytes(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      expect(qr.embeddedImage, isNull);
      expect(find.text('Necesitas tener la app instalada.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('profile photo viewer uses the shared dark layout and only owners can edit', (tester) async {
    var edited = false;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showPhotoViewer(
              context,
              null,
              title: 'Editar',
              circular: true,
              name: 'Persona',
              profileLink: 'nexolocal://provider/id',
              onChange: () => edited = true,
            ),
            child: const Text('Ver perfil'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ver perfil'));
    await tester.pumpAndSettle();
    expect(find.text('Compartir perfil'), findsOneWidget);
    expect(find.text('Copiar enlace'), findsOneWidget);
    expect(find.textContaining('QR'), findsOneWidget);
    expect(find.byTooltip('Editar foto de perfil'), findsOneWidget);
    await tester.tap(find.byTooltip('Editar foto de perfil'));
    await tester.pumpAndSettle();
    expect(edited, isTrue);
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showPhotoViewer(
              context,
              null,
              title: 'Perfil',
              circular: true,
              name: 'Contacto',
              profileLink: 'nexolocal://provider/id',
            ),
            child: const Text('Ver contacto'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Ver contacto'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('Editar foto de perfil'), findsNothing);
    expect(find.text('Compartir perfil'), findsOneWidget);
  });
  testWidgets('photo is rendered from local bytes and preview returns an optional caption', (tester) async {
    final bytes = await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      ui.Canvas(recorder).drawColor(const Color(0xFF196C60), ui.BlendMode.src);
      final picture = recorder.endRecording();
      final image = await picture.toImage(40, 30);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = data!.buffer.asUint8List();
      image.dispose();
      picture.dispose();
      return bytes;
    });
    await tester.pumpWidget(
      ProviderScope(
        child: host(
          PrivateChatMedia(conversation: 'c', file: const {'id': 'photo', 'type': 'image/png'}, initialBytes: bytes),
        ),
      ),
    );
    expect(find.byType(Image), findsOneWidget);
    expect(find.text('Ver foto privada'), findsNothing);
    await tester.pumpAndSettle();
    String? caption;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async {
              caption = await previewChatPhoto(context, bytes!);
            },
            child: const Text('Abrir foto'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir foto'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Este es el mensaje de la foto');
    await tester.tap(find.byTooltip('Enviar foto'));
    await tester.pumpAndSettle();
    expect(caption, 'Este es el mensaje de la foto');
    expect(tester.takeException(), isNull);
  });
  test('chat inserts immediately and reconciles exactly one server message', () async {
    final api = OptimisticChatApi()..gate = Completer<Message>();
    final store = MemoryChatHistory();
    final experience = ChatExperience(api: () => api, vault: () async => store, prepare: (_) async => api.thread);
    addTearDown(experience.dispose);
    final local = experience.enqueue('c', text: 'Mensaje inmediato');
    expect(experience.pending('c').single, same(local));
    expect(local.status, isNot(ChatSendState.sent));
    await pumpEventQueue();
    api.gate!.complete(const Message(id: 'confirmed', kind: 'text', text: 'Mensaje inmediato', mine: true));
    await pumpEventQueue();
    expect(local.status, ChatSendState.sent);
    experience.remember(
      ChatThread(
        id: 'c',
        counterpart: api.thread.counterpart,
        encrypted: true,
        messages: const [Message(id: 'confirmed', kind: 'text', text: 'Mensaje inmediato', mine: true)],
      ),
    );
    expect(experience.pending('c'), isEmpty);
    expect(experience.thread('c')!.messages, hasLength(1));
  });
  test('failed chat remains visible and retries without adding another local bubble', () async {
    final api = OptimisticChatApi()..fail = true;
    final experience = ChatExperience(
      api: () => api,
      vault: () async => MemoryChatHistory(),
      prepare: (_) async => api.thread,
    );
    addTearDown(experience.dispose);
    final local = experience.enqueue('c', text: 'Conservar borrador');
    await pumpEventQueue();
    expect(local.status, ChatSendState.failed);
    expect(experience.pending('c').single.text, 'Conservar borrador');
    api.fail = false;
    experience.retry('c', local);
    await pumpEventQueue();
    expect(api.sends, 2);
    expect(experience.pending('c'), isEmpty);
    expect(experience.thread('c')!.messages.single.text, 'Conservar borrador');
  });
  test('photo caption and local bytes survive caller cleanup then clear on account disposal', () async {
    final api = OptimisticChatApi();
    final experience = ChatExperience(
      api: () => api,
      vault: () async => MemoryChatHistory(),
      prepare: (_) async => api.thread,
    );
    final original = Uint8List.fromList([1, 2, 3]);
    final local = experience.enqueue('c', text: 'Mi foto', bytes: original, type: 'image/jpeg');
    original.fillRange(0, original.length, 0);
    expect(local.bytes, [1, 2, 3]);
    await pumpEventQueue();
    expect(api.caption, 'Mi foto');
    expect(api.clientId, local.id);
    expect(experience.media('c:file'), [1, 2, 3]);
    experience.dispose();
    expect(experience.media('c:file'), isNull);
    expect(local.bytes, [0, 0, 0]);
  });
  test('encrypted local history restores metadata and media without reviving a server-empty history', () async {
    final api = OptimisticChatApi();
    final store = MemoryChatHistory();
    const thread = ChatThread(
      id: 'c',
      counterpart: Counterpart(id: 'peer', displayName: 'Contacto'),
      encrypted: true,
      messages: [
        Message(
          id: 'one',
          kind: 'image',
          text: 'Pie de foto',
          mine: true,
          privateAttachment: {'id': 'file', 'type': 'image/jpeg'},
        ),
      ],
    );
    store.values['history-ui:c'] = jsonEncode(ChatExperience.encodeHistory(thread));
    final experience = ChatExperience(api: () => api, vault: () async => store, prepare: (_) async => api.thread);
    addTearDown(experience.dispose);
    await experience.restore('c');
    expect(experience.thread('c')!.messages.single.text, 'Pie de foto');
    expect(experience.thread('c')!.messages.single.privateAttachment!['id'], 'file');
    experience.remember(api.thread);
    await experience.restore('c');
    expect(experience.thread('c')!.messages, isEmpty);
  });
  testWidgets('long chat text uses bounded width without horizontal overflow at large type', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(size: Size(320, 900), textScaler: TextScaler.linear(1.4)),
          child: Scaffold(
            body: SingleChildScrollView(
              child: ChatMessageBubble(
                privateConversation: false,
                conversation: 'c',
                showDay: false,
                m: Message(
                  id: 'long',
                  kind: 'text',
                  text: List.filled(30, 'Mensaje extenso con varias palabras.').join(' '),
                  mine: true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Enviado'), findsNothing);
    expect(find.byIcon(Icons.done_rounded), findsOneWidget);
  });
  testWidgets('voice renders playback and duration immediately from local PCM without fetching', (tester) async {
    final pcm = Uint8List(32044);
    await tester.pumpWidget(
      ProviderScope(
        child: host(
          PrivateChatMedia(conversation: 'c', file: const {'id': 'voice', 'type': 'audio/wav'}, initialBytes: pcm),
        ),
      ),
    );
    expect(find.byTooltip('Reproducir nota de voz'), findsOneWidget);
    expect(find.textContaining('0:01'), findsOneWidget);
    expect(find.text('Escuchar nota de voz'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('nota de voz: sin permiso de micrófono no se graba ni se envía', (tester) async {
    final capture = DeniedVoiceCapture();
    var sent = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [voiceCaptureProvider.overrideWithValue(() => capture)],
        child: MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: VoiceComposer(
                accent: Colors.teal,
                showMic: true,
                trailing: const SizedBox(),
                onSend: (_) => sent++,
                child: const SizedBox(height: 48),
              ),
            ),
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(tester.getCenter(find.byKey(const ValueKey('voice-mic'))));
    await tester.pump();
    await tester.pump();
    await gesture.up();
    await tester.pump(const Duration(seconds: 4));
    expect(capture.starts, 0);
    expect(capture.released, isTrue);
    expect(sent, 0);
    expect(find.text('Desliza para cancelar'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('nota de voz: soltar envia, deslizar cancela y subir bloquea', (tester) async {
    final capture = FakeVoiceCapture();
    final sent = <int>[];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [voiceCaptureProvider.overrideWithValue(() => capture)],
        child: MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: VoiceComposer(
                  accent: Colors.teal,
                  showMic: true,
                  trailing: const SizedBox(),
                  onSend: (wav) => sent.add(wav.length),
                  child: const SizedBox(height: 48),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    final mic = find.byKey(const ValueKey('voice-mic'));
    Future<TestGesture> hold() async {
      final gesture = await tester.startGesture(tester.getCenter(mic));
      await tester.pump();
      await tester.pump();
      capture.speak(32000);
      await tester.pump();
      return gesture;
    }

    var gesture = await hold();
    expect(find.text('Desliza para cancelar'), findsOneWidget);
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(sent, [32044]);
    expect(find.text('Desliza para cancelar'), findsNothing);

    gesture = await hold();
    await gesture.moveBy(const Offset(-140, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump(const Duration(seconds: 1));
    expect(sent, hasLength(1));
    expect(find.text('Desliza para cancelar'), findsNothing);

    gesture = await hold();
    await gesture.moveBy(const Offset(0, -100));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    // Bloqueada: sigue grabando sin el dedo.
    expect(sent, hasLength(1));
    expect(find.byTooltip('Eliminar grabaci\u00f3n'), findsOneWidget);
    await tester.tap(find.byTooltip('Enviar nota de voz'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(sent, hasLength(2));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('el horario se elige en un panel y puede copiarse a los dias activos', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    List<DayRange?>? saved;
    await tester.pumpWidget(
      host(
        Scaffold(
          body: SingleChildScrollView(
            child: HoursEditor(
              initialDays: const [(9, 18), (9, 18), null, null, null, null, null],
              initialUrgent: false,
              onSave: (days, urgent) async {
                saved = days;
                return true;
              },
            ),
          ),
        ),
      ),
    );
    expect(find.byType(DropdownButton<int>), findsNothing);
    await tester.tap(find.text('9:00 \u2013 18:00').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('hour-10')));
    await tester.pump();
    // Tras elegir la apertura se pasa al cierre; no ofrece horas anteriores.
    expect(find.byKey(const ValueKey('hour-10')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('hour-16')));
    await tester.pump();
    await tester.tap(find.text('Usar este horario en todos los d\u00edas activos'));
    await tester.pump();
    await tester.ensureVisible(find.text('Usar este horario'));
    await tester.tap(find.text('Usar este horario'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Guardar horario'));
    await tester.tap(find.text('Guardar horario'));
    await tester.pump();
    expect(saved, [(10, 16), (10, 16), null, null, null, null, null]);
    expect(tester.takeException(), isNull);
  });

  test('los errores de pedido se explican con palabras claras', () {
    expect(apiErrorMessage(const ApiException(code: 'order.active_exists', status: 409)), contains('pedido activo'));
    expect(
      apiErrorMessage(const ApiException(code: 'order.request_already_assigned', status: 409)),
      contains('prestador asignado'),
    );
  });

  testWidgets('inbox searches contacts and filters unread conversations', (tester) async {
    final adapter = MockAdapter();
    const conversations = [
      Conversation(
        id: 'one',
        counterpart: Counterpart(id: 'a', displayName: 'Ana'),
        lastPreview: 'Hola',
        unread: 2,
        ago: 'hace 17 min',
      ),
      Conversation(
        id: 'two',
        counterpart: Counterpart(id: 'b', displayName: 'Luis'),
        lastPreview: 'Gracias',
      ),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(VisualSession.new),
          apiProvider.overrideWithValue(HttpNexoApi(testDio(adapter))),
          inboxProvider.overrideWith((ref, role) async => (conversations, 2)),
        ],
        child: host(const InboxPage()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Luis'), findsOneWidget);
    // La hora queda alineada al borde derecho de la tarjeta, sin importar el largo del nombre.
    final card = tester.getRect(find.ancestor(of: find.text('Ana'), matching: find.byType(InkWell)).first);
    expect(card.right - tester.getRect(find.text('hace 17 min')).right, closeTo(13, .5));
    await tester.enterText(find.byType(TextField), 'lui');
    await tester.pump();
    expect(find.text('Ana'), findsNothing);
    expect(find.text('Luis'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '');
    await tester.tap(find.text('Sin leer \u00b7 1'));
    await tester.pump();
    expect(find.text('Ana'), findsOneWidget);
    expect(find.text('Luis'), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('palomitas distinguen enviado entregado y le?do', (tester) async {
    final now = DateTime(2026, 11, 17);
    for (final state in [(null, null, 'Enviado'), (now, null, 'Entregado'), (now, now, 'Le\u00eddo')]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageReceipt(deliveredAt: state.$1, readAt: state.$2),
          ),
        ),
      );
      expect(find.text(state.$3), findsOneWidget);
      expect(find.byIcon(state.$1 == null ? Icons.done_rounded : Icons.done_all_rounded), findsOneWidget);
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.color, state.$2 != null ? const Color(0xFF53D7FF) : Colors.white70);
    }
  });

  testWidgets('Skeleton layouts fit narrow screens and respect reduced motion', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final kind in NexoSkeletonKind.values) {
      await tester.pumpWidget(host(SingleChildScrollView(child: ContentSkeleton(kind: kind)), reduced: true));
      await tester.pumpAndSettle();
      expect(find.byType(ContentSkeleton), findsOneWidget);
      expect(tester.takeException(), isNull, reason: kind.name);
      expect(tester.binding.hasScheduledFrame, isFalse);
    }
  });
  testWidgets('Async skeleton preserves loaded data and shows real errors', (tester) async {
    await tester.pumpWidget(
      host(
        SingleChildScrollView(
          child: skeletonView<String>(NexoSkeletonKind.account, const AsyncLoading<String>(), (value) => Text(value)),
        ),
        reduced: true,
      ),
    );
    expect(find.byType(ContentSkeleton), findsOneWidget);
    await tester.pumpWidget(
      host(
        skeletonView<String>(
          NexoSkeletonKind.account,
          const AsyncData<String>('Cuenta existente'),
          (value) => Text(value),
        ),
        reduced: true,
      ),
    );
    expect(find.text('Cuenta existente'), findsOneWidget);
    expect(find.byType(ContentSkeleton), findsNothing);
    await tester.pumpWidget(
      host(
        skeletonView<String>(
          NexoSkeletonKind.account,
          AsyncError<String>(Exception('offline'), StackTrace.current),
          (value) => Text(value),
          onRetry: () {},
        ),
        reduced: true,
      ),
    );
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.byType(ContentSkeleton), findsNothing);
  });

  testWidgets('la revision muestra skeleton en avatar y portada sin texto sobre la foto', (tester) async {
    await tester.pumpWidget(
      host(
        const Column(
          children: [
            SizedBox(width: 88, height: 88, child: PhotoProcessingOverlay(circular: true)),
            SizedBox(width: 300, height: 120, child: PhotoProcessingOverlay()),
          ],
        ),
      ),
    );
    expect(find.byType(PhotoProcessingOverlay), findsNWidgets(2));
    expect(find.text('Revisando?'), findsNothing);
    await tester.pump(const Duration(milliseconds: 250));
    expect(tester.takeException(), isNull);
  });

  testWidgets('solicitud sin autor usa identidad neutra y no separadores vacios', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [accountProvider.overrideWith((ref) async => null)],
        child: host(
          const SingleChildScrollView(
            child: RequestCard(
              r: ServiceRequest(
                id: 'missing-author',
                category: 'plomeria',
                title: 'Reparacion',
                description: 'Necesito ayuda',
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Solicitud de la comunidad'), findsOneWidget);
    expect(find.text('?'), findsNothing);
    expect(find.text(' \u00b7 '), findsNothing);
    expect(find.byIcon(Icons.person_outline_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compartir perfil ofrece acciones sin compartir al abrir y permite QR', (tester) async {
    var shared = false;
    const channel = MethodChannel('mx.nexolocal/share');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      shared = true;
      return null;
    });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null),
    );
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => showProfileShareSheet(context, id: 'public-profile', name: 'Perfil de prueba'),
            child: const Text('Opciones'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Opciones'));
    await tester.pumpAndSettle();
    expect(find.text('Compartir'), findsOneWidget);
    expect(find.text('Copiar enlace'), findsOneWidget);
    expect(shared, isFalse);
    await tester.tap(find.text('Ver c\u00f3digo QR'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileQrCard), findsOneWidget);
    expect(tester.widget<ProfileQrCard>(find.byType(ProfileQrCard)).link, 'nexolocal://provider/public-profile');
    expect(shared, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('perfil de quien publica muestra solo datos publicos reales', (tester) async {
    const request = ServiceRequest(
      id: 'r-publica',
      category: 'plomeria',
      title: 'Fuga en la cocina',
      description: 'Necesito reparar una fuga',
      zoneLabel: 'Tula, Hidalgo',
      clientName: 'K. D.',
    );
    await tester.pumpWidget(host(const RequestAuthorPage(request: request)));
    expect(find.text('K. D.'), findsOneWidget);
    expect(find.text('Fuga en la cocina'), findsOneWidget);
    expect(find.textContaining('Tula, Hidalgo'), findsOneWidget);
  });

  testWidgets('publicacion extensa muestra texto completo al pulsar Ver mas y se puede contraer', (tester) async {
    final longText = ('Necesito una reparacion detallada en mi domicilio. ' * 14).trim();
    await tester.pumpWidget(
      host(SingleChildScrollView(child: SizedBox(width: 260, child: ExpandablePublicationText(longText)))),
    );
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
          {'slug': 'plomeria', 'name': 'Plomería', 'icon': 'drop'},
        ],
      })
      ..on(
        'POST',
        '/v1/discovery/requests',
        problem('server.dependency_unavailable', 503, 'No se pudo comprobar el contenido.'),
        status: 503,
      );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sessionProvider.overrideWith(VisualSession.new),
          searchLocationProvider.overrideWith(TestLocation.new),
          apiProvider.overrideWithValue(HttpNexoApi(testDio(adapter))),
        ],
        child: MaterialApp(
          scaffoldMessengerKey: rootMessengerKey,
          home: const Scaffold(body: PublishPage()),
        ),
      ),
    );
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

  testWidgets('ML: al agregar una foto sin categoría, Publicar sugiere la categoría (spec 049, FR-001)',
      (tester) async {
    ImagePickerPlatform.instance = _OnePhotoPicker();
    final adapter = MockAdapter()
      ..on('GET', '/v1/discovery/categories', {
        'categories': [
          {'slug': 'plomeria', 'name': 'Plomería', 'icon': 'drop'}
        ]
      });
    await tester.pumpWidget(ProviderScope(overrides: [
      sessionProvider.overrideWith(VisualSession.new),
      searchLocationProvider.overrideWith(TestLocation.new),
      apiProvider.overrideWithValue(HttpNexoApi(testDio(adapter))),
      categorySuggesterProvider.overrideWithValue(_PlumbingSuggester()),
    ], child: MaterialApp(scaffoldMessengerKey: rootMessengerKey, home: const Scaffold(body: PublishPage()))));
    await tester.pumpAndSettle();
    expect(find.textContaining('Por la foto parece'), findsNothing);
    await tester.ensureVisible(find.textContaining('Agregar fotos'));
    await tester.tap(find.textContaining('Agregar fotos'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Por la foto parece'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0]) {
    testWidgets('Publicar mantiene columnas alineadas y opciones tocables a $width', (tester) async {
      await tester.binding.setSurfaceSize(Size(width, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      var taps = 0;
      await tester.pumpWidget(
        host(
          Column(
            children: [
              PublishOptionRow(icon: 'hammer', label: 'Servicio', value: 'Elegir', onTap: () => taps++),
              PublishOptionRow(
                icon: 'pin',
                label: 'Ubicación',
                value: 'Santa María Magdalena, Hidalgo',
                onTap: () => taps++,
              ),
              PublishOptionRow(icon: 'clock', label: '¿Para cuándo?', value: 'Esta semana', onTap: () => taps++),
              PublishOptionRow(icon: 'chat', label: 'Te contactan por', value: 'Solo chat', onTap: () => taps++),
            ],
          ),
        ),
      );
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
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountProvider.overrideWith((ref) async => null),
          sessionProvider.overrideWith(VisualSession.new),
          apiProvider.overrideWithValue(HttpNexoApi(testDio(adapter))),
        ],
        child: host(
          const SingleChildScrollView(
            child: WorkCard(
              work: Work(
                id: 'w',
                provider: ProviderMini(id: 'p', name: 'Prestador real'),
                category: 'plomeria',
                title: 'Trabajo real',
                recs: 7,
              ),
            ),
          ),
        ),
      ),
    );
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
      'radiusKm': 5,
    });
    final container = ProviderContainer(
      overrides: [
        sessionProvider.overrideWith(LocationSessionSwitch.new),
        apiProvider.overrideWithValue(HttpNexoApi(testDio(adapter))),
      ],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(home: Consumer(builder: (_, ref, __) => Text(ref.watch(searchLocationProvider).zoneLabel))),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Zona real A'), findsOneWidget);
    expect(container.read(searchLocationProvider).radiusKm, 5);
    adapter.on('GET', '/v1/discovery/me/location', {
      'searchLocation': {'lat': 20.15, 'lng': -99.44},
      'zoneLabel': 'Zona real B',
      'radiusKm': 20,
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
      final container = ProviderContainer(
        overrides: [
          sessionProvider.overrideWith(signedIn ? VisualSession.new : SignedOutVisualSession.new),
          searchLocationProvider.overrideWith(TestLocation.new),
        ],
      );
      container
          .read(signupFlowProvider.notifier)
          .accountCreated(const CreatedAccount(name: 'Nueva Cuenta', nextStep: 'home', tokens: null));
      final router = container.read(routerProvider);
      router.go(signedIn ? Routes.home : Routes.registerDone);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
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
        {'lat': 20.0489, 'lng': -99.3729, 'label': 'Tula de Allende, Hidalgo', 'zoneLabel': 'Tula de Allende, Hidalgo'},
      ],
    });
    LocationPick? selected;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiProvider.overrideWithValue(HttpNexoApi(testDio(adapter)))],
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                child: const Text('Elegir'),
                onPressed: () async {
                  selected = await Navigator.of(context).push<LocationPick>(
                    MaterialPageRoute(builder: (_) => const LocationPickerPage(args: LocationPickerArgs())),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Elegir'));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<NexoButton>(find.byWidgetPredicate((w) => w is NexoButton && w.label == 'Usar esta ubicación'))
          .onPressed,
      isNull,
    );
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
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiProvider.overrideWithValue(HttpNexoApi(testDio(adapter)))],
        child: const MaterialApp(
          home: LocationPickerPage(args: LocationPickerArgs(initial: GeoPoint(20.05, -99.34))),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Una dirección');
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();
    expect(find.textContaining('No pudimos buscar direcciones.'), findsOneWidget);
    expect(
      tester
          .widget<NexoButton>(find.byWidgetPredicate((w) => w is NexoButton && w.label == 'Usar esta ubicación'))
          .onPressed,
      isNotNull,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('perfil ofrece cuatro secciones accesibles en pantallas estrechas', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 640));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    String? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MediaQuery(
            data: const MediaQueryData(textScaler: TextScaler.linear(1.5)),
            child: ProviderProfileTabs(value: 'work', onChanged: (value) => selected = value),
          ),
        ),
      ),
    );
    final labels = ['Trabajos', 'Fotos', 'Información', 'Opiniones'];
    for (var i = 0; i < labels.length - 1; i++) {
      expect(tester.getCenter(find.text(labels[i])).dx, lessThan(tester.getCenter(find.text(labels[i + 1])).dx));
    }
    await tester.tap(find.text('Fotos'));
    expect(selected, 'photos');
    expect(tester.takeException(), isNull);
  });

  testWidgets('trabajo propio abre opciones antes de editar o eliminar', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: host(
          const SingleChildScrollView(
            child: WorkCard(
              own: true,
              work: Work(
                id: 'owned',
                provider: ProviderMini(id: 'p', name: 'Autora'),
                category: 'plomeria',
                title: 'Trabajo',
                text: 'Contenido del trabajo',
                images: [],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byWidgetPredicate((widget) => widget is ActIcon && widget.label == 'Opciones de trabajo'));
    await tester.pumpAndSettle();
    expect(find.text('Editar trabajo'), findsOneWidget);
    expect(find.text('Eliminar publicación'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
    await tester.tap(find.text('Eliminar publicación'));
    await tester.pumpAndSettle();
    expect(find.text('Conservar trabajo'), findsOneWidget);
    expect(find.textContaining('Tus conversaciones y pedidos se conservan.'), findsOneWidget);
    await tester.tap(find.text('Conservar trabajo'));
    await tester.pumpAndSettle();
    expect(find.text('Contenido del trabajo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('feed ocupa todo el ancho con imagen cuadrada como la maqueta', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        child: host(
          const SingleChildScrollView(
            child: WorkCard(
              work: Work(
                id: 'visual-work',
                provider: ProviderMini(id: 'provider', name: 'Prestador'),
                category: 'plomeria',
                title: 'Trabajo publicado',
                images: [Img('demo://plomeria/0')],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final image = tester.getSize(find.byType(PhotoCarousel));
    expect(image.width, 390);
    expect(image.height, image.width);
    expect(find.text('Contactar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('interesados selecciona dos IDs y abre el comparador compartido', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const first = ProviderProfile(id: 'pro-1', name: 'Ana', categories: ['plomeria']);
    const second = ProviderProfile(id: 'pro-2', name: 'Luis', categories: ['plomeria']);
    final adapter = MockAdapter()
      ..on('GET', '/v1/discovery/providers/compare', {
        'providers': [
          {'providerId': 'pro-1', 'name': 'Ana'},
          {'providerId': 'pro-2', 'name': 'Luis'},
        ],
        'rows': [
          {
            'key': 'price',
            'label': 'Precio',
            'values': ['Desde 100', 'Desde 150'],
          },
        ],
      });
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const interested_ui.InterestedPage(requestId: 'req'),
        ),
        GoRoute(path: Routes.compare, builder: (_, __) => const ComparePage()),
      ],
    );
    addTearDown(router.dispose);
    final container = ProviderContainer(
      overrides: [
        sessionProvider.overrideWith(VisualSession.new),
        searchLocationProvider.overrideWith(TestLocation.new),
        myRequestsProvider.overrideWith((ref) async => []),
        interestedProvider(('req', 'rate')).overrideWith(
          (ref) async => const InterestedPage(
            requestId: 'req',
            title: 'Reparar una fuga',
            status: 'open',
            items: [
              Interested(provider: first, note: 'Puedo ayudarte'),
              Interested(provider: second),
            ],
          ),
        ),
        apiProvider.overrideWithValue(HttpNexoApi(testDio(adapter))),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Comparar prestador').first);
    await tester.tap(find.text('Comparar prestador').first);
    await tester.pumpAndSettle();
    expect(container.read(compareProvider).map((p) => p.id), ['pro-1']);
    expect(find.text('En comparación'), findsOneWidget);
    // Tapping again removes the same candidate, rather than duplicating it.
    await tester.tap(find.text('En comparación'));
    await tester.pumpAndSettle();
    expect(container.read(compareProvider), isEmpty);
    await tester.tap(find.text('Comparar prestador').first);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Comparar prestador').last);
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView).first, const Offset(0, -100));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Comparar prestador').last);
    await tester.pumpAndSettle();
    expect(container.read(compareProvider).map((p) => p.id), ['pro-1', 'pro-2']);
    await tester.tap(find.text('Comparar'));
    await tester.pumpAndSettle();
    expect(find.byType(ComparePage), findsOneWidget);
    expect(adapter.last('GET', '/v1/discovery/providers/compare').query['ids'], 'pro-1,pro-2');
    expect(find.text('Desde 100'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cabecera de busqueda alinea titulo y ubicacion en ancho reducido', (tester) async {
    for (final width in [320.0, 390.0]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: width,
                child: const MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(1.3)),
                  child: SearchHeader(title: 'Buscar solicitudes', location: 'Santa Maria Magdalena, Hidalgo - 20 km'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.widget<Text>(find.text('Santa Maria Magdalena, Hidalgo - 20 km')).maxLines, 1);
      final title = tester.getRect(find.text('Buscar solicitudes'));
      final location = tester.getRect(find.text('Santa Maria Magdalena, Hidalgo - 20 km'));
      expect(location.left, greaterThan(title.right));
      expect(location.center.dy, closeTo(title.center.dy, 1));
      final paragraph = tester.renderObject<RenderParagraph>(find.text('Buscar solicitudes'));
      final painter = TextPainter(
        text: paragraph.text,
        maxLines: 2,
        textDirection: TextDirection.ltr,
        textScaler: paragraph.textScaler,
      )..layout(maxWidth: paragraph.size.width);
      expect(painter.computeLineMetrics().length, lessThanOrEqualTo(2));
      painter.dispose();
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('la cabecera permanece fija al desplazar el contenido', (tester) async {
    await tester.pumpWidget(
      host(
        PinnedHeaderList(
          children: [
            const ScreenTitleBar('Cabecera fija'),
            for (var i = 0; i < 30; i++) SizedBox(height: 80, child: Text('Fila $i')),
          ],
        ),
      ),
    );
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
      final container = ProviderContainer(
        overrides: [
          sessionProvider.overrideWith(VisualSession.new),
          pushProvider.overrideWith(VisualPush.new),
          syncProvider.overrideWith(VisualSync.new),
          accountProvider.overrideWith((ref) async => account),
          myProviderProvider.overrideWith((ref) async => null),
          searchLocationProvider.overrideWith(TestLocation.new),
          myRequestsProvider.overrideWith((ref) async => const <ServiceRequest>[]),
          savedProvider.overrideWith((ref) async => throw const ApiException(code: 'http_404', status: 404)),
          inboxProvider.overrideWith((ref, role) async => (const <Conversation>[], 0)),
        ],
      );
      final router = container.read(routerProvider);
      router.go(Routes.account);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
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
      // El perfil ya no repite un botón de editar: se entra desde la foto.
      expect(find.text('Editar datos de mi perfil'), findsNothing);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, 600));
      await tester.pumpAndSettle();
      await tester.tap(find.byWidgetPredicate((w) => w is Hero && w.tag == 'my-avatar'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Editar perfil'));
      await tester.pumpAndSettle();
      expect(find.text('Editar perfil'), findsOneWidget);
      expect(find.text('Tu nombre'), findsOneWidget);
      expect(find.text('Agregar foto'), findsOneWidget);
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
      await tester.tap(
        find.descendant(of: find.byType(LocationPickerPage), matching: find.bySemanticsLabel('Cerrar ubicación')).last,
      );
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
    await tester.pumpWidget(
      host(
        NexoEnter(
          child: NexoButton(label: 'Continuar', onPressed: () => calls++),
        ),
        reduced: true,
      ),
    );
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
    await tester.pumpWidget(
      host(
        Align(
          alignment: Alignment.bottomCenter,
          child: NexoNavigation(current: 0, onSelected: (index) => selected = index),
        ),
      ),
    );
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
    await tester.pumpWidget(
      host(
        Align(
          alignment: Alignment.bottomCenter,
          child: NexoNavigation(current: 4, unread: 3, onSelected: (index) => selected = index),
        ),
      ),
    );
    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Cuenta'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    await tester.tap(find.text('Buscar'));
    await tester.pumpAndSettle();
    expect(selected, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('perfil muestra nombre y experiencias reales sin inventar actividad', (tester) async {
    const account = AccountScreen(name: 'Cuenta Real', email: 'cuenta@example.test', emailVerified: true);
    var edits = 0;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountProvider.overrideWith((ref) async => account),
          searchLocationProvider.overrideWith(TestLocation.new),
          myRequestsProvider.overrideWith((ref) async => throw const ApiException(code: 'http_404', status: 404)),
          savedProvider.overrideWith((ref) async => throw const ApiException(code: 'http_404', status: 404)),
        ],
        child: MaterialApp(
          home: MyProfilePage(initial: account, onEdit: (_) => edits++),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Cuenta Real'), findsOneWidget);
    expect(find.text('Correo verificado'), findsOneWidget);
    expect(find.text('Editar datos de mi perfil'), findsNothing);
    await tester.tap(find.byWidgetPredicate((w) => w is Hero && w.tag == 'my-avatar'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Editar perfil'));
    await tester.pumpAndSettle();
    expect(edits, 1);
    expect(find.text('—'), findsNWidgets(3));
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -450));
    await tester.pumpAndSettle();
    expect(find.text('Próximamente'), findsOneWidget);
    await tester.tap(find.text('Experiencias').last);
    await tester.pumpAndSettle();
    expect(find.text('Tus experiencias'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets('carrusel de solicitud muestra contador actualizado', (tester) async {
    await tester.pumpWidget(
      host(
        const SizedBox(
          width: 320,
          child: PhotoCarousel(
            category: 'plomeria',
            images: [Img('demo://plomeria/0'), Img('demo://plomeria/1'), Img('demo://plomeria/2')],
          ),
        ),
      ),
    );
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
      'contact': 'chatCall',
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
      id: 'w1',
      provider: ProviderMini(id: 'p1', name: 'Persona'),
      category: 'plomeria',
      title: 'Trabajo anterior',
    );
    final updated = await api.editWork(
      original,
      title: 'Trabajo nuevo',
      text: 'Descripción completa del trabajo',
      tag: 'Finalizado',
      imageUploadIds: ['a', 'b'],
    );
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
    await api.editRequest(
      'r1',
      title: 'Título nuevo',
      description: 'Descripción actualizada',
      urgency: 'week',
      contact: 'chat',
      imageUploadIds: ['a', 'b'],
    );
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
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiProvider.overrideWithValue(HttpNexoApi(testDio(adapter)))],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: TextButton(
                onPressed: () => showBasicSheet(
                  context,
                  ref,
                  const ProviderProfile(id: 'real', name: 'Nombre Real', bio: 'Descripción real del servicio.'),
                ),
                child: const Text('Editar'),
              ),
            ),
          ),
        ),
      ),
    );
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
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiProvider.overrideWithValue(HttpNexoApi(testDio(adapter)))],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: TextButton(
                onPressed: () => showTermsEditSheet(
                  context,
                  ref,
                  const ProviderProfile(
                    id: 'real',
                    name: 'Nombre Real',
                    payment: ['cash', 'transfer'],
                    responseTime: 'sameDay',
                  ),
                ),
                child: const Text('Condiciones'),
              ),
            ),
          ),
        ),
      ),
    );
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

  Future<MockAdapter> openSheet(
    WidgetTester tester,
    String section,
    void Function(BuildContext context, WidgetRef ref) open,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final adapter = MockAdapter();
    adapter.on('PATCH', '/v1/discovery/providers/me/$section', {'providerId': 'real'});
    await tester.pumpWidget(
      ProviderScope(
        overrides: [apiProvider.overrideWithValue(HttpNexoApi(testDio(adapter)))],
        child: MaterialApp(
          home: Consumer(
            builder: (context, ref, _) => Scaffold(
              body: TextButton(onPressed: () => open(context, ref), child: const Text('Abrir hoja')),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir hoja'));
    await tester.pumpAndSettle();
    return adapter;
  }

  Future<void> press(WidgetTester tester, Finder target) async {
    await tester.ensureVisible(target);
    await tester.pumpAndSettle();
    await tester.tap(target);
    await tester.pumpAndSettle();
  }

  testWidgets('precios marca el error junto al campo y no descarta filas sin avisar', (tester) async {
    final adapter = await openSheet(
      tester,
      'prices',
      (context, ref) => showPricesSheet(context, ref, const ProviderProfile(id: 'real', name: 'Nombre Real')),
    );
    await tester.enterText(find.byKey(const ValueKey('price-amount-0')), '350');
    await press(tester, find.text('Guardar precios'));
    expect(find.text('Escribe qué servicio es.'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('price-service-0')), 'Fuga');
    await tester.enterText(find.byKey(const ValueKey('price-amount-0')), '');
    await press(tester, find.text('Guardar precios'));
    expect(find.text('Escribe el precio o elige «A cotizar».'), findsOneWidget);

    await press(tester, find.text('A cotizar'));
    expect(find.text('Escribe el precio o elige «A cotizar».'), findsNothing);
    await press(tester, find.text('Agregar otro servicio'));
    await tester.enterText(find.byKey(const ValueKey('price-service-1')), 'Se quita');
    await tester.pump();
    expect(find.text('2 de 3'), findsOneWidget);
    await press(tester, find.byTooltip('Quitar servicio 2'));
    expect(find.text('Se quita'), findsNothing);
    expect(find.text('1 de 3'), findsOneWidget);

    await press(tester, find.text('Guardar precios'));
    final body = adapter.last('PATCH', '/v1/discovery/providers/me/prices').body as Map;
    expect(body['prices'], [
      {'service': 'Fuga', 'fromCents': null, 'unit': 'quote', 'suffix': ''},
    ]);
    expect(body['visit'], {'mode': 'hidden'});
    expect(tester.takeException(), isNull);
  });

  testWidgets('condiciones no supone un tiempo de respuesta que nadie eligió', (tester) async {
    final adapter = await openSheet(
      tester,
      'terms',
      (context, ref) => showTermsEditSheet(context, ref, const ProviderProfile(id: 'real', name: 'Nombre Real')),
    );
    expect(find.text('Sin elegir, tu perfil no promete un tiempo de respuesta.'), findsOneWidget);
    await press(tester, find.text('48 h'));
    await press(tester, find.text('48 h'));
    await press(tester, find.text('Tarjeta'));
    await press(tester, find.text('Guardar'));
    final body = adapter.last('PATCH', '/v1/discovery/providers/me/terms').body as Map;
    expect(body['responseTime'], isNull);
    expect(body['payment'], ['card']);
    expect(tester.takeException(), isNull);
  });

  Future<MockAdapter> openAccount(WidgetTester tester, SessionController Function() session) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final adapter = MockAdapter();
    adapter.on('POST', '/v1/identity/me/deletion', {'status': 'pendingDeletion', 'daysRemaining': 30}, status: 202);
    adapter.on('DELETE', '/v1/identity/me/deletion', {'status': 'active'});
    final container = ProviderContainer(
      overrides: [
        sessionProvider.overrideWith(session),
        apiProvider.overrideWithValue(HttpNexoApi(testDio(adapter))),
        pushProvider.overrideWith(VisualPush.new),
        syncProvider.overrideWith(VisualSync.new),
        accountProvider.overrideWith((ref) async => const AccountScreen(name: 'Cuenta Real', emailVerified: true)),
        myProviderProvider.overrideWith((ref) async => null),
        searchLocationProvider.overrideWith(TestLocation.new),
        myRequestsProvider.overrideWith((ref) async => const <ServiceRequest>[]),
        savedProvider.overrideWith((ref) async => throw const ApiException(code: 'http_404', status: 404)),
        inboxProvider.overrideWith((ref, role) async => (const <Conversation>[], 0)),
        notificationsProvider.overrideWith((ref) async => (const <NotificationItem>[], 0)),
      ],
    );
    addTearDown(container.dispose);
    final router = container.read(routerProvider)..go(Routes.account);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();
    return adapter;
  }

  testWidgets('eliminar cuenta avisa lo irreversible, exige contraseña y cierra la sesión', (tester) async {
    DeletingSession.signOuts = 0;
    final adapter = await openAccount(tester, DeletingSession.new);
    await tester.scrollUntilVisible(find.text('Eliminar mi cuenta'), 300, scrollable: find.byType(Scrollable).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar mi cuenta'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Eso no se recupera aunque canceles la baja.'), findsOneWidget);

    final confirm = find.byWidgetPredicate((w) => w is NexoButton && w.label == 'Eliminar mi cuenta');
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(find.text('Escribe tu contraseña para confirmar.'), findsOneWidget);
    expect(adapter.calls.where((c) => c.path == '/v1/identity/me/deletion'), isEmpty);
    expect(DeletingSession.signOuts, 0);

    await tester.enterText(find.byType(TextField).first, 'NoEsUnSecreto1');
    await tester.ensureVisible(confirm);
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect((adapter.last('POST', '/v1/identity/me/deletion').body as Map)['password'], 'NoEsUnSecreto1');
    expect(DeletingSession.signOuts, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('con la baja pendiente solo se puede conservar la cuenta o salir', (tester) async {
    final adapter = await openAccount(tester, RecoverySession.new);
    expect(find.text('Tu cuenta tiene una baja pendiente'), findsOneWidget);
    expect(find.text('Cerrar sesión'), findsOneWidget);
    expect(find.text('Eliminar mi cuenta'), findsNothing);
    await tester.tap(find.text('Conservar mi cuenta'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(adapter.calls.map((c) => '${c.method} ${c.path}'), contains('DELETE /v1/identity/me/deletion'));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
  });

  group('guía de «Explorar sin cuenta» (maqueta)', () {
    Future<ProviderContainer> openAsGuest(WidgetTester tester) async {
      // La fuente de prueba es más ancha que la real: se da holgura a la barra.
      await tester.binding.setSurfaceSize(const Size(520, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final container = ProviderContainer(
        overrides: [
          sessionProvider.overrideWith(GuestVisualSession.new),
          pushProvider.overrideWith(VisualPush.new),
          syncProvider.overrideWith(VisualSync.new),
          searchLocationProvider.overrideWith(TestLocation.new),
          accountProvider.overrideWith((ref) async => null),
          myProviderProvider.overrideWith((ref) async => null),
          myRequestsProvider.overrideWith((ref) async => const <ServiceRequest>[]),
          inboxProvider.overrideWith((ref, role) async => (const <Conversation>[], 0)),
          notificationsProvider.overrideWith((ref) async => (const <NotificationItem>[], 0)),
          feedProvider.overrideWith(
            (ref) async => const FeedPage(
              zoneLabel: 'Zona elegida',
              guest: true,
              page: CursorPage([
                Work(
                  id: 'w1',
                  provider: ProviderMini(id: 'p1', name: 'Luis Ortega'),
                  category: 'plomeria',
                  title: 'Fuga reparada',
                  text: 'Cambié la tubería de la cocina en una tarde.',
                  images: [],
                ),
              ]),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      final router = container.read(routerProvider)..go(Routes.home);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
      return container;
    }

    Future<void> finish(WidgetTester tester) async {
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 3));
    }

    testWidgets('recorre los 4 pasos tocando lo resaltado y permite volver', (tester) async {
      final container = await openAsGuest(tester);
      expect(find.text('PASO 1 DE 4'), findsOneWidget);
      expect(find.text('Primero, elige dónde buscar'), findsOneWidget);
      expect(find.text('Toca tu zona'), findsOneWidget);
      expect(find.byTooltip('Paso anterior'), findsNothing);

      container.read(guestTourProvider.notifier).next();
      await tester.pumpAndSettle();
      expect(find.text('Busca lo que necesitas'), findsOneWidget);
      // Tocar el buscador iluminado avanza sin salir de Inicio.
      await tester.tapAt(tester.getCenter(find.byKey(TourAnchors.search)));
      await tester.pumpAndSettle();
      expect(find.text('Trabajos reales de tu zona'), findsOneWidget);

      await tester.tap(find.byTooltip('Paso anterior'));
      await tester.pumpAndSettle();
      expect(find.text('PASO 2 DE 4'), findsOneWidget);
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Siguiente'));
      await tester.pumpAndSettle();
      expect(find.text('Explora antes de decidir'), findsOneWidget);
      await tester.tap(find.text('Listo, explorar'));
      await tester.pumpAndSettle();
      expect(find.byType(GuestTourOverlay), findsNothing);
      expect(tester.takeException(), isNull);
      await finish(tester);
    });

    testWidgets('el fondo atenuado no ejecuta nada y la guía se puede omitir', (tester) async {
      final container = await openAsGuest(tester);
      container.read(guestTourProvider.notifier).next();
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(260, 430));
      await tester.pumpAndSettle();
      expect(find.text('PASO 2 DE 4'), findsOneWidget);
      await tester.tap(find.text('Omitir guía'));
      await tester.pumpAndSettle();
      expect(find.byType(GuestTourOverlay), findsNothing);
      expect(container.read(guestTourProvider), isNull);
      await finish(tester);
    });

    testWidgets('el primer paso abre el mapa y, sin elegir zona, no avanza', (tester) async {
      await openAsGuest(tester);
      await tester.tap(find.text('Elegir ubicación'));
      await tester.pumpAndSettle();
      expect(find.text('Primero, elige dónde buscas'), findsOneWidget);
      expect(find.byType(LocationPickerPage), findsOneWidget);
      Navigator.of(tester.element(find.byType(LocationPickerPage))).pop();
      await tester.pumpAndSettle();
      expect(find.text('PASO 1 DE 4'), findsOneWidget);
      await finish(tester);
    });

    testWidgets('quien tiene sesión no ve la guía', (tester) async {
      final container = ProviderContainer(overrides: [sessionProvider.overrideWith(VisualSession.new)]);
      addTearDown(container.dispose);
      expect(container.read(guestTourProvider), isNull);
    });
  });

  testWidgets('eliminar una publicación exige mantener presionado', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    var deletes = 0;
    bool? result;
    await tester.pumpWidget(
      host(
        Builder(
          builder: (context) => TextButton(
            onPressed: () async => result = await confirmPublicationDelete(
              context,
              preview: const PublicationPreview(text: 'Mi publicación'),
              loses: 'Deja de verse.',
              keeps: 'Los pedidos se conservan.',
              keepLabel: 'Conservar',
              onDelete: () async => deletes++,
            ),
            child: const Text('Abrir'),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    // Un toque instantáneo y otro soltado a la mitad no borran nada.
    await tester.tap(find.text('Mantén presionado para eliminar').first);
    await tester.pumpAndSettle();
    expect(deletes, 0);
    final half = await tester.startGesture(tester.getCenter(find.text('No sueltes hasta que se llene').first));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await half.up();
    await tester.pumpAndSettle();
    expect(deletes, 0);
    expect(find.text('Mantén presionado para eliminar'), findsWidgets);
    final press = await tester.startGesture(tester.getCenter(find.text('Mantén presionado para eliminar').first));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1200));
    await press.up();
    await tester.pumpAndSettle();
    expect(deletes, 1);
    expect(result, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('editar solo guarda con cambios y pide confirmar antes de descartarlos', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      ProviderScope(
        child: host(
          Consumer(
            builder: (context, ref, _) => TextButton(
              onPressed: () => showRequestEditor(
                context,
                ref,
                const ServiceRequest(
                  id: 'r',
                  category: 'plomeria',
                  title: 'Fuga',
                  description: 'Necesito reparar una fuga',
                  mine: true,
                ),
              ),
              child: const Text('Editar ahora'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Editar ahora'));
    await tester.pumpAndSettle();
    NexoButton save() =>
        tester.widget<NexoButton>(find.byWidgetPredicate((w) => w is NexoButton && w.label == 'Guardar cambios'));
    expect(save().onPressed, isNull);
    expect(find.text('Aún no has cambiado nada'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Necesito reparar una fuga grande');
    await tester.pump();
    expect(save().onPressed, isNotNull);
    expect(find.text('Tienes cambios sin guardar'), findsOneWidget);
    await tester.tap(find.byTooltip('Cerrar edición'));
    await tester.pumpAndSettle();
    expect(find.text('¿Descartar tus cambios?'), findsOneWidget);
    await tester.tap(find.text('Seguir editando'));
    await tester.pumpAndSettle();
    expect(find.text('Necesito reparar una fuga grande'), findsOneWidget);
    await tester.tap(find.byTooltip('Cerrar edición'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Descartar cambios'));
    await tester.pumpAndSettle();
    expect(find.text('Guardar cambios'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _OnePhotoPicker extends ImagePickerPlatform {
  @override
  Future<List<XFile>> getMultiImageWithOptions(
          {MultiImagePickerOptions options = const MultiImagePickerOptions()}) async =>
      [
        XFile.fromData(Uint8List.fromList([0xFF, 0xD8, 0xFF]), path: 'lavabo.jpg', mimeType: 'image/jpeg')
      ];
}

class _PlumbingSuggester implements CategorySuggester {
  @override
  Future<CategoryGuess?> suggest(String imagePath, {Set<String>? allowed}) async =>
      const CategoryGuess(category: 'plomeria', confidence: 0.72, labels: ['Sink', 'Tap']);
  @override
  Future<void> close() async {}
}
