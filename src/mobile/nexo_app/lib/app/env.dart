/// Configuración por entorno. Se pasa con --dart-define al compilar:
///   flutter build apk --dart-define=API_BASE_URL=https://api.ejemplo.com
/// Sin secretos aquí (constitución §6).
class Env {
  Env._();

  /// Backend de producción (Azure, HTTPS). Para el backend en tu PC desde el
  /// emulador: --dart-define=API_BASE_URL=http://10.0.2.2:8080
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://nexolocal-back-a5g4ceagb9fufjb7.northcentralus-01.azurewebsites.net',
  );

  /// Landing con el aviso de privacidad, términos y baja de cuenta (requisito
  /// 16/17 del profesor). Vacío = solo el texto dentro de la app.
  static const landingUrl = String.fromEnvironment('LANDING_URL');

  static String? landingPage(String path) {
    final base = landingUrl.trim();
    if (base.isEmpty || !isSecureBaseUrl(base, release: true)) return null;
    return '${base.endsWith('/') ? base.substring(0, base.length - 1) : base}/$path';
  }

  /// Versión que se informa al registrar el teléfono para push. La pone el
  /// pipeline (--dart-define=APP_VERSION=1.2.3); SemVer.
  static const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '0.3.0');

  /// Cliente OAuth. Vacío (por defecto) = no se envía client_id; el backend
  /// actual responde invalid_client a 'nexo-mobile'.
  static const oauthClientId = String.fromEnvironment('OAUTH_CLIENT_ID');

  static const oauthScope = 'openid offline_access nexo_api';

  /// Modo de fábrica de los grupos de endpoints (spec 045):
  ///   auto = intenta el backend y, si el endpoint aún no existe o no hay
  ///          señal, responde con los datos de la maqueta sin mostrar error.
  ///   live = siempre el backend.   fake = siempre la maqueta.
  /// `auth` (login, registro, contraseña) siempre es real.
  static const apiMode = String.fromEnvironment('API_MODE', defaultValue: 'auto');

  /// Grupos forzados al backend real, p. ej. LIVE=cuenta,perfil (o all).
  static const live = String.fromEnvironment('LIVE');

  /// Grupos forzados a la maqueta, p. ej. FAKE=mensajes.
  static const fake = String.fromEnvironment('FAKE');

  /// En release solo se acepta HTTPS hacia el backend (spec 046, seguridad).
  static bool isSecureBaseUrl(String url, {required bool release}) {
    final u = Uri.tryParse(url);
    if (u == null || !u.hasScheme || u.host.isEmpty) return false;
    if (u.userInfo.isNotEmpty) return false;
    if (u.scheme == 'https') return true;
    if (release) return false;
    const localHosts = {'10.0.2.2', 'localhost', '127.0.0.1'};
    return u.scheme == 'http' && (localHosts.contains(u.host) || u.host.startsWith('192.168.'));
  }

  /// Ubicación de búsqueda por defecto (zona Centro de la maqueta) mientras
  /// no exista el selector de mapa (spec 006/007).
  static const defaultLat = 20.0535;
  static const defaultLng = -99.3425;
  static const defaultZone = 'Centro';
  static const defaultRadiusKm = 10;
}
