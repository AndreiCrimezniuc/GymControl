import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:gymboss/app.dart';
import 'package:gymboss/config/api_config.dart';
import 'package:gymboss/data/diagnostics/diagnostic_service.dart';
import 'package:gymboss/data/local/local_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Open the offline store before the app reads any data. Failure here must not
  // block launch — the app still works online without a cache.
  try {
    await LocalStore.instance.init();
    await DiagnosticService.instance.init();
  } catch (e) {
    if (kDebugMode) debugPrint('offline store init failed: $e');
  }
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    unawaited(
      DiagnosticService.instance.record(
        'flutter.framework_error',
        level: ClientDiagnosticLevel.error,
        attributes: {'error_code': details.exception.runtimeType.toString()},
      ),
    );
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    unawaited(
      DiagnosticService.instance.record(
        'flutter.platform_error',
        level: ClientDiagnosticLevel.error,
        attributes: {'error_code': error.runtimeType.toString()},
      ),
    );
    return false;
  };
  unawaited(DiagnosticService.instance.record('app.started'));
  if (kDebugMode) {
    debugPrint('GymBoss starting — ${ApiConfig.summary}');
  }
  runApp(const GymBossApp());
}
