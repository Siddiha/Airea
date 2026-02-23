import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb, kReleaseMode;

class ApiConfig {
  // ========================================
  // 🔧 Backend Configuration
  // ========================================

  // Production URL (Railway deployment)
  static const String _productionUrl =
      'https://airea-production.up.railway.app/api';

  // Set to true to use production backend, false for local development
  static const bool useProduction = true;

  // Local development settings
  static const String _computerIP = '192.168.8.106';
  static const String backendPort = '8080';

  // Automatically choose the correct host based on platform (for local dev)
  static String get _localBackendHost {
    if (kIsWeb) {
      return 'localhost';
    } else if (Platform.isAndroid) {
      return '10.0.2.2';
    } else if (Platform.isIOS) {
      return 'localhost';
    } else {
      return _computerIP;
    }
  }

  // API Base URL - uses production or local based on config
  static String get baseUrl {
    if (useProduction || kReleaseMode) {
      return _productionUrl;
    }
    return 'http://$_localBackendHost:$backendPort/api';
  }

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

  // Device-specific data and statistics (DEPRECATED - use summary endpoint)
  static String deviceCoughUrl(String deviceId) =>
      '$baseUrl/cough/device/$deviceId';

  // NEW: Daily summary endpoint (replaces old stats endpoints)
  static String dailySummaryUrl(String deviceId, String date) =>
      '$baseUrl/summary/daily/$deviceId?date=$date';

  // NEW: Weekly summary endpoint
  static String weeklySummaryUrl(String deviceId, String weekStart) =>
      '$baseUrl/summary/weekly/$deviceId?weekStart=$weekStart';

  // DEPRECATED: Old stats endpoint - backend doesn't implement these
  // Use dailySummaryUrl instead
  static String deviceStatsUrl(String deviceId, String period) =>
      '$baseUrl/summary/daily/$deviceId?date=${_getTodayDate()}';

  // Helper to get today's date in YYYY-MM-DD format
  static String _getTodayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
