/// Almacenamiento local por cuenta (spec 051 / 016): caché de lecturas para
/// ver lo último sin señal y cola de publicaciones pendientes.
///
/// Todo se guarda separado por `account` y se borra al cerrar sesión,
/// eliminar la cuenta o si el servidor invalida la sesión (constitución §4).
library;

/// Código del error que devuelve la cola: la acción quedó guardada y se
/// enviará al volver la conexión. No es una falla del backend.
const kQueuedOffline = 'client.queued_offline';

class CachedResponse {
  const CachedResponse({required this.body, required this.savedAt, this.etag});
  final String body;
  final String? etag;
  final DateTime savedAt;
}

class OutboxItem {
  const OutboxItem({
    this.id,
    required this.account,
    required this.method,
    required this.path,
    required this.body,
    required this.idempotencyKey,
    required this.createdAt,
    this.attempts = 0,
  });
  final int? id;
  final String account;
  final String method;
  final String path;
  final String body;
  final String idempotencyKey;
  final DateTime createdAt;
  final int attempts;

  OutboxItem withId(int id) => OutboxItem(
        id: id,
        account: account,
        method: method,
        path: path,
        body: body,
        idempotencyKey: idempotencyKey,
        createdAt: createdAt,
        attempts: attempts,
      );
}

abstract class LocalStore {
  /// Respuestas más grandes no se guardan (fotos nunca: solo JSON).
  static const maxBodyBytes = 512 * 1024;

  /// Entradas por cuenta; se borran las más viejas.
  static const maxEntries = 300;

  /// Reintentos de una publicación pendiente antes de descartarla.
  static const maxAttempts = 5;

  Future<CachedResponse?> read(String account, String key);
  Future<void> write(String account, String key, CachedResponse r);
  Future<int> enqueue(OutboxItem item);
  Future<List<OutboxItem>> pending(String account);
  Future<void> removeOutbox(int id);
  Future<void> bumpAttempt(int id);
  Future<void> purgeAccount(String account);
}

/// En memoria: pruebas y respaldo si SQLite no abre.
class MemoryLocalStore implements LocalStore {
  final Map<String, Map<String, CachedResponse>> _cache = {};
  final List<OutboxItem> _outbox = [];
  int _seq = 0;

  @override
  Future<CachedResponse?> read(String account, String key) async => _cache[account]?[key];

  @override
  Future<void> write(String account, String key, CachedResponse r) async {
    if (r.body.length > LocalStore.maxBodyBytes) return;
    final m = _cache.putIfAbsent(account, () => {});
    m[key] = r;
    if (m.length > LocalStore.maxEntries) {
      final oldest = m.entries.reduce((a, b) => a.value.savedAt.isBefore(b.value.savedAt) ? a : b).key;
      m.remove(oldest);
    }
  }

  @override
  Future<int> enqueue(OutboxItem item) async {
    final dup = _outbox.where((o) => o.idempotencyKey == item.idempotencyKey);
    if (dup.isNotEmpty) return dup.first.id!;
    final it = item.withId(++_seq);
    _outbox.add(it);
    return it.id!;
  }

  @override
  Future<List<OutboxItem>> pending(String account) async => [
        for (final o in _outbox)
          if (o.account == account) o,
      ];

  @override
  Future<void> removeOutbox(int id) async => _outbox.removeWhere((o) => o.id == id);

  @override
  Future<void> bumpAttempt(int id) async {
    final i = _outbox.indexWhere((o) => o.id == id);
    if (i < 0) return;
    final o = _outbox[i];
    _outbox[i] = OutboxItem(
      id: o.id,
      account: o.account,
      method: o.method,
      path: o.path,
      body: o.body,
      idempotencyKey: o.idempotencyKey,
      createdAt: o.createdAt,
      attempts: o.attempts + 1,
    );
  }

  @override
  Future<void> purgeAccount(String account) async {
    _cache.remove(account);
    _outbox.removeWhere((o) => o.account == account);
  }
}
