/// Which backend the app talks to. Selected at build/run time via a flag:
///
///   flutter run                              # dev — shared dev server
///   flutter run --dart-define=ENV=prod       # prod
///   flutter build apk --dart-define=ENV=prod # prod release build
///
enum AppEnvironment { dev, prod }

/// Resolves backend base URLs from the selected environment.
///
/// Resolution order for each URL:
///   1. explicit override  (--dart-define=API_BASE_URL / AUTH_BASE_URL)
///   2. environment default (dev → local host, prod → PROD_BASE_URL)
class ApiConfig {
  // ─── Flags (compile-time constants injected via --dart-define) ──────────────

  static const String _envName = String.fromEnvironment('ENV', defaultValue: 'dev');

  /// Full base-URL overrides. Win over everything — handy for a physical device
  /// on the LAN, a staging host, etc.:
  ///   --dart-define=API_BASE_URL=http://192.168.1.42
  static const String _apiOverride = String.fromEnvironment('API_BASE_URL');
  static const String _authOverride = String.fromEnvironment('AUTH_BASE_URL');

  /// Prod entry point (single nginx host over HTTPS). Override per build:
  ///   --dart-define=PROD_BASE_URL=https://api.yourdomain.com
  static const String _prodBase = String.fromEnvironment(
    'PROD_BASE_URL',
    defaultValue: 'https://api.gymboss.app',
  );

  // ─── Environment ────────────────────────────────────────────────────────────

  static AppEnvironment get environment =>
      _envName == 'prod' ? AppEnvironment.prod : AppEnvironment.dev;

  static bool get isProd => environment == AppEnvironment.prod;
  static bool get isDev => !isProd;

  // ─── Host resolution ────────────────────────────────────────────────────────

  /// Dev entry point — the shared dev server, so any build/run works out of the
  /// box without flags. Override for a local backend:
  ///   --dart-define=DEV_BASE_URL=http://10.0.2.2   (Android emulator)
  ///   --dart-define=DEV_BASE_URL=http://localhost  (web/desktop)
  static const String _devBase = String.fromEnvironment(
    'DEV_BASE_URL',
    defaultValue: 'http://168.119.114.105',
  );

  /// Single nginx entry point — all traffic goes through one host.
  static String get _base => isProd ? _prodBase : _devBase;

  // ─── Public base URLs ───────────────────────────────────────────────────────

  /// Auth service routes: /auth/login, /auth/register, /auth/refresh, /auth/google
  static String get authBaseUrl => _authOverride.isNotEmpty ? _authOverride : _base;

  /// Gym entities API — nginx → backend-api
  static String get apiBaseUrl => _apiOverride.isNotEmpty ? _apiOverride : _base;

  /// Resolves a possibly-relative media path to an absolute URL against the API
  /// host. Exercise illustrations are stored as "/api/v1/exercise-images/x.png";
  /// absolute URLs (custom user images) and empty strings are returned as-is.
  static String resolveImageUrl(String url) {
    if (url.isEmpty || url.startsWith('http://') || url.startsWith('https://')) {
      return url;
    }
    if (url.startsWith('/')) return '$apiBaseUrl$url';
    return url;
  }

  /// One-line summary for startup logging.
  static String get summary =>
      'env=${environment.name} api=$apiBaseUrl auth=$authBaseUrl';
}
