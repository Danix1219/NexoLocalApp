import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/auth/session_controller.dart';
import '../../core/chat/chat_vault.dart';
import '../../data/api_provider.dart';
import '../../data/models.dart';
import '../../data/nexo_api.dart';

enum ChatSendState { queued, sending, failed, sent }

class LocalChatMessage {
  LocalChatMessage({required this.id, required this.text, this.bytes, this.type}) : createdAt = DateTime.now();
  final String id;
  final String text;
  final Uint8List? bytes;
  final String? type;
  final DateTime createdAt;
  ChatSendState status = ChatSendState.queued;
  String? serverId;
  Message get message => Message(
    id: serverId ?? id,
    kind: type == null
        ? 'text'
        : type!.startsWith('image/')
        ? 'image'
        : 'audio',
    text: text,
    mine: true,
    createdAt: createdAt,
  );
}

final chatExperienceProvider = Provider<ChatExperience>((ref) {
  ref.watch(sessionProvider.select((s) => s.accountId));
  final experience = ChatExperience(
    api: () => ref.read(apiProvider),
    vault: () => ref.read(privateChatVaultProvider.future),
    prepare: (id) async {
      final api = ref.read(apiProvider);
      var thread = await api.messages(id);
      if (!thread.encrypted && const bool.fromEnvironment('CHAT_E2EE', defaultValue: true)) {
        await ref.read(privateChatProvider.future);
        await api.enablePrivateChat(id);
        thread = await api.messages(id);
      }
      return thread;
    },
  );
  experience.download = (conversation, file) async =>
      (await ref.read(privateChatProvider.future)).downloadAttachment(conversation, file);
  ref.onDispose(experience.dispose);
  return experience;
});

/// Account-scoped presentation and outbox. Plaintext media never reaches disk.
class ChatExperience extends ChangeNotifier {
  ChatExperience({required this.api, required this.vault, required this.prepare});
  final NexoApi Function() api;
  final Future<ChatVault> Function() vault;
  final Future<ChatThread> Function(String) prepare;
  final _threads = <String, ChatThread>{};
  final _pending = <String, List<LocalChatMessage>>{};
  final _running = <String>{};
  final _prepared = <String>{};
  final _loaded = <String>{};
  final _media = <String, Uint8List>{};
  final _saved = <String, String>{};
  final _loading = <String, Future<void>>{};
  final _failures = <String, int>{};
  final _queue = <(String, Map<String, dynamic>)>[];
  final _fetched = <String>{};
  int _workers = 0;
  bool _disposed = false;

  /// Descarga y descifra un adjunto; sin esto no hay precarga.
  Future<Uint8List> Function(String conversation, Map<String, dynamic> file)? download;

  static const _memoryLimit = 40 * 1024 * 1024;
  ChatThread? thread(String id) => _threads[id];
  List<LocalChatMessage> pending(String id) => List.unmodifiable(_pending[id] ?? const []);

  void seed(String id, Counterpart counterpart) {
    _threads.putIfAbsent(id, () => ChatThread(id: id, counterpart: counterpart, messages: const []));
  }

  Future<void> restore(String id) async {
    if (_loaded.contains(id) || _threads[id]?.messages.isNotEmpty == true) return;
    try {
      final store = await vault();
      final raw = await store.transaction((state) async => state['history-ui:$id']);
      if (_disposed || raw == null || _loaded.contains(id) || _threads[id]?.messages.isNotEmpty == true) return;
      final value = jsonDecode(raw) as Map<String, dynamic>;
      _threads[id] = decodeHistory(id, value);
      notifyListeners();
    } catch (_) {
      /* First sync remains authoritative; never replace an unreadable vault. */
    }
  }

