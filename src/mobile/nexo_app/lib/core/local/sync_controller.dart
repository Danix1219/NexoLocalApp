import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/session_controller.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';
import 'local_store.dart';
import 'offline_interceptor.dart';
import 'sqflite_store.dart';

/// SQLite si está disponible; si no abre (pruebas, almacenamiento lleno),
/// memoria: la app sigue funcionando, solo sin persistir entre aperturas.
final localStoreProvider = Provider<Future<LocalStore>>((ref) async {
  try {
    return await SqfliteLocalStore.open();
  } catch (_) {
    return MemoryLocalStore();
  }
});

/// `true` cuando el teléfono vuelve a tener red. Se sobreescribe en pruebas.
final connectivityChangesProvider = Provider<Stream<bool>>(
    (ref) => Connectivity().onConnectivityChanged.map((r) => r.any((c) => c != ConnectivityResult.none)));

String accountKey(SessionState s) => s.isSignedIn && s.accountId != null ? s.accountId! : 'guest';

class SyncState {
  const SyncState({this.offlineSince, this.pending = 0});

  /// Hora de lo guardado que se está mostrando sin señal; null = en línea.
  final DateTime? offlineSince;

  /// Publicaciones en la cola esperando señal.
  final int pending;

  bool get offline => offlineSince != null;
}

/// Resultado de enviar la cola (para avisar a la persona).
class SyncReport {
  const SyncReport({this.sent = 0, this.failed = const []});
  final int sent;
  final List<String> failed;
}

/// Cache y cola por cuenta, y reenvío al recuperar la conexión (spec 051).
class SyncController extends Notifier<SyncState> {
  StreamSubscription<bool>? _net;
  AppLifecycleListener? _life;
  bool _flushing = false;

  /// Avisos al usuario (se conectan al toast desde el shell).
  void Function(String message)? notify;

  @override
  SyncState build() {
    _net = ref.read(connectivityChangesProvider).listen((online) {
      if (online) unawaited(flush());
    });
    try {
      _life = AppLifecycleListener(onResume: () => unawaited(flush()));
    } catch (_) {
      // Sin binding (pruebas puras).
    }
    ref.onDispose(() {
      _net?.cancel();
      _life?.dispose();
    });
    ref.listen<bool>(sessionProvider.select((s) => s.isSignedIn), (_, now) {
      if (now) unawaited(flush());
    });
    return const SyncState();
  }

  void markOffline(DateTime savedAt) {
    if (state.offlineSince != savedAt) state = SyncState(offlineSince: savedAt, pending: state.pending);
  }

  void markOnline() {
    if (state.offline) {
      state = SyncState(pending: state.pending);
      unawaited(flush());
    }
  }

  Future<void> queued() async => _refreshPending();

  Future<void> _refreshPending() async {
    final s = ref.read(sessionProvider);
    final items = await (await ref.read(localStoreProvider)).pending(accountKey(s));
    state = SyncState(offlineSince: state.offlineSince, pending: items.length);
  }

  /// Envía la cola de la cuenta actual. Se detiene al primer fallo de red.
  Future<SyncReport> flush() async {
    final s = ref.read(sessionProvider);
    if (_flushing || !s.isSignedIn) return const SyncReport();
    _flushing = true;
    var sent = 0;
    final failed = <String>[];
    try {
      final store = await ref.read(localStoreProvider);
      final dio = ref.read(dioProvider);
      for (final it in await store.pending(accountKey(s))) {
        try {
          await dio.request<dynamic>(
            it.path,
            data: jsonDecode(it.body),
            options: Options(
              method: it.method,
              headers: {'Idempotency-Key': it.idempotencyKey},
              extra: const {kAuth: true, kReplay: true},
            ),
          );
          await store.removeOutbox(it.id!);
          sent++;
        } on DioException catch (e) {
          final res = e.response;
          if (res == null) break; // Sigue sin señal.
          final err = ApiException.fromDio(e);
          final business = !err.code.startsWith('http_') && res.statusCode != 401;
          if (business || it.attempts + 1 >= LocalStore.maxAttempts) {
            await store.removeOutbox(it.id!);
            failed.add(err.detail ?? 'No se pudo publicar una solicitud guardada.');
          } else {
            await store.bumpAttempt(it.id!);
          }
          if (res.statusCode == 401) break;
        }
      }
      await _refreshPending();
    } catch (_) {
      // La próxima reconexión lo vuelve a intentar.
    } finally {
      _flushing = false;
    }
    if (sent > 0)
      notify?.call(sent == 1 ? 'Se publicó tu solicitud guardada.' : 'Se publicaron $sent solicitudes guardadas.');
    for (final f in failed) {
      notify?.call(f);
    }
    return SyncReport(sent: sent, failed: failed);
  }
}

final syncProvider = NotifierProvider<SyncController, SyncState>(SyncController.new);
