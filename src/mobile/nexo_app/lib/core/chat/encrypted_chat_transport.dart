import '../local/file_cache.dart';
import 'dart:typed_data';
import 'package:libsignal/libsignal.dart';
import 'chat_vault.dart';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../network/api_client.dart';
import 'signal_chat_crypto.dart';

/// Ciphertext-only transport. Never falls back to the legacy text/image API.
class EncryptedChatTransport {
  EncryptedChatTransport(this.dio, this.crypto, {this.files});

  /// Adjuntos ya descargados, tal como viajaron (cifrados).
  final FileCache? files;
  final Dio dio;
  final SignalChatCrypto crypto;
  static const root = '/v1/engagement/chat-keys';
  Options options({String? key}) =>
      Options(extra: const {kAuth: true}, headers: {if (key != null) 'Idempotency-Key': key});

  Future<Map<String, dynamic>> uploadAttachment(String conversation, Uint8List bytes, String type) async {
    if (!['image/jpeg', 'image/png', 'image/webp', 'audio/wav'].contains(type) ||
        (type != 'audio/wav' && bytes.length > 5 * 1024 * 1024) ||
        bytes.isEmpty) {
      throw StateError('Archivo no compatible o demasiado grande');
    }
    if (type == 'audio/wav' && bytes.length > 1024 * 1024) {
      final chunks = <Map<String, dynamic>>[];
      for (var offset = 0; offset < bytes.length; offset += 1024 * 1024) {
        final end = (offset + 1024 * 1024).clamp(0, bytes.length);
        chunks.add(await uploadAttachment(conversation, Uint8List.sublistView(bytes, offset, end), type));
      }
      return {'id': const Uuid().v4(), 'version': 2, 'chunks': chunks, 'type': type, 'size': bytes.length};
    }
    final id = const Uuid().v4();
    final key = ChatVault.randomBytes(32);
    final nonce = ChatVault.randomBytes(12);
    final cipher = Aes256GcmSiv(key: key.toList());
    try {
      final ciphertext = cipher.encrypt(
        plaintext: bytes.toList(),
        nonce: nonce.toList(),
        associatedData: utf8.encode('nexo-private-file-v1:$conversation:$id'),
      );
      await dio.put<void>(
        '$root/conversations/$conversation/attachments/$id',
        data: Uint8List.fromList(ciphertext),
        options: Options(
          extra: const {kAuth: true},
          contentType: 'application/octet-stream',
          responseType: ResponseType.plain,
          sendTimeout: const Duration(seconds: 60),
          receiveTimeout: const Duration(seconds: 60),
          headers: {'Content-Length': ciphertext.length},
        ),
      );
      return {'id': id, 'key': base64Encode(key), 'nonce': base64Encode(nonce), 'type': type, 'size': bytes.length};
    } finally {
      cipher.dispose();
      key.fillRange(0, key.length, 0);
    }
  }

  Future<Uint8List> downloadAttachment(String conversation, Map<String, dynamic> file) async {
    if (file['version'] == 2) {
      if (file['type'] != 'audio/wav' ||
          file['chunks'] is! List ||
          file['size'] is! int ||
          (file['size'] as int) <= 0) {
        throw StateError('Audio invalido');
      }
      final chunks = (file['chunks'] as List).cast<Map>();
      var total = 0;
      for (final chunk in chunks) {
        if (chunk['version'] != null ||
            chunk['type'] != 'audio/wav' ||
            chunk['size'] is! int ||
            (chunk['size'] as int) <= 0 ||
            (chunk['size'] as int) > 1024 * 1024) {
          throw StateError('Bloque de audio invalido');
        }
        total += chunk['size'] as int;
      }
      if (total != file['size'] || chunks.isEmpty) throw StateError('Audio incompleto');
      final result = Uint8List(total);
      var offset = 0;
      try {
        for (final chunk in chunks) {
          final bytes = await downloadAttachment(conversation, Map<String, dynamic>.from(chunk));
          result.setRange(offset, offset + bytes.length, bytes);
          offset += bytes.length;
          bytes.fillRange(0, bytes.length, 0);
        }
        return result;
      } catch (_) {
        result.fillRange(0, result.length, 0);
        rethrow;
      }
    }
    final id = file['id'] as String;
    if (!RegExp(r'^[a-fA-F0-9-]{36}$').hasMatch(id)) throw StateError('Adjunto invalido');
    final key = base64Decode(file['key'] as String);
    final nonce = base64Decode(file['nonce'] as String);
    if (key.length != 32 || nonce.length != 12 || file['size'] is! int || (file['size'] as int) > 5 * 1024 * 1024) {
      throw StateError('Adjunto invalido');
    }
    final cipher = Aes256GcmSiv(key: key.toList());
    Uint8List open(List<int> sealed) {
      final plain = cipher.decrypt(
        ciphertext: sealed,
        nonce: nonce.toList(),
        associatedData: utf8.encode('nexo-private-file-v1:$conversation:$id'),
      );
      if (plain.length != file['size']) {
        plain.fillRange(0, plain.length, 0);
        throw StateError('Adjunto alterado');
      }
      return Uint8List.fromList(plain);
    }

    try {
      // En el teléfono se guarda tal como viaja: cifrado. Abrirlo es local.
      final stored = await files?.read(id);
      if (stored != null) {
        try {
          return open(stored);
        } catch (_) {
          await files?.remove(id);
        }
      }
      final cancellation = CancelToken();
      final response = await dio.get<List<int>>(
        '$root/conversations/$conversation/attachments/$id',
        cancelToken: cancellation,
        options: Options(
          extra: const {kAuth: true},
          responseType: ResponseType.bytes,
          receiveTimeout: const Duration(seconds: 60),
        ),
        onReceiveProgress: (received, total) {
          if (received > 8 * 1024 * 1024) cancellation.cancel('Adjunto demasiado grande');
        },
      );
      final plain = open(response.data!);
      await files?.write(id, response.data!);
      return plain;
    } finally {
      cipher.dispose();
      key.fillRange(0, key.length, 0);
    }
  }

