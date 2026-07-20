import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:gymboss/core/errors/app_error.dart';
import 'package:gymboss/data/services/auth/auth_service.dart';
import 'package:gymboss/data/services/auth/token_storage.dart';

/// Production HTTP client that:
/// - Attaches Bearer token to every request
/// - On 401: refreshes the access token and retries once
/// - On refresh failure: fires [onSessionExpired] and throws authTokenExpired
class AuthenticatedClient {
  final http.Client _inner;
  final TokenStorage _storage;
  final AuthService _authService;

  final _sessionExpiredCtrl = StreamController<void>.broadcast();
  Stream<void> get onSessionExpired => _sessionExpiredCtrl.stream;

  // Shared Future so concurrent 401s trigger only one refresh.
  Future<String?>? _ongoingRefresh;

  AuthenticatedClient({
    required TokenStorage storage,
    required AuthService authService,
    http.Client? inner,
  })  : _storage = storage,
        _authService = authService,
        _inner = inner ?? http.Client();

  Future<http.Response> get(Uri uri) =>
      _withRetry((h) => _inner.get(uri, headers: h));

  Future<http.Response> post(Uri uri, {Object? body}) =>
      _withRetry((h) => _inner.post(uri, headers: h, body: body));

  Future<http.Response> put(Uri uri, {Object? body}) =>
      _withRetry((h) => _inner.put(uri, headers: h, body: body));

  Future<http.Response> delete(Uri uri, {Object? body}) =>
      _withRetry((h) => _inner.delete(uri, headers: h, body: body));

  Future<http.Response> _withRetry(
    Future<http.Response> Function(Map<String, String>) make,
  ) async {
    try {
      var headers = await _buildHeaders();
      var resp = await make(headers);

      if (resp.statusCode == 401) {
        final newToken = await _refreshOnce();
        if (newToken != null) {
          headers = await _buildHeaders();
          resp = await make(headers);
        }
        if (resp.statusCode == 401) {
          _signalExpired();
          throw AppError(AppErrorCode.authTokenExpired);
        }
      }
      return resp;
    } on AppError {
      rethrow;
    } on SocketException catch (e, s) {
      throw AppError(AppErrorCode.networkUnavailable, message: e.toString(), cause: e)..log(s);
    } on TimeoutException catch (e, s) {
      throw AppError(AppErrorCode.networkTimeout, message: e.toString(), cause: e)..log(s);
    } catch (e, s) {
      throw wrapUnknown(e, s);
    }
  }

  Future<Map<String, String>> _buildHeaders() async {
    final token = await _storage.getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<String?> _refreshOnce() {
    _ongoingRefresh ??= _doRefresh().whenComplete(() => _ongoingRefresh = null);
    return _ongoingRefresh!;
  }

  Future<String?> _doRefresh() async {
    try {
      final rt = await _storage.getRefreshToken();
      if (rt == null) return null;
      final tokens = await _authService.refresh(rt);
      await _storage.save(tokens.accessToken, tokens.refreshToken);
      return tokens.accessToken;
    } catch (_) {
      await _storage.clear();
      return null;
    }
  }

  void _signalExpired() {
    if (!_sessionExpiredCtrl.isClosed) _sessionExpiredCtrl.add(null);
  }

  void dispose() {
    _inner.close();
    _sessionExpiredCtrl.close();
  }
}
