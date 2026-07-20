import 'package:logger/logger.dart';

final _log = Logger();

enum AppErrorCode {
  // AUTH
  authInvalidCredentials,
  authEmailTaken,
  authTokenExpired,
  authUnknown,
  // NETWORK
  networkUnavailable,
  networkServerError,
  networkTimeout,
  // DATA
  dataLoadFailed,
  dataSaveFailed,
  dataParseError,
  accountDeleteFailed,
  // INPUT VALIDATION
  validationRequired,
  validationPasswordTooShort,
  validationPasswordMismatch,
  // FALLBACK
  unknown,
}

extension AppErrorCodeExt on AppErrorCode {
  String get code {
    switch (this) {
      case AppErrorCode.authInvalidCredentials:
        return 'AUTH_001';
      case AppErrorCode.authEmailTaken:
        return 'AUTH_002';
      case AppErrorCode.authTokenExpired:
        return 'AUTH_003';
      case AppErrorCode.authUnknown:
        return 'AUTH_099';
      case AppErrorCode.networkUnavailable:
        return 'NET_001';
      case AppErrorCode.networkServerError:
        return 'NET_002';
      case AppErrorCode.networkTimeout:
        return 'NET_003';
      case AppErrorCode.dataLoadFailed:
        return 'DATA_001';
      case AppErrorCode.dataSaveFailed:
        return 'DATA_002';
      case AppErrorCode.dataParseError:
        return 'DATA_003';
      case AppErrorCode.accountDeleteFailed:
        return 'DATA_004';
      case AppErrorCode.validationRequired:
        return 'INPUT_001';
      case AppErrorCode.validationPasswordTooShort:
        return 'INPUT_002';
      case AppErrorCode.validationPasswordMismatch:
        return 'INPUT_003';
      case AppErrorCode.unknown:
        return 'ERR_000';
    }
  }

  String get userMessage {
    switch (this) {
      case AppErrorCode.authInvalidCredentials:
        return 'Incorrect email or password';
      case AppErrorCode.authEmailTaken:
        return 'This email is already registered';
      case AppErrorCode.authTokenExpired:
        return 'Session expired, please log in again';
      case AppErrorCode.authUnknown:
        return 'Authentication failed';
      case AppErrorCode.networkUnavailable:
        return 'No internet connection';
      case AppErrorCode.networkServerError:
        return 'Server error, please try again';
      case AppErrorCode.networkTimeout:
        return 'Request timed out';
      case AppErrorCode.dataLoadFailed:
        return 'Failed to load data';
      case AppErrorCode.dataSaveFailed:
        return 'Failed to save';
      case AppErrorCode.dataParseError:
        return 'Unexpected data from server';
      case AppErrorCode.accountDeleteFailed:
        return 'Failed to delete account, please try again';
      case AppErrorCode.validationRequired:
        return 'Please fill in all fields';
      case AppErrorCode.validationPasswordTooShort:
        return 'Password must be at least 8 characters';
      case AppErrorCode.validationPasswordMismatch:
        return 'Passwords do not match';
      case AppErrorCode.unknown:
        return 'Something went wrong';
    }
  }

  static String messageFor(String code) {
    final match = AppErrorCode.values.where((e) => e.code == code).firstOrNull;
    return match?.userMessage ?? 'Something went wrong';
  }
}

class AppError implements Exception {
  final AppErrorCode errorCode;
  final String? _internalMessage;
  final Object? _cause;

  const AppError(this.errorCode, {String? message, Object? cause})
    : _internalMessage = message,
      _cause = cause;

  String get displayCode => errorCode.code;

  void log([StackTrace? stack]) {
    _log.e(
      '[${errorCode.code}] $_internalMessage',
      error: _cause,
      stackTrace: stack,
    );
  }

  @override
  String toString() => 'AppError(${errorCode.code})';
}

/// Wraps an unknown exception into an [AppError] and logs it immediately.
AppError wrapUnknown(Object e, [StackTrace? s]) {
  final err = AppError(AppErrorCode.unknown, message: e.toString(), cause: e);
  err.log(s);
  return err;
}