  Future<void> register() async {
    final bundle = await crypto.publicBundle();
    await dio.put<void>('$root/devices', data: bundle, options: options());
  }

  Future<void> enable(String conversation) async {
    await register();
    await dio.post<void>('$root/conversations/$conversation/enable', options: options());
  }

  Future<void> discardDeletedEdit(String conversation, String target) => crypto.vault.transaction((state) async {
    final pending = state['pending:$conversation'];
    if (pending == null) return;
    final saved = jsonDecode(pending) as Map<String, dynamic>;
    if (saved['editTarget'] == target) state.remove('pending:$conversation');
  });

  Future<String> retryPending(String conversation, String peer) async {
    final pending = await crypto.vault.transaction((state) async => state['pending:$conversation']);
    if (pending == null) throw StateError('No hay mensaje pendiente');
    final saved = jsonDecode(pending) as Map<String, dynamic>;
    return send(
      conversation,
      peer,
      Map<String, dynamic>.from(jsonDecode(saved['content'] as String) as Map),
      retryId: saved['id'] as String,
      editTarget: saved['editTarget'] as String?,
    );
  }

  Future<String> send(
    String conversation,
    String peer,
    Map<String, dynamic> content, {
    String? retryId,
    String? editTarget,
  }) async {
    final responses = await Future.wait([
      dio.get<List<dynamic>>('$root/devices', options: options()),
      dio.get<List<dynamic>>('$root/conversations/$conversation/devices', options: options()),
    ]);
    final ownResponse = responses[0];
    final otherResponse = responses[1];
    final own = (ownResponse.data ?? []).cast<int>().where((d) => d != crypto.deviceId);
    final other = (otherResponse.data ?? []).cast<int>();
    if (other.isEmpty) throw StateError('El contacto debe actualizar y preparar su chat privado');
    final savedOperation = await crypto.vault.transaction((state) async {
      final pending = state['pending:$conversation'];
      if (pending != null) {
        final saved = jsonDecode(pending) as Map<String, dynamic>;
        if (saved['content'] != jsonEncode(content) || saved['editTarget'] != editTarget) {
          throw StateError('Reintenta primero el mensaje pendiente antes de enviar otro');
        }
        return saved['id'] as String;
      }
      final id = retryId ?? const Uuid().v4();
      state['pending:$conversation'] = jsonEncode({'id': id, 'content': jsonEncode(content), 'editTarget': editTarget});
      return id;
    });
    final messageId = savedOperation;
    final targets = [(crypto.account, own), (peer, other)];
    final envelopes = <Map<String, dynamic>>[];
    for (final (account, devices) in targets) {
      for (final device in devices) {
        final path = account == crypto.account
            ? '$root/devices/$device/claim'
            : '$root/conversations/$conversation/devices/$device/claim';
        // Only claim when no session exists; consumed keys are never reused.
        final needsKeys = await crypto.vault.transaction(
          (state) async => !state.containsKey('session:$account:$device'),
        );
        Map<String, dynamic>? bundle;
        if (needsKeys) {
          final response = await dio.post<Map<String, dynamic>>(path, options: options());
          bundle = response.data;
        }
        envelopes.add(
          await crypto.encrypt(
            conversation: conversation,
            messageId: messageId,
            recipient: account,
            recipientDevice: device,
            content: content,
            bundle: bundle,
          ),
        );
      }
    }
    // Retain original content in the encrypted vault for the originating device.
    await crypto.vault.transaction((state) async {
      final previous = state['sent:$messageId'];
      final saved = jsonEncode({'conversation': conversation, 'content': content});
      if (previous != null && previous != saved) throw StateError('Identificador reutilizado');
      state['sent:$messageId'] = saved;
    });
    final response = await dio.request<Map<String, dynamic>>(
      '$root/conversations/$conversation/messages${editTarget == null ? '' : '/$editTarget'}',
      data: {'envelopes': envelopes},
      options: options(key: messageId).copyWith(method: editTarget == null ? 'POST' : 'PATCH'),
    );
    final serverId = response.data?['messageId'] as String?;
    if (serverId == null) throw StateError('No se confirmo el envio');
    await crypto.vault.transaction((state) async {
      state['server:$serverId'] = messageId;
      state.remove('pending:$conversation');
    });
    return serverId;
  }

  Future<Map<String, dynamic>> readOwn(String serverId, String conversation, {String? operationId}) =>
      crypto.vault.transaction((state) async {
        final id = operationId ?? state['server:$serverId'];
        final value = id == null ? null : state['sent:$id'];
        if (value == null) throw StateError('Este mensaje no esta disponible en este dispositivo');
        final saved = jsonDecode(value) as Map<String, dynamic>;
        if (saved['conversation'] != conversation) throw StateError('Conversacion invalida');
        return Map<String, dynamic>.from(saved['content'] as Map);
      });
}
