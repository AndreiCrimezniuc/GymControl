import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:gymboss/app.dart';
import 'package:gymboss/config/api_config.dart';
import 'package:gymboss/data/local/local_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Open the offline store before the app reads any data. Failure here must not
  // block launch — the app still works online without a cache.
  try {
    await LocalStore.instance.init();
  } catch (e) {
    if (kDebugMode) debugPrint('offline store init failed: $e');
  }
  if (kDebugMode) {
    debugPrint('GymBoss starting — ${ApiConfig.summary}');
  }
  runApp(const GymBossApp());
}
