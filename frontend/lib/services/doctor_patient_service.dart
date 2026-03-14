import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/doctor_patient_connection.dart';

/// Service to manage doctor-patient connections via backend API
class DoctorPatientService {
  static const _doctorCodeKey = 'doctor_code';

  /// Save the logged-in doctor's code for use in API calls
  static Future<void> saveDoctorCode(String doctorCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_doctorCodeKey, doctorCode);
  }

  /// Get the logged-in doctor's code
  static Future<String?> getDoctorCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_doctorCodeKey);
  }

  /// Get all connected patients from the backend
  static Future<List<DoctorPatientConnection>> getConnectedPatients() async {
    try {
      final doctorCode = await getDoctorCode();
      if (doctorCode == null || doctorCode.isEmpty) {
        print('No doctor code found');
        return [];
      }

      final url = Uri.parse(
          '${ApiConfig.baseUrl}/connections/doctor/$doctorCode/patients');
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList
            .map((item) => DoctorPatientConnection.fromApiJson(
                item as Map<String, dynamic>))
            .toList();
      } else {
        print('Failed to load patients: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error loading connected patients: $e');
      return [];
    }
  }

  /// Get the total count of connected patients
  static Future<int> getConnectedPatientCount() async {
    final patients = await getConnectedPatients();
    return patients.length;
  }

  /// Connect a new patient via backend API
  static Future<bool> connectPatient({
    required String patientCode,
  }) async {
    try {
      final doctorCode = await getDoctorCode();
      if (doctorCode == null || doctorCode.isEmpty) {
        print('No doctor code found');
        return false;
      }

      final url =
          Uri.parse('${ApiConfig.baseUrl}/connections/add-by-code');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'doctorCode': doctorCode,
          'patientCode': patientCode,
        }),
      ).timeout(const Duration(seconds: 10));

      return response.statusCode == 200;
    } catch (e) {
      print('Error connecting patient: $e');
      return false;
    }
  }

  /// Clear saved doctor code (on logout)
  static Future<void> clearDoctorCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_doctorCodeKey);
  }

  /// Disconnect a patient via backend API
  static Future<bool> disconnectPatient(String patientId) async {
    try {
      final doctorCode = await getDoctorCode();
      if (doctorCode == null || doctorCode.isEmpty) {
        return false;
      }

      final url = Uri.parse(
          '${ApiConfig.baseUrl}/connections/disconnect?doctorCode=$doctorCode&patientId=$patientId');
      final response = await http.delete(url).timeout(
        const Duration(seconds: 10),
      );

      return response.statusCode == 200;
    } catch (e) {
      print('Error disconnecting patient: $e');
      return false;
    }
  }
}
