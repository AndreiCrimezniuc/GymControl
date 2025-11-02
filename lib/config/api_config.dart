import 'package:flutter/foundation.dart';

class ApiConfig {
  /// Returns the correct base URL for the current platform
  static String get baseUrl {
    // Use kIsWeb and defaultTargetPlatform from Flutter foundation
    // These work across all platforms including web
    if (kIsWeb) {
      // Web
      return 'http://localhost:3000';
    }
    
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        // Android emulator uses 10.0.2.2 to access host machine's localhost
        return 'http://10.0.2.2:3000';
      case TargetPlatform.iOS:
        // iOS simulator can use localhost directly
        return 'http://localhost:3000';
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
        // Desktop platforms
        return 'http://localhost:3000';
      default:
        return 'http://localhost:3000';
    }
  }

  /// For production, use this instead:
  // static const String baseUrl = 'https://api.yourapp.com';
}