  void confirmMutation(String conversation, String id, {String? text}) {
    final thread = _threads[conversation];
    if (thread == null) return;
    final messages = thread.messages
        .map(
          (m) => m.id != id
              ? m
              : Message(
                  id: m.id,
                  kind: text == null ? 'deleted' : 'text',
                  text: text ?? '',
                  mine: m.mine,
                  senderId: m.senderId,
                  createdAt: m.createdAt,
                  deliveredAt: m.deliveredAt,
                  readAt: m.readAt,
                  editedAt: DateTime.now(),
                  encryptedPayload: text == null ? null : m.encryptedPayload,
                ),
        )
        .toList();
    remember(
      ChatThread(
        id: thread.id,
        counterpart: thread.counterpart,
        messages: messages,
        encrypted: thread.encrypted,
        peerAccountId: thread.peerAccountId,
        activeOrder: thread.activeOrder,
        blocked: thread.blocked,
        canSend: thread.canSend,
        quickReplies: thread.quickReplies,
        hasMore: thread.hasMore,
        nextCursor: thread.nextCursor,
      ),
    );
  }

  void remember(ChatThread thread) {
    if (_disposed) return;
    final previous = _threads[thread.id];
    for (final deleted in thread.messages.where((m) => m.kind == 'deleted')) {
      final old = previous?.messages.where((m) => m.id == deleted.id).firstOrNull;
      if (old?.privateAttachment != null) _wipe(_media.remove('${thread.id}:${old!.privateAttachment!['id']}'));
    }
    _threads[thread.id] = thread;
    _loaded.add(thread.id);
    if (thread.encrypted) _prepared.add(thread.id);
    final confirmed = thread.messages.map((m) => m.id).toSet();
    final removed = (_pending[thread.id] ?? const <LocalChatMessage>[])
        .where((m) => m.serverId != null && confirmed.contains(m.serverId))
        .toList();
    _pending[thread.id]?.removeWhere(removed.contains);
    for (final message in removed) {
      _wipe(message.bytes);
    }
    notifyListeners();
    unawaited(_persist(thread));
    _prefetch(thread);
  }

  /// Fotos y notas de voz se piden en cuanto llega el hilo, de la más nueva a
  /// la más antigua, para que ya estén listas al verlas o reproducirlas.
  void _prefetch(ChatThread thread) {
    if (download == null) return;
    final wanted = thread.messages.reversed.where((m) => m.privateAttachment?['id'] is String).take(30);
    for (final message in wanted) {
      final file = message.privateAttachment!;
      final key = '${thread.id}:${file['id']}';
      if (_media.containsKey(key) || _loading.containsKey(key) || !_fetched.add(key)) continue;
      _queue.add((thread.id, file));
    }
    while (_workers < 3 && _queue.isNotEmpty) {
      unawaited(_work());
    }
  }

  Future<void> _work() async {
    _workers++;
    try {
      while (!_disposed && _queue.isNotEmpty) {
        final (conversation, file) = _queue.removeAt(0);
        final key = '$conversation:${file['id']}';
        try {
          await _fetch(conversation, file, evict: false);
        } catch (_) {
          // Se vuelve a intentar con la siguiente actualización, dos veces más.
          if ((_failures[key] = (_failures[key] ?? 0) + 1) < 3) _fetched.remove(key);
        }
      }
    } finally {
      _workers--;
    }
  }

  /// Una sola descarga por adjunto aunque lo pidan varios a la vez.
  Future<void> _fetch(String conversation, Map<String, dynamic> file, {required bool evict}) {
    final key = '$conversation:${file['id']}';
    return _loading[key] ??= () async {
      final bytes = await download!(conversation, file);
      try {
        // La precarga no desplaza lo que ya está listo: lo demás queda en disco.
        final used = _media.values.fold<int>(0, (total, value) => total + value.length);
        if (evict || used + bytes.length <= _memoryLimit) cacheMedia(key, bytes);
      } finally {
        bytes.fillRange(0, bytes.length, 0);
      }
    }().whenComplete(() => _loading.remove(key));
  }

