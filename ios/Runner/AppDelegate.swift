import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Live Activities are system-owned and may survive a killed Flutter
    // process. Clear them before Dart restores the durable workout; a valid
    // snapshot will immediately create a fresh, authoritative activity.
    WorkoutLiveActivityBridge.endAll()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    WorkoutLiveActivityBridge.register(
      messenger: engineBridge.applicationRegistrar.messenger()
    )
  }
}
