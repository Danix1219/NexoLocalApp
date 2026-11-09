import 'dart:convert';

class AuthTokens {
  const AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;

  /// Respuesta OAuth de `POST /connect/token`. Si una renovación no trajera
  /// refresh nuevo, se conserva [fallbackRefresh].
  factory AuthTokens.fromOAuth(Map<String, dynamic> j, {String? fallbackRefresh}) {
    final secs = (j['expires_in'] as num?)?.toInt() ?? 600;
    return AuthTokens(
      accessToken: j['access_token'] as String,
      refreshToken: (j['refresh_token'] as String?) ?? fallbackRefresh ?? '',
      expiresAt: DateTime.now().add(Duration(seconds: secs)),
    );
  }

  /// Respuesta de `POST /v1/identity/accounts`. Acepta camelCase (contrato) o
  /// snake_case, y también tokens anidados en `tokens`. Si no vienen, null.
  static AuthTokens? tryFromAccount(Map<String, dynamic> j) {
    final src = j['tokens'] is Map<String, dynamic> ? j['tokens'] as Map<String, dynamic> : j;
    final access = (src['accessToken'] ?? src['access_token']) as String?;
    final refresh = (src['refreshToken'] ?? src['refresh_token']) as String?;
    if (access == null || refresh == null) return null;
    final secs = ((src['expiresInSeconds'] ?? src['expires_in']) as num?)?.toInt() ?? 600;
    return AuthTokens(
      accessToken: access,
      refreshToken: refresh,
      expiresAt: DateTime.now().add(Duration(seconds: secs)),
    );
  }
}

/// Claims que la app lee del access token. Son solo una pista para la UI: el
/// servidor vuelve a autorizar cada petición (constitución §2).
class TokenClaims {
  const TokenClaims({this.sub, this.mode = 'client', this.hasProvider = false});

  final String? sub;
  final String mode;
  final bool hasProvider;

  static TokenClaims decode(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length < 2) return const TokenClaims();
      final payload =
          utf8.decode(base64Url.decode(base64Url.normalize(parts[1])));
      final m = jsonDecode(payload) as Map<String, dynamic>;
      final hp = m['has_provider'];
      return TokenClaims(
        sub: m['sub']?.toString(),
        mode: m['mode']?.toString() == 'provider' ? 'provider' : 'client',
        hasProvider: hp == true || hp?.toString().toLowerCase() == 'true',
      );
    } catch (_) {
      return const TokenClaims();
    }
  }
}