  /// Bytes listos para mostrar o reproducir (copia propia de quien los pide).
  Future<Uint8List> loadMedia(String conversation, Map<String, dynamic> file) async {
    final key = '$conversation:${file['id']}';
    final ready = media(key);
    if (ready != null) return ready;
    if (download == null || _disposed) throw StateError('Adjunto no disponible');
    await _fetch(conversation, file, evict: true);
    // La precarga pudo terminar sin dejarlo en memoria: se abre de disco.
    return media(key) ?? await download!(conversation, file);
  }

  Future<void> _persist(ChatThread thread) async {
    final raw = jsonEncode(encodeHistory(thread));
    if (_saved[thread.id] == raw) return;
    _saved[thread.id] = raw;
    try {
      final store = await vault();
      if (_disposed || _saved[thread.id] != raw) return;
      await store.transaction((state) async {
        state['history-ui:${thread.id}'] = raw;
        final histories = state.keys.where((key) => key.startsWith('history-ui:')).toList();
        for (final key in histories.take((histories.length - 15).clamp(0, histories.length))) {
          state.remove(key);
        }
      });
    } catch (_) {
      _saved.remove(thread.id);
    }
  }

  LocalChatMessage enqueue(String conversation, {String text = '', Uint8List? bytes, String? type}) {
    if (_disposed) throw StateError('La sesion cambio');
    final message = LocalChatMessage(
      id: 'local:${const Uuid().v4()}',
      text: text.trim(),
      bytes: bytes == null ? null : Uint8List.fromList(bytes),
      type: type,
    );
    _pending.putIfAbsent(conversation, () => []).add(message);
    notifyListeners();
    unawaited(_pump(conversation));
    return message;
  }

  void retry(String conversation, LocalChatMessage message) {
    if (_disposed || message.status != ChatSendState.failed) return;
    message.status = ChatSendState.queued;
    notifyListeners();
    unawaited(_pump(conversation));
  }

  Future<void> _pump(String id) async {
    if (_disposed || !_running.add(id)) return;
    try {
      while (!_disposed) {
        final waiting = (_pending[id] ?? const <LocalChatMessage>[]).where((m) => m.status != ChatSendState.sent);
        if (waiting.isEmpty || waiting.first.status == ChatSendState.failed) break;
        final local = waiting.first;
        local.status = ChatSendState.sending;
        notifyListeners();
        try {
          if (!_prepared.contains(id)) {
            final latest = await prepare(id);
            if (_disposed) return;
            remember(latest);
            if (latest.blocked || !latest.canSend) throw StateError('Conversacion no disponible');
            if (const bool.fromEnvironment('CHAT_E2EE', defaultValue: true) && !latest.encrypted) {
              throw StateError('La conexion segura aun no esta lista');
            }
            _prepared.add(id);
          }
          if (_disposed) return;
          final message = local.bytes == null
              ? await api().sendMessage(id, text: local.text)
              : await api().sendPrivateAttachment(
                  id,
                  local.bytes!,
                  local.type!,
                  caption: local.text,
                  clientMessageId: local.id,
                );
          if (_disposed) return;
          local.serverId = message.id;
          local.status = ChatSendState.sent;
          if (local.bytes != null && message.privateAttachment?['id'] is String) {
            cacheMedia('$id:${message.privateAttachment!['id']}', local.bytes!);
          }
          if (_threads[id]?.messages.any((m) => m.id == message.id) == true) {
            _pending[id]?.remove(local);
            _wipe(local.bytes);
          }
          notifyListeners();
          unawaited(api().messages(id).then(remember).catchError((Object _) {}));
        } catch (_) {
          if (_disposed) return;
          local.status = ChatSendState.failed;
          notifyListeners();
          break;
        }
      }
    } finally {
      _running.remove(id);
    }
  }

  Uint8List? media(String key) {
    final value = _media.remove(key);
    if (value == null) return null;
    _media[key] = value;
    return Uint8List.fromList(value);
  }

