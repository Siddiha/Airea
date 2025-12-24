import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/cough_event.dart';
import '../models/cough_statistics.dart';
import '../models/device.dart';

class ApiService {
  // ========================================
  // 🔧 CHANGE THIS TO YOUR BACKEND IP!
  // ========================================
  static const String baseUrl = 'http://192.168.1.100:8080/api';

  // --- COUGH ENDPOINTS ---

  /// Get all cough events for a device
  Future<List<CoughEvent>> getCoughEvents(String deviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cough/device/$deviceId'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => CoughEvent.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load cough events: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting cough events: $e');
      rethrow;
    }
  }

  /// Get cough events within a time range
  Future<List<CoughEvent>> getCoughEventsByTimeRange(
    String deviceId,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final startMillis = start.millisecondsSinceEpoch;
      final endMillis = end.millisecondsSinceEpoch;

      final response = await http.get(
        Uri.parse(
          '$baseUrl/cough/device/$deviceId/range?start=$startMillis&end=$endMillis',
        ),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => CoughEvent.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load cough events: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting cough events by time range: $e');
      rethrow;
    }
  }

  /// Get hourly statistics
  Future<CoughStatistics> getHourlyStatistics(String deviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cough/stats/$deviceId/hour'),
      );

      if (response.statusCode == 200) {
        return CoughStatistics.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load statistics: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting hourly statistics: $e');
      rethrow;
    }
  }

  /// Get today's statistics
  Future<CoughStatistics> getTodayStatistics(String deviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cough/stats/$deviceId/today'),
      );

      if (response.statusCode == 200) {
        return CoughStatistics.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load statistics: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting today statistics: $e');
      rethrow;
    }
  }

  /// Get weekly statistics
  Future<CoughStatistics> getWeeklyStatistics(String deviceId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cough/stats/$deviceId/week'),
      );

      if (response.statusCode == 200) {
        return CoughStatistics.fromJson(json.decode(response.body));
      } else {
        throw Exception('Failed to load statistics: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting weekly statistics: $e');
      rethrow;
    }
  }

  // --- DEVICE ENDPOINTS ---

  /// Get all active devices
  Future<List<Device>> getActiveDevices() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/device/active'));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Device.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load devices: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting active devices: $e');
      rethrow;
    }
  }

  /// Get device by ID
  Future<Device?> getDevice(String deviceId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/device/$deviceId'));

      if (response.statusCode == 200) {
        return Device.fromJson(json.decode(response.body));
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to load device: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting device: $e');
      rethrow;
    }
  }

  /// Register a new device
  Future<Device> registerDevice({
    required String deviceId,
    String? deviceName,
    String? location,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/device/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'deviceId': deviceId,
          'deviceName': deviceName,
          'location': location,
        }),
      );

      if (response.statusCode == 201) {
        final result = json.decode(response.body);
        return Device.fromJson(result['device']);
      } else {
        throw Exception('Failed to register device: ${response.statusCode}');
      }
    } catch (e) {
      print('Error registering device: $e');
      rethrow;
    }
  }

  /// Health check
  Future<bool> checkHealth() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/cough/health'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }
}
