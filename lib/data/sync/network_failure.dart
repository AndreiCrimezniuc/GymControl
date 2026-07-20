import 'dart:async';

import 'package:http/http.dart' as http;

import 'package:gymboss/core/errors/app_error.dart';

/// Whether an operation failed because the backend is temporarily unreachable
/// and can safely fall back to durable local state / the mutation outbox.
bool isTransientNetworkFailure(Object error) =>
    error is TimeoutException ||
    error is http.ClientException ||
    error is AppError &&
        (error.errorCode == AppErrorCode.networkUnavailable ||
            error.errorCode == AppErrorCode.networkTimeout ||
            error.errorCode == AppErrorCode.networkServerError);