  void cacheMedia(String key, Uint8List bytes) {
    if (_disposed || bytes.length > 5 * 1024 * 1024) return;
    _wipe(_media.remove(key));
    _media[key] = Uint8List.fromList(bytes);
    while (_media.values.fold<int>(0, (total, bytes) => total + bytes.length) > _memoryLimit) {
      _wipe(_media.remove(_media.keys.first));
    }
  }

  static void _wipe(Uint8List? bytes) {
    if (bytes == null) return;
    PaintingBinding.instance.imageCache.evict(MemoryImage(bytes), includeLive: true);
    bytes.fillRange(0, bytes.length, 0);
  }

  @override
  void dispose() {
    _disposed = true;
    for (final list in _pending.values) {
      for (final m in list) {
        _wipe(m.bytes);
      }
    }
    for (final bytes in _media.values) {
      _wipe(bytes);
    }
    _pending.clear();
    _queue.clear();
    _media.clear();
    _threads.clear();
    _saved.clear();
    super.dispose();
  }

  static Map<String, dynamic> encodeHistory(ChatThread t) => {
    'counterpart': {
      'id': t.counterpart.id,
      'displayName': t.counterpart.displayName,
      'photoUrl': t.counterpart.photoUrl,
      'kind': t.counterpart.kind,
      'providerId': t.counterpart.providerId,
    },
    'encrypted': t.encrypted,
    'peerAccountId': t.peerAccountId,
    'blocked': t.blocked,
    'canSend': t.canSend,
    'quickReplies': t.quickReplies,
    'hasMore': t.hasMore,
    'nextCursor': t.nextCursor,
    if (t.activeOrder != null)
      'activeOrder': {
        'orderId': t.activeOrder!.orderId,
        'status': t.activeOrder!.status,
        'statusText': t.activeOrder!.statusText,
      },
    'items': t.messages
        .skip((t.messages.length - 100).clamp(0, t.messages.length))
        .map(
          (m) => {
            'messageId': m.id,
            'kind': m.kind,
            'text': m.text,
            'mine': m.mine,
            'createdAt': m.createdAt?.toUtc().toIso8601String(),
            'readAt': m.readAt?.toUtc().toIso8601String(),
            'editedAt': m.editedAt?.toUtc().toIso8601String(),
            'deliveredAt': m.deliveredAt?.toUtc().toIso8601String(),
            'senderId': m.senderId,
            'encrypted': m.encryptedPayload,
            'file': m.privateAttachment,
            'imageUrl': m.imageUrl,
            if (m.orderId != null || m.systemType != null) 'system': {'orderId': m.orderId, 'type': m.systemType},
          },
        )
        .toList(),
  };

  static ChatThread decodeHistory(String id, Map<String, dynamic> j) => ChatThread(
    id: id,
    counterpart: Counterpart.fromJson(Map<String, dynamic>.from(j['counterpart'] as Map)),
    encrypted: j['encrypted'] == true,
    peerAccountId: j['peerAccountId'] as String?,
    blocked: j['blocked'] == true,
    canSend: j['canSend'] == true,
    hasMore: j['hasMore'] == true,
    nextCursor: j['nextCursor'] as String?,
    quickReplies: (j['quickReplies'] as List? ?? []).cast<String>(),
    activeOrder: ActiveOrder.fromJson(
      j['activeOrder'] == null ? null : Map<String, dynamic>.from(j['activeOrder'] as Map),
    ),
    messages: (j['items'] as List).map((item) {
      final row = Map<String, dynamic>.from(item as Map);
      final m = Message.fromJson(row);
      return Message(
        id: m.id,
        kind: m.kind,
        text: m.text,
        mine: m.mine,
        createdAt: m.createdAt,
        readAt: m.readAt,
        editedAt: m.editedAt,
        deliveredAt: m.deliveredAt,
        senderId: m.senderId,
        encryptedPayload: m.encryptedPayload,
        imageUrl: m.imageUrl,
        systemType: m.systemType,
        orderId: m.orderId,
        privateAttachment: row['file'] == null ? null : Map<String, dynamic>.from(row['file'] as Map),
      );
    }).toList(),
  );
}
