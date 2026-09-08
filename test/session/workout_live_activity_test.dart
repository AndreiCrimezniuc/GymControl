import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymboss/ui/menu_options_list/workouts/session/workout_live_activity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('gymcontrol/workout_live_activity');

  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    debugDefaultTargetPlatformOverride = null;
  });

  test('restored activity receives the authoritative session state', () async {
    MethodCall? received;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          received = call;
          return null;
        });
    final startedAt = DateTime.utc(2026, 9, 8, 10, 30);

    await WorkoutLiveActivity.start(
      workoutName: 'Heavy day',
      totalSets: 12,
      completedSets: 5,
      startedAt: startedAt,
      restSeconds: 90,
    );

    expect(received?.method, 'start');
    final args = Map<String, Object?>.from(received?.arguments as Map);
    expect(args['workoutName'], 'Heavy day');
    expect(args['totalSets'], 12);
    expect(args['completedSets'], 5);
    expect(args['startedAt'], startedAt.millisecondsSinceEpoch);
    expect(
      (args['restEnd'] as int),
      greaterThan(DateTime.now().millisecondsSinceEpoch),
    );
  });

  test('end does not complete before native ActivityKit cleanup', () async {
    final nativeCleanup = Completer<void>();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'end');
          await nativeCleanup.future;
          return null;
        });

    var completed = false;
    final ending = WorkoutLiveActivity.end().then((_) => completed = true);
    await Future<void>.delayed(Duration.zero);
    expect(completed, isFalse);

    nativeCleanup.complete();
    await ending;
    expect(completed, isTrue);
  });
}
