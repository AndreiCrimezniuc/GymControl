# Dynamic Island / Live Activity — future proposal

> Status: **not implemented and not part of the current release**. This document
> is a design recipe only. Plugin versions, serialization behavior, Apple
> capabilities, privacy, and background behavior must be revalidated before
> implementation. Current functionality is documented in
> [MOBILE.md](https://github.com/Control-Labs-Holding/backend-api/blob/main/docs/MOBILE.md).

Show the workout timer + current exercise in the iOS Dynamic Island and Lock
Screen while a session is active. This is **native iOS (ActivityKit)** and only
runs on a physical device (iOS 16.1+); it can't be built or tested from the web
deploy pipeline, so it lives here as a ready-to-apply recipe rather than wired
into the web build.

Our session already exposes everything the activity needs from
`WorkoutSessionController` (elapsed, current exercise, done/total sets, volume).

## 1. Add the Flutter plugin

```yaml
# pubspec.yaml
dependencies:
  live_activities: ^2.4.0   # or latest
```

## 2. Xcode setup (one-time, manual)

1. Open `ios/Runner.xcworkspace`.
2. File → New → Target → **Widget Extension**, name it `WorkoutActivity`,
   check **Include Live Activity**, uncheck "Include Configuration Intent".
3. In the **Runner** target Info.plist add: `NSSupportsLiveActivities` = `YES`.
4. Set the widget extension's minimum deployment target to iOS 16.1+.
5. Add an **App Group** (e.g. `group.app.gymboss`) to BOTH the Runner and the
   widget targets (Signing & Capabilities → + App Groups). The `live_activities`
   plugin uses it to pass data; set the same id in Dart (`appGroupId`).

## 3. Native activity attributes + widget (Swift)

`ios/WorkoutActivity/WorkoutAttributes.swift`

```swift
import ActivityKit

struct WorkoutAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    var exercise: String     // current exercise name
    var elapsed: String      // "12:34"
    var setsDone: Int
    var setsTotal: Int
  }
  var workoutName: String
}
```

`ios/WorkoutActivity/WorkoutActivityLiveActivity.swift`

```swift
import ActivityKit
import WidgetKit
import SwiftUI

struct WorkoutActivityLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: WorkoutAttributes.self) { context in
      // Lock Screen / banner
      HStack {
        VStack(alignment: .leading) {
          Text(context.attributes.workoutName).font(.caption).foregroundStyle(.secondary)
          Text(context.state.exercise).font(.headline).lineLimit(1)
        }
        Spacer()
        VStack(alignment: .trailing) {
          Text(context.state.elapsed).font(.headline.monospacedDigit())
          Text("\(context.state.setsDone)/\(context.state.setsTotal) sets").font(.caption).foregroundStyle(.secondary)
        }
      }
      .padding()
      .activityBackgroundTint(Color.black.opacity(0.85))
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) { Text(context.state.elapsed).font(.headline.monospacedDigit()) }
        DynamicIslandExpandedRegion(.trailing) { Text("\(context.state.setsDone)/\(context.state.setsTotal)").font(.headline) }
        DynamicIslandExpandedRegion(.bottom) { Text(context.state.exercise).font(.subheadline).lineLimit(1) }
      } compactLeading: {
        Image(systemName: "dumbbell.fill")
      } compactTrailing: {
        Text(context.state.elapsed).font(.caption2.monospacedDigit())
      } minimal: {
        Image(systemName: "dumbbell.fill")
      }
      .keylineTint(Color.red)
    }
  }
}
```

## 4. Flutter service

`lib/ui/menu_options_list/workouts/session/live_activity_service.dart`

```dart
import 'dart:io';
import 'package:live_activities/live_activities.dart';

class LiveActivityService {
  final _la = LiveActivities();
  String? _id;
  bool _ready = false;

  Future<void> _init() async {
    if (_ready || !Platform.isIOS) return;
    await _la.init(appGroupId: 'group.app.gymboss');
    _ready = true;
  }

  Future<void> start(Map<String, dynamic> state) async {
    if (!Platform.isIOS) return;
    await _init();
    _id = await _la.createActivity(state);
  }

  Future<void> update(Map<String, dynamic> state) async {
    if (!Platform.isIOS || _id == null) return;
    await _la.updateActivity(_id!, state);
  }

  Future<void> end() async {
    if (!Platform.isIOS || _id == null) return;
    await _la.endActivity(_id!);
    _id = null;
  }
}
```

## 5. Hook it into the session

In `WorkoutSessionController`:

- add `final _live = LiveActivityService();`
- in `start()`: `_live.start(_activityState());`
- in the 1-second `_ticker` and after `toggleSet`: `_live.update(_activityState());`
- in `finish()` and `clear()`: `_live.end();`

```dart
Map<String, dynamic> _activityState() {
  final current = _groups.firstWhere(
    (g) => g.sets.any((s) => !s.done),
    orElse: () => _groups.isNotEmpty ? _groups.last : SessionExercise(name: '', muscleGroup: '', restSeconds: 0, sets: []),
  );
  return {
    'workoutName': _workout?.name ?? '',
    'exercise': current.name,
    'elapsed': elapsed,
    'setsDone': doneSets,
    'setsTotal': totalSets,
  };
}
```

(The exact key names must match `WorkoutAttributes.ContentState` and how the
`live_activities` plugin serializes state — confirm against the plugin's
example. On non-iOS platforms every call is a no-op, so the web build is
unaffected once the plugin is added.)

## 6. Test

Build to a physical iOS 16.1+ device (`flutter run` with the device selected),
start a workout, lock the screen / check the Dynamic Island.
```
```
