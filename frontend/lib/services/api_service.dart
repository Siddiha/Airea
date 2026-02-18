import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart'; // ← Add this import!
import '../models/cough_event.dart';
import '../models/cough_statistics.dart';
import '../models/device.dart';

class ApiService {
  // Use configuration instead of hardcoded URL
  static String get baseUrl => ApiConfig.baseUrl;
  // Look for a line similar to this and update it:
  //static const String baseUrl = 'http://10.0.2.2:8080/api';

  /// Health check
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/cough/health'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('Health check failed: $e');
      return false;
    }
  }

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

  /// Get hourly statistics (using summary endpoint)
  Future<CoughStatistics> getHourlyStatistics(String deviceId) async {
    try {
      // Use current hour's data from summary endpoint
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      final response = await http.get(
        Uri.parse('$baseUrl/summary/daily/$deviceId?date=$dateStr'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Map summary data to CoughStatistics format
        return CoughStatistics(
          totalCoughs: data['totalCoughs'] ?? 0,
          dryCoughs: 0, // Not tracked in current system
          wetCoughs: 0, // Not tracked in current system
          unknownCoughs: data['totalCoughs'] ?? 0,
          averageConfidence: (data['avgConfidence'] ?? 0.0).toDouble(),
          coughsPerHour: (data['coughFrequency'] ?? 0.0).toDouble(),
          mostCommonType: 'cough',
          period: 'hour',
        );
      } else {
        throw Exception('Failed to load statistics: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting hourly statistics: $e');
      rethrow;
    }
  }

  /// Get today's statistics (using summary endpoint)
  Future<CoughStatistics> getTodayStatistics(String deviceId) async {
    try {
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      final response = await http.get(
        Uri.parse('$baseUrl/summary/daily/$deviceId?date=$dateStr'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Map summary data to CoughStatistics format
        return CoughStatistics(
          totalCoughs: data['totalCoughs'] ?? 0,
          dryCoughs: 0, // Not tracked in current system
          wetCoughs: 0, // Not tracked in current system
          unknownCoughs: data['totalCoughs'] ?? 0,
          averageConfidence: (data['avgConfidence'] ?? 0.0).toDouble(),
          coughsPerHour: (data['coughFrequency'] ?? 0.0).toDouble(),
          mostCommonType: 'cough',
          period: 'today',
        );
      } else {
        throw Exception('Failed to load statistics: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting today statistics: $e');
      rethrow;
    }
  }

  /// Get weekly statistics (using summary endpoint for today)
  Future<CoughStatistics> getWeeklyStatistics(String deviceId) async {
    try {
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      final response = await http.get(
        Uri.parse('$baseUrl/summary/daily/$deviceId?date=$dateStr'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        // Map summary data to CoughStatistics format
        // For weekly, we're showing today's data as placeholder
        return CoughStatistics(
          totalCoughs: data['totalCoughs'] ?? 0,
          dryCoughs: 0, // Not tracked in current system
          wetCoughs: 0, // Not tracked in current system
          unknownCoughs: data['totalCoughs'] ?? 0,
          averageConfidence: (data['avgConfidence'] ?? 0.0).toDouble(),
          coughsPerHour: (data['coughFrequency'] ?? 0.0).toDouble(),
          mostCommonType: 'cough',
          period: 'week',
        );
      } else {
        throw Exception('Failed to load statistics: ${response.statusCode}');
      }
    } catch (e) {
      print('Error getting weekly statistics: $e');
      rethrow;
    }
  }

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

  /// Generate dummy cough data for testing
  Future<Map<String, dynamic>> generateDummyData(String deviceId, {int count = 20}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cough/generate-dummy/$deviceId?count=$count'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to generate dummy data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error generating dummy data: $e');
      rethrow;
    }
  }
}
