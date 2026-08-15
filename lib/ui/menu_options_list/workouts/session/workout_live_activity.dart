import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Best-effort bridge to iOS ActivityKit. The app remains fully functional on
/// unsupported devices and when Live Activities are disabled in Settings.
class WorkoutLiveActivity {
  static const _channel = MethodChannel('gymcontrol/workout_live_activity');

  static bool get _supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static Future<void> start({
    required String workoutName,
    required int totalSets,
  }) => _call('start', {
    'workoutName': workoutName,
    'totalSets': totalSets,
    'completedSets': 0,
    'startedAt': DateTime.now().millisecondsSinceEpoch,
  });

  static Future<void> update({
    required int completedSets,
    required int totalSets,
    int? restSeconds,
  }) => _call('update', {
    'completedSets': completedSets,
    'totalSets': totalSets,
    'restEnd':
        restSeconds == null || restSeconds <= 0
            ? null
            : DateTime.now()
                .add(Duration(seconds: restSeconds))
                .millisecondsSinceEpoch,
  });

  static Future<void> end() => _call('end');

  static Future<void> _call(String method, [Map<String, Object?>? args]) async {
    if (!_supported) return;
    try {
      await _channel.invokeMethod<void>(method, args);
    } on PlatformException {
      // Live Activity is an enhancement, never a workout blocker.
    } on MissingPluginException {
      // Allows tests and older installs to run before the native bridge exists.
    }
  }
}
