import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../models/cough_event.dart';
import '../models/cough_statistics.dart';
import '../models/device.dart';
import '../models/device_model.dart';

class ApiService {
  // Use configuration instead of hardcoded URL
  static String get baseUrl => ApiConfig.baseUrl;

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
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final response = await http.get(
        Uri.parse('$baseUrl/summary/daily/$deviceId?date=$dateStr'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CoughStatistics(
          totalCoughs: data['totalCoughs'] ?? 0,
          dryCoughs: 0,
          wetCoughs: 0,
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
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final response = await http.get(
        Uri.parse('$baseUrl/summary/daily/$deviceId?date=$dateStr'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CoughStatistics(
          totalCoughs: data['totalCoughs'] ?? 0,
          dryCoughs: 0,
          wetCoughs: 0,
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
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final response = await http.get(
        Uri.parse('$baseUrl/summary/daily/$deviceId?date=$dateStr'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return CoughStatistics(
          totalCoughs: data['totalCoughs'] ?? 0,
          dryCoughs: 0,
          wetCoughs: 0,
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
  Future<Map<String, dynamic>> generateDummyData(String deviceId,
      {int count = 20}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/cough/generate-dummy/$deviceId?count=$count'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
            'Failed to generate dummy data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error generating dummy data: $e');
      rethrow;
    }
  }

  /// Get alert notifications from fall events history (deduplicated, newest first)
  Future<List<PatientNotification>> getFallAlerts(String deviceId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/fall/history/$deviceId'),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);

        // Sort by timestamp descending so we keep the most recent of each type
        jsonList.sort((a, b) {
          final ta = a['timestamp']?.toString() ?? '';
          final tb = b['timestamp']?.toString() ?? '';
          return tb.compareTo(ta);
        });

        final seen = <String>{};
        final result = <PatientNotification>[];

        for (final event in jsonList) {
          final String level = event['emergencyLevel'] ?? 'NORMAL';
          // Skip NORMAL/MONITORING events — only show real alerts
          if (level == 'NORMAL' || level == 'MONITORING') continue;

          final bool isHighAlert = level == 'CRITICAL';
          final String reason =
              (event['emergencyReason'] ?? '').toString().trim();
          final String title = reason.isNotEmpty ? reason : 'Fall detected';

          // Deduplicate: skip if we've already shown this exact reason
          if (seen.contains(title)) continue;
          seen.add(title);

          final String timestamp = event['timestamp']?.toString() ?? '';
          String timeStr = '--:--';
          if (timestamp.length >= 16) {
            try {
              final dt = DateTime.parse(timestamp);
              timeStr =
                  '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
            } catch (_) {
              timeStr = timestamp.substring(11, 16);
            }
          }

          result.add(PatientNotification(
            title: title,
            time: timeStr,
            isHighAlert: isHighAlert,
          ));
        }

        return result;
      }
      return [];
    } catch (e) {
      print('Error fetching fall alerts: $e');
      return [];
    }
  }

  /// Link a device to the currently logged-in patient in the Spring Boot backend.
  Future<Map<String, dynamic>> linkDeviceToPatient(
      String deviceId, String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/link-device'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode({'deviceId': deviceId}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return {'success': true};
      } else {
        final data = json.decode(response.body);
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to link device'
        };
      }
    } catch (e) {
      print('Error linking device to backend: $e');
      return {'success': false, 'message': 'Backend unreachable'};
    }
  }

  Future<VitalsData?> getLatestVitals(String deviceId) async {
    try {
      // REMOVED the extra /api from the path below
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/vitals/latest/$deviceId'),
      );

      if (response.statusCode == 200) {
        return VitalsData.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      print('Error fetching vitals: $e');
      return null;
    }
  }
}

class VitalsData {
  final double temp;
  final int bpm;
  final bool leadsOff;
  final double respiratoryRate;

  VitalsData({
    required this.temp,
    required this.bpm,
    required this.leadsOff,
    required this.respiratoryRate,
  });

  factory VitalsData.fromJson(Map<String, dynamic> json) {
    return VitalsData(
      temp: (json['temp'] ?? 0.0).toDouble(),
      bpm: (json['bpm'] ?? 0).toInt(),
      leadsOff: json['leadsOff'] ?? true,
      respiratoryRate: (json['rr'] ?? 0.0).toDouble(),
    );
  }
}
