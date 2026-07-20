import 'package:gymboss/config/api_config.dart';
import 'package:gymboss/core/errors/app_error.dart';
import 'package:gymboss/data/services/auth/auth_service.dart';
import 'package:gymboss/data/services/auth/authenticated_client.dart';
import 'package:gymboss/data/services/auth/google_sign_in_service.dart';
import 'package:gymboss/data/services/auth/token_storage.dart';
import 'package:gymboss/domain/models/auth/user.dart';

class AuthRepository {
  final AuthService _service;
  final TokenStorage _storage;
  final GoogleSignInService _google;
  final AuthenticatedClient _client;

  AuthRepository({
    required AuthService service,
    required TokenStorage storage,
    required AuthenticatedClient client,
    GoogleSignInService? google,
  }) : _service = service,
       _storage = storage,
       _client = client,
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

  /// Permanently deletes the account (GDPR right to erasure). Domain data
  /// (backend-api) and identity (auth-service) live in separate databases,
  /// so this is two calls, not one atomic operation — if the second fails
  /// after the first succeeds, domain data is gone but the identity remains
  /// and the caller sees an error to retry.
  Future<void> deleteAccount() async {
    final apiResp = await _client
        .delete(Uri.parse('${ApiConfig.apiBaseUrl}/api/v1/account'))
        .timeout(const Duration(seconds: 10));
    if (apiResp.statusCode != 204) {
      throw AppError(
        AppErrorCode.accountDeleteFailed,
        message: 'DELETE /api/v1/account HTTP ${apiResp.statusCode}',
      );
    }

    final authResp = await _client
        .delete(Uri.parse('${ApiConfig.authBaseUrl}/account'))
        .timeout(const Duration(seconds: 10));
    if (authResp.statusCode != 204) {
      throw AppError(
        AppErrorCode.accountDeleteFailed,
        message: 'DELETE /account HTTP ${authResp.statusCode}',
      );
    }

    await _google.signOut();
    await _storage.clear();
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
