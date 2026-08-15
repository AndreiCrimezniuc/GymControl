import ActivityKit
import Flutter

@available(iOS 16.1, *)
struct GymControlWorkoutAttributes: ActivityAttributes {
  struct ContentState: Codable, Hashable {
    var completedSets: Int
    var totalSets: Int
    var restEnd: Date?
  }

  var workoutName: String
  var startedAt: Date
}

final class WorkoutLiveActivityBridge {
  static func register(messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(
      name: "gymcontrol/workout_live_activity",
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      guard #available(iOS 16.1, *) else {
        result(nil)
        return
      }
      let args = call.arguments as? [String: Any] ?? [:]
      switch call.method {
      case "start":
        start(args: args, result: result)
      case "update":
        update(args: args, result: result)
      case "end":
        end(result: result)
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  @available(iOS 16.1, *)
  private static func state(from args: [String: Any]) -> GymControlWorkoutAttributes.ContentState {
    let restMilliseconds = args["restEnd"] as? Double
    return .init(
      completedSets: args["completedSets"] as? Int ?? 0,
      totalSets: args["totalSets"] as? Int ?? 0,
      restEnd: restMilliseconds.map { Date(timeIntervalSince1970: $0 / 1000) }
    )
  }

  @available(iOS 16.1, *)
  private static func start(args: [String: Any], result: @escaping FlutterResult) {
    guard ActivityAuthorizationInfo().areActivitiesEnabled else {
      result(nil)
      return
    }
    Task {
      for activity in Activity<GymControlWorkoutAttributes>.activities {
        if #available(iOS 16.2, *) {
          await activity.end(nil, dismissalPolicy: .immediate)
        } else {
          await activity.end(using: nil, dismissalPolicy: .immediate)
        }
      }
      let milliseconds = args["startedAt"] as? Double ?? Date().timeIntervalSince1970 * 1000
      let attributes = GymControlWorkoutAttributes(
        workoutName: args["workoutName"] as? String ?? "Workout",
        startedAt: Date(timeIntervalSince1970: milliseconds / 1000)
      )
      do {
        if #available(iOS 16.2, *) {
          _ = try Activity.request(
            attributes: attributes,
            content: .init(state: state(from: args), staleDate: nil),
            pushType: nil
          )
        } else {
          _ = try Activity.request(
            attributes: attributes,
            contentState: state(from: args),
            pushType: nil
          )
        }
        result(nil)
      } catch {
        result(FlutterError(code: "activity_start", message: error.localizedDescription, details: nil))
      }
    }
  }

  @available(iOS 16.1, *)
  private static func update(args: [String: Any], result: @escaping FlutterResult) {
    Task {
      for activity in Activity<GymControlWorkoutAttributes>.activities {
        if #available(iOS 16.2, *) {
          await activity.update(.init(state: state(from: args), staleDate: nil))
        } else {
          await activity.update(using: state(from: args))
        }
      }
      result(nil)
    }
  }

  @available(iOS 16.1, *)
  private static func end(result: @escaping FlutterResult) {
    Task {
      for activity in Activity<GymControlWorkoutAttributes>.activities {
        if #available(iOS 16.2, *) {
          await activity.end(nil, dismissalPolicy: .immediate)
        } else {
          await activity.end(using: nil, dismissalPolicy: .immediate)
        }
      }
      result(nil)
    }
  }
}
