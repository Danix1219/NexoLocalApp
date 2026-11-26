import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart' as local;
import '../../app/env.dart';
import '../../app/router.dart';
import '../../core/auth/auth_tokens.dart';
import '../../core/auth/token_storage.dart';
import '../../core/network/api_client.dart' show refreshTokens;
import '../../core/chat/chat_vault.dart';
import '../../core/chat/signal_chat_crypto.dart';

/// FCM carries references only. Plaintext is obtained on the recipient device.
class ChatNotifications {
  static const _native = MethodChannel('mx.nexolocal/chat-notifications');
  static final Set<String> _shortcuts = {};
  static Future<void> prepareShortcut(
    String account,
    String id,
    String name,
    String? photoUrl, {
    Uint8List? image,
  }) async {
    final signature = '$account:$id:$name:$photoUrl';
    if (_shortcuts.contains(signature)) return;
    try {
      final avatar = image ?? await _avatar(photoUrl);
      await _native.invokeMethod<void>('shortcut', {
        'id': 'chat:$account:$id',
        'name': name,
        'link': 'nexolocal://chat/$id',
        if (avatar != null) 'avatar': avatar,
      });
      // Retry a missing/failed photo on the next inbox refresh.
      if (avatar != null) _shortcuts.add(signature);
    } catch (_) {
      /* Background engine uses shortcuts prepared by the main app. */
    }
  }

  static final plugin = local.FlutterLocalNotificationsPlugin();
  static Future<void>? _initializing;
  static void Function(String link)? onOpen;
  static final Set<String> _processing = {};

  /// Evaluated at display time, not when the push first arrives.
  static bool Function(String conversation)? isViewing;
  static final Map<String, String> _read = {};

  static bool shouldDisplay(String account, String conversation, String message, {String? persistedRead}) =>
      isViewing?.call(conversation) != true &&
      !_wasRead(message, _read['$account:$conversation']) &&
      !_wasRead(message, persistedRead);

  static bool _wasRead(String message, String? watermark) {
    if (watermark == null) return false;
    if (message == watermark) return true;
    // API message IDs are UUIDv7: lexical order is chronological. Legacy IDs
    // without this guarantee only use exact matching.
    final ordered = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return ordered.hasMatch(message) &&
        ordered.hasMatch(watermark) &&
        message.toLowerCase().compareTo(watermark.toLowerCase()) <= 0;
  }

  static Future<void> confirmRead(String account, String conversation, String message) async {
    _read['$account:$conversation'] = message;
    await TokenStorage().writeChatRead(account, conversation, message);
    await dismiss(conversation);
  }

  static Future<bool> _displayAllowed(String account, String conversation, String message) async {
    final read = await TokenStorage().readChatRead(account, conversation);
    return shouldDisplay(account, conversation, message, persistedRead: read);
  }

  static Future<void> init() => _initializing ??= _initialize();
  static Future<void> _initialize() async {
    await plugin.initialize(
      const local.InitializationSettings(android: local.AndroidInitializationSettings('ic_chat_notification')),
      onDidReceiveNotificationResponse: (response) {
        final link = response.payload;
        if (link != null && Routes.fromDeepLink(link) != null) onOpen?.call(link);
      },
    );
  }

  static Future<String?> initialLink() async {
    await init();
    final details = await plugin.getNotificationAppLaunchDetails();
    return details?.didNotificationLaunchApp == true ? details?.notificationResponse?.payload : null;
  }

  static String preview(String kind, String text) => switch (kind) {
    'image' => '\u{1f4f7} Foto',
    'audio' => '\u{1f3a4} Nota de voz',
    'text' => text.trim().isEmpty ? 'Nuevo mensaje' : text.trim(),
    _ => 'Nuevo mensaje',
  };

