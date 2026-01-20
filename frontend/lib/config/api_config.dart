import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  // ========================================
  // 🔧 Backend Configuration
  // ========================================

  // IMPORTANT: This IP is used for Physical Devices on the same Wi-Fi.
  // Find it using: ipconfig (Windows) or ifconfig (Mac/Linux)
  static const String _computerIP = '192.168.8.106';
  static const String backendPort = '8080';

  // Automatically choose the correct host based on platform
  static String get backendHost {
    if (kIsWeb) {
      // Running in web browser - use localhost
      return 'localhost';
    } else if (Platform.isAndroid) {
      // Android Emulator uses 10.0.2.2 to access the Mac/PC localhost
      // If using a physical Android device, use _computerIP
      return '10.0.2.2';
    } else if (Platform.isIOS) {
      // iOS Simulator: Use 'localhost' to talk to the Mac it's running on
      // Physical iPhone: Use _computerIP
      return 'localhost';
    } else {
      return _computerIP;
    }
  }

  // API Base URL (automatically constructed)
  static String get baseUrl => 'http://$backendHost:$backendPort/api';

  // Default device ID for testing (matches your ESP32 ID)
  static const String defaultDeviceId = 'ESP32_COUGH_01';

  // ========================================
  // 🚀 API Endpoints
  // ========================================

  // Cough related endpoints
  static const String healthEndpoint = '/cough/health';
  static const String coughEventEndpoint = '/cough/event';
  static const String deviceEndpoint = '/device';

  // Helper methods to get full URLs
  static String get healthCheckUrl => '$baseUrl$healthEndpoint';
  static String get coughEventUrl => '$baseUrl$coughEventEndpoint';
  static String get deviceUrl => '$baseUrl$deviceEndpoint';

  // Device-specific data and statistics
  static String deviceCoughUrl(String deviceId) =>
      '$baseUrl/cough/device/$deviceId';

  static String deviceStatsUrl(String deviceId, String period) =>
      '$baseUrl/cough/stats/$deviceId/$period';
}
