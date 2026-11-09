import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../local/sync_controller.dart';
import 'auth_tokens.dart';
import 'token_storage.dart';

/// `guest`: "Explorar sin cuenta" (7.14). Ve inicio y búsqueda; contactar,
/// guardar y publicar le piden cuenta.
enum SessionStatus { unknown, signedOut, guest, signedIn }

class SessionState {
  const SessionState({
    required this.status,
    this.accountId,
    this.mode = 'client',
    this.hasProvider = false,
    this.name,
  });

  const SessionState.unknown() : this(status: SessionStatus.unknown);
  const SessionState.signedOut() : this(status: SessionStatus.signedOut);
  const SessionState.guest() : this(status: SessionStatus.guest);

  factory SessionState.fromTokens(AuthTokens t, {String? name, String? modeOverride}) {
    final c = TokenClaims.decode(t.accessToken);
    return SessionState(
      status: SessionStatus.signedIn,
      accountId: c.sub,
      mode: modeOverride ?? c.mode,
      hasProvider: c.hasProvider,
      name: name,
    );
  }

  final SessionStatus status;
  final String? accountId;

  /// `client` | `provider`.
  final String mode;
  final bool hasProvider;

  /// Se conoce al registrarse o al cargar Cuenta (`/v1/screens/account`).
  final String? name;

  bool get isSignedIn => status == SessionStatus.signedIn;
  bool get isGuest => status == SessionStatus.guest;
  bool get isProviderMode => isSignedIn && mode == 'provider';

  SessionState copyWith({String? mode, bool? hasProvider, String? name}) => SessionState(
        status: status,
        accountId: accountId,
        mode: mode ?? this.mode,
        hasProvider: hasProvider ?? this.hasProvider,
        name: name ?? this.name,
      );
}

/// Sesión siempre viva: se restaura del almacenamiento seguro al abrir la app
/// y el interceptor la renueva en silencio (ver api_client.dart).
class SessionController extends Notifier<SessionState> {
  TokenStorage get _storage => ref.read(tokenStorageProvider);

  @override
  SessionState build() {
    Future.microtask(_restore);
    return const SessionState.unknown();
  }

  Future<void> _restore() async {
    try {
      final t = await _storage.read();
      if (t == null) {
        state = const SessionState.signedOut();
        return;
      }
      state = SessionState.fromTokens(t,
          name: await _storage.readName(), modeOverride: await _storage.readMode());
    } catch (_) {
      state = const SessionState.signedOut();
    }
  }

  Future<void> signIn(AuthTokens tokens, {String? name}) async {
    await _storage.write(tokens);
    await _storage.writeName(name);
    await _storage.writeMode(null);
    state = SessionState.fromTokens(tokens, name: name);
  }

  /// Tras una renovación: mode/has_provider se releen del token nuevo, salvo
  /// que el modo se haya elegido en la app (backend de cuenta aún de prueba).
  Future<void> updateTokens(AuthTokens tokens) async {
    await _storage.write(tokens);
    if (state.isSignedIn) {
      state = SessionState.fromTokens(tokens, name: state.name, modeOverride: await _storage.readMode());
    }
  }

  /// Cambio de modo cliente ⇄ prestador. Si el backend devolvió tokens con
  /// el claim nuevo se usan; si no, el modo se guarda en el teléfono.
  Future<void> setMode(String mode, {AuthTokens? tokens, bool? hasProvider}) async {
    if (tokens != null) {
      await _storage.write(tokens);
      await _storage.writeMode(null);
      state = SessionState.fromTokens(tokens, name: state.name);
      return;
    }
    await _storage.writeMode(mode);
    state = state.copyWith(mode: mode, hasProvider: hasProvider);
  }

  Future<void> setName(String name) async {
    if (!state.isSignedIn || name.isEmpty || name == state.name) return;
    await _storage.writeName(name);
    state = state.copyWith(name: name);
  }

  void enterGuest() => state = const SessionState.guest();

  /// Del modo visitante a crear cuenta o iniciar sesión.
  void leaveGuest() {
    if (state.isGuest) state = const SessionState.signedOut();
  }

  /// Cierre local: borra credenciales y datos de la cuenta del dispositivo.
  Future<void> signOutLocal() async {
    // Caché y cola de esta cuenta fuera del teléfono (constitución §4).
    final id = state.accountId;
    if (id != null) {
      try {
        await (await ref.read(localStoreProvider)).purgeAccount(id);
      } catch (_) {}
    }
    await _storage.clear();
    state = const SessionState.signedOut();
  }
}

final sessionProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);
