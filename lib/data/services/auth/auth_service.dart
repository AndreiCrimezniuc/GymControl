import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:gymboss/config/api_config.dart';
import 'package:gymboss/core/errors/app_error.dart';
import 'package:gymboss/data/apimodels/auth/auth.dart';
import 'package:gymboss/domain/models/auth/user.dart';

class AuthService {
  final String _base = ApiConfig.authBaseUrl;

  Future<AuthTokens> login(String email, String password) async {
    final resp = await _post('/auth/login', {
      'email': email,
      'password': password,
    });
    return TokenResponseModel.fromJson(jsonDecode(resp.body)).toDomain();
  }

  Future<AuthTokens> register(String email, String password) async {
    final resp = await _post('/auth/register', {
      'email': email,
      'password': password,
    }, expectedStatus: 201);
    return TokenResponseModel.fromJson(jsonDecode(resp.body)).toDomain();
  }

  Future<AuthTokens> refresh(String refreshToken) async {
    final resp = await _post('/auth/refresh', {'refresh_token': refreshToken});
    return TokenResponseModel.fromJson(jsonDecode(resp.body)).toDomain();
  }

  Future<AuthTokens> loginWithGoogle(String idToken) async {
    final resp = await _post('/auth/google', {'id_token': idToken});
    return TokenResponseModel.fromJson(jsonDecode(resp.body)).toDomain();
  }

  Future<http.Response> _post(
    String path,
    Map<String, dynamic> body, {
    int expectedStatus = 200,
  }) async {
    try {
      final resp = await http
          .post(
            Uri.parse('$_base$path'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));

      _assertStatus(resp, expectedStatus, path);
      return resp;
    } on AppError {
      rethrow;
    } on SocketException catch (e, s) {
      throw AppError(
        AppErrorCode.networkUnavailable,
        message: '$path: $e',
        cause: e,
      )..log(s);
    } on TimeoutException catch (e, s) {
      throw AppError(
        AppErrorCode.networkTimeout,
        message: '$path: $e',
        cause: e,
      )..log(s);
    } catch (e, s) {
      throw wrapUnknown(e, s);
    }
  }

  void _assertStatus(http.Response resp, int expected, String path) {
    if (resp.statusCode == expected) return;

    final raw = _bodyError(resp);
    final code = switch (resp.statusCode) {
      401 => AppErrorCode.authInvalidCredentials,
      409 => AppErrorCode.authEmailTaken,
      >= 500 => AppErrorCode.networkServerError,
      _ => AppErrorCode.authUnknown,
    };

    throw AppError(code, message: '$path HTTP ${resp.statusCode}: $raw')..log();
  }

  String _bodyError(http.Response resp) {
    try {
      return (jsonDecode(resp.body) as Map<String, dynamic>)['error']
              ?.toString() ??
          resp.body;
    } catch (_) {
      return resp.body;
    }
  }
}
