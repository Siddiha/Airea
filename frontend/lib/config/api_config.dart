class ApiConfig {
  // ========================================
  // 🔧 Backend Configuration
  // ========================================

  // Your computer's IP address (from ipconfig)
  static const String backendHost = 'localhost';
  static const String backendPort = '8080';

  // API Base URL (automatically constructed)
  static const String baseUrl = 'http://$backendHost:$backendPort/api';

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
