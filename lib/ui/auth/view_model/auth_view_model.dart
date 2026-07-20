import 'package:flutter/cupertino.dart';
import 'package:gymboss/core/errors/app_error.dart';
import 'package:gymboss/data/repositories/auth_repository.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repo;

  AuthStatus _status = AuthStatus.unknown;
  String? _errorCode;
  bool _loading = false;

  AuthViewModel(this._repo);

  AuthStatus get status => _status;

  /// Only the error code is exposed — never the raw message.
  String? get errorCode => _errorCode;
  bool get loading => _loading;

  Future<void> checkAuth() async {
    final loggedIn = await _repo.isLoggedIn;
    _status = loggedIn ? AuthStatus.authenticated : AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      await _repo.login(email, password);
      _status = AuthStatus.authenticated;
      _errorCode = null;
    } catch (e, s) {
      _errorCode = _handleError(e, s);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> register(String email, String password) async {
    _setLoading(true);
    try {
      await _repo.register(email, password);
      _status = AuthStatus.authenticated;
      _errorCode = null;
    } catch (e, s) {
      _errorCode = _handleError(e, s);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loginWithGoogle() async {
    _setLoading(true);
    try {
      final ok = await _repo.loginWithGoogle();
      if (ok) {
        _status = AuthStatus.authenticated;
        _errorCode = null;
      }
    } catch (e, s) {
      _errorCode = _handleError(e, s);
    } finally {
      _setLoading(false);
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  /// Permanently deletes the account. On success flips to unauthenticated,
  /// same as [logout]; on failure sets [errorCode] and leaves the caller
  /// still logged in so they can retry.
  Future<void> deleteAccount() async {
    _setLoading(true);
    try {
      await _repo.deleteAccount();
      _status = AuthStatus.unauthenticated;
      _errorCode = null;
    } catch (e, s) {
      _errorCode = _handleError(e, s);
    } finally {
      _setLoading(false);
    }
  }

  void clearError() {
    _errorCode = null;
    notifyListeners();
  }

  void _setLoading(bool v) {
    _loading = v;
    notifyListeners();
  }

  String _handleError(Object e, StackTrace s) {
    if (e is AppError) {
      e.log(s);
      return e.displayCode;
    }
    // unexpected — wrap and log
    return wrapUnknown(e, s).displayCode;
  }
}