  static Future<void> show(Map<String, dynamic> data) async {
    final link = data['deepLink']?.toString();
    final route = Routes.fromDeepLink(link);
    final id = route != null && route.startsWith('/chat/') ? route.substring(6) : null;
    if (id == null || !RegExp(r'^[a-fA-F0-9-]{36}$').hasMatch(id) || !_processing.add(id)) return;
    if (isViewing?.call(id) == true) {
      await dismiss(id);
      return;
    }
    ChatVault? vault;
    final dio = Dio(
      BaseOptions(
        baseUrl: Env.apiBaseUrl,
        connectTimeout: const Duration(seconds: 6),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
    try {
      final storage = TokenStorage();
      var tokens = await storage.read();
      if (tokens != null && tokens.expiresAt.isBefore(DateTime.now().add(const Duration(seconds: 30)))) {
        try {
          tokens = await storage.refreshCoordinated(tokens, refreshTokens);
        } catch (_) {
          // Keep the existing session; failed network is not logout.
        }
      }
      if (tokens == null) return;
      final account = TokenClaims.decode(tokens.accessToken).sub;
      // Do not display an old account's notification after switching accounts.
      if (account == null || data['accountId'] != account) return;
      dio.options.headers['Authorization'] = 'Bearer ${tokens.accessToken}';
      await init();
      try {
        final response = await dio.get<Map<String, dynamic>>(
          '/v1/engagement/conversations/$id/messages',
          queryParameters: {'limit': 10},
        );
        final json = response.data!;
        if (json['blocked'] == true) return;
        final counterpart = Map<String, dynamic>.from(json['counterpart'] as Map);
        final messages = (json['items'] as List? ?? []).whereType<Map>();
        final message = messages.where((m) => m['mine'] != true && m['kind'] != 'system').firstOrNull;
        if (message == null) return;
        if (message['kind'] == 'deleted') {
          await dismiss(id);
          return;
        }
        final messageId = '${message['messageId']}';
        if (!await _displayAllowed(account, id, messageId)) {
          await dismiss(id);
          return;
        }
        var kind = '${message['kind']}';
        var text = message['text'] as String? ?? '';
        if (kind == 'encrypted') {
          vault = await ChatVault.open(account);
          final saved = await vault.transaction((state) async => state['device']);
          if (saved == null) throw StateError('Device not prepared');
          final device = int.parse(saved);
          final crypto = SignalChatCrypto(vault, account, device);
          final payload = message['encrypted'] as Map?;
          final envelopes = (payload?['envelopes'] as List? ?? []).whereType<Map>();
          final selected = envelopes
              .where((e) => e['recipient'] == account && e['recipientDevice'] == device)
              .firstOrNull;
          if (selected == null) throw StateError('Message not for this device');
          final content = await crypto.decrypt(
            conversation: id,
            sender: '${message['senderId']}',
            envelope: Map<String, dynamic>.from(selected),
          );
          kind = '${content['kind']}';
          text = content['text'] as String? ?? '';
        }
        final current = await TokenStorage().read();
        if (current == null || TokenClaims.decode(current.accessToken).sub != account) return;
        final name = (counterpart['displayName'] as String? ?? '').trim();
        final body = preview(kind, text);
        final avatar = await _avatar(counterpart['photoUrl'] as String?);
        final stillSignedIn = await TokenStorage().read();
        if (stillSignedIn == null || TokenClaims.decode(stillSignedIn.accessToken).sub != account) return;
        await prepareShortcut(account, id, name, counterpart['photoUrl'] as String?, image: avatar);
        final person = local.Person(
          name: name.isEmpty ? 'Contacto de Nexo Local' : name,
          key: '${counterpart['accountId'] ?? counterpart['id']}',
          icon: avatar == null ? null : local.ByteArrayAndroidIcon(avatar),
        );
        if (!await _displayAllowed(account, id, messageId)) {
          await dismiss(id);
          return;
        }
        await plugin.show(
          _id(id),
          person.name,
          body,
          local.NotificationDetails(
            android: local.AndroidNotificationDetails(
              'nexo_chat_private_v1',
              'Mensajes',
              channelDescription: 'Conversaciones de Nexo Local',
              importance: local.Importance.high,
              priority: local.Priority.high,
              category: local.AndroidNotificationCategory.message,
              shortcutId: 'chat:$account:$id',
              visibility: local.NotificationVisibility.private,
              color: const Color(0xFF196C60),
              largeIcon: avatar == null ? null : local.ByteArrayAndroidBitmap(avatar),
              onlyAlertOnce: true,
              autoCancel: true,
              subText: 'Nexo Local',
              styleInformation: local.MessagingStyleInformation(
                const local.Person(name: 'T\u00fa'),
                conversationTitle: person.name,
                groupConversation: false,
                messages: [local.Message(body, DateTime.tryParse('${message['createdAt']}') ?? DateTime.now(), person)],
              ),
            ),
          ),
          payload: link,
        );
        // Opening/reading while Android was posting must win over a late push.
        if (!await _displayAllowed(account, id, messageId)) await dismiss(id);
        // Delivery means the device fetched the message; never imply it was read.
        try {
          await dio.post<void>(
            '/v1/engagement/conversations/$id/delivered',
            data: {'upToMessageId': message['messageId']},
          );
        } catch (_) {
          /* Retry delivery when opening the app. */
        }
      } on DioException catch (e) {
        if (e.response?.statusCode == 403 || e.response?.statusCode == 404) return;
        await _fallback(id, link!, account);
      } catch (_) {
        await _fallback(id, link!, account);
      }
    } finally {
      await vault?.close();
      dio.close();
      _processing.remove(id);
    }
  }

  static int _id(String value) => value.codeUnits.fold(0, (a, b) => (a * 31 + b) & 0x7fffffff);
  static Future<void> dismiss(String id) async {
    await init();
    await plugin.cancel(_id(id));
  }

  static Future<void> clear() async {
    await init();
    await plugin.cancelAll();
    _shortcuts.clear();
    _read.clear();
    isViewing = null;
    try {
      await _native.invokeMethod<void>('clear');
    } catch (_) {}
  }

  static Future<void> _fallback(String id, String link, String account) async {
    final current = await TokenStorage().read();
    if (current == null || TokenClaims.decode(current.accessToken).sub != account || isViewing?.call(id) == true) {
      return;
    }
    await plugin.show(
      _id(id),
      'Nexo Local',
      'Tienes un mensaje nuevo. Abre el chat para leerlo.',
      const local.NotificationDetails(
        android: local.AndroidNotificationDetails(
          'nexo_chat_private_v1',
          'Mensajes',
          importance: local.Importance.high,
          priority: local.Priority.high,
          visibility: local.NotificationVisibility.private,
        ),
      ),
      payload: link,
    );
  }

  @visibleForTesting
  static bool allowsAvatarUrl(Uri uri, {required bool release}) =>
      Env.isSecureBaseUrl(uri.toString(), release: release);

  static Future<Uint8List?> _avatar(String? url) async {
    final source = Uri.tryParse(url ?? '');
    if (source == null || (url ?? '').isEmpty) return null;
    final uri = source.hasScheme ? source : Uri.parse(Env.apiBaseUrl).resolveUri(source);
    if (!allowsAvatarUrl(uri, release: kReleaseMode)) return null;
    final client = Dio(
      BaseOptions(connectTimeout: const Duration(seconds: 3), receiveTimeout: const Duration(seconds: 3)),
    );
    final cancellation = CancelToken();
    try {
      var target = uri;
      Response<List<int>> response;
      for (var redirects = 0; ; redirects++) {
        response = await client.get<List<int>>(
          target.toString(),
          cancelToken: cancellation,
          options: Options(
            responseType: ResponseType.bytes,
            followRedirects: false,
            validateStatus: (status) => status != null && status >= 200 && status < 400,
          ),
          onReceiveProgress: (n, total) {
            if (n > 5 * 1024 * 1024) cancellation.cancel();
          },
        );
        if (response.statusCode! < 300) break;
        final location = response.headers.value('location');
        if (redirects >= 3 || location == null) return null;
        target = target.resolve(location);
        if (!allowsAvatarUrl(target, release: kReleaseMode)) return null;
      }
      final bytes = response.data;
      if (bytes == null || bytes.length > 5 * 1024 * 1024) return null;
      final codec = await ui.instantiateImageCodec(Uint8List.fromList(bytes), targetWidth: 128, allowUpscaling: false);
      try {
        final frame = await codec.getNextFrame();
        try {
          final png = await frame.image.toByteData(format: ui.ImageByteFormat.png);
          return png?.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes);
        } finally {
          frame.image.dispose();
        }
      } finally {
        codec.dispose();
      }
    } catch (_) {
      return null;
    } finally {
      client.close();
    }
  }
}
