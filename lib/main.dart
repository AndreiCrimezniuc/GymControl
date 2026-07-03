import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:gymboss/app.dart';
import 'package:gymboss/config/api_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kDebugMode) {
    debugPrint('GymBoss starting — ${ApiConfig.summary}');
  }
  runApp(const GymBossApp());
}
