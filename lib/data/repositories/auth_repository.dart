import 'package:gymboss/data/services/auth/auth_service.dart';
import 'package:gymboss/data/services/auth/google_sign_in_service.dart';
import 'package:gymboss/data/services/auth/token_storage.dart';
import 'package:gymboss/domain/models/auth/user.dart';

class AuthRepository {
  final AuthService _service;
  final TokenStorage _storage;
  final GoogleSignInService _google;

  AuthRepository({
    required AuthService service,
    required TokenStorage storage,
    GoogleSignInService? google,
  })  : _service = service,
        _storage = storage,
        _google = google ?? GoogleSignInService();

  Future<bool> get isLoggedIn => _storage.hasToken();

  Future<String?> get accessToken => _storage.getAccessToken();

  Future<void> login(String email, String password) async {
    final tokens = await _service.login(email, password);
    await _storage.save(tokens.accessToken, tokens.refreshToken);
  }

  Future<void> register(String email, String password) async {
    final tokens = await _service.register(email, password);
    await _storage.save(tokens.accessToken, tokens.refreshToken);
  }

  Future<void> logout() async {
    await _google.signOut();
    await _storage.clear();
  }

  /// Returns false if the user cancelled the Google sign-in sheet.
  Future<bool> loginWithGoogle() async {
    final idToken = await _google.signIn();
    if (idToken == null) return false;
    final tokens = await _service.loginWithGoogle(idToken);
    await _storage.save(tokens.accessToken, tokens.refreshToken);
    return true;
  }

  Future<AuthTokens?> tryRefresh() async {
    final refreshToken = await _storage.getRefreshToken();
    if (refreshToken == null) return null;
    try {
      final tokens = await _service.refresh(refreshToken);
      await _storage.save(tokens.accessToken, tokens.refreshToken);
      return tokens;
    } catch (_) {
      await _storage.clear();
      return null;
    }
  }
}
