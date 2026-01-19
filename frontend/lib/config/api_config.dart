import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // ========================================
  // 🔧 Backend Configuration
  // ========================================

  // IMPORTANT: Set your computer's IP address here
  // Find it using: ipconfig (Windows) or ifconfig (Mac/Linux)
  static const String _computerIP = '192.168.8.106';  // Updated to match current IP
  static const String backendPort = '8080';

  // Automatically choose the correct host based on platform
  static String get backendHost {
    if (kIsWeb) {
      // Running in web browser - use localhost
      return 'localhost';
    } else if (Platform.isAndroid) {
      // Check if running on emulator or physical device
      // Emulator: use 10.0.2.2 (special alias to host machine)
      // Physical device: use computer's actual IP
      // For now, we'll use the computer IP - change to '10.0.2.2' if using emulator
      return _computerIP;  // Change to '10.0.2.2' for Android Emulator
    } else if (Platform.isIOS) {
      // iOS Simulator can use localhost, physical device needs IP
      return _computerIP;  // Use 'localhost' for iOS Simulator
    } else {
      return _computerIP;
    }
  }

  // API Base URL (automatically constructed)
  static String get baseUrl => 'http://$backendHost:$backendPort/api';

  // Default device ID for testing
  static const String defaultDeviceId = 'ESP32_COUGH_01';

  // API Endpoints
  static const String healthEndpoint = '/cough/health';
  static const String coughEventEndpoint = '/cough/event';
  static const String deviceEndpoint = '/device';

  // Helper methods
  static String get healthCheckUrl => '$baseUrl$healthEndpoint';
  static String get coughEventUrl => '$baseUrl$coughEventEndpoint';
  static String get deviceUrl => '$baseUrl$deviceEndpoint';

  // Get device-specific URLs
  static String deviceCoughUrl(String deviceId) =>
      '$baseUrl/cough/device/$deviceId';
  static String deviceStatsUrl(String deviceId, String period) =>
      '$baseUrl/cough/stats/$deviceId/$period';
}
