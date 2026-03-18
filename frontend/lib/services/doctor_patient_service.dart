import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  /// Get the logged-in doctor's code (auto-fetches from backend if not cached)
  static Future<String?> getDoctorCode() async {
    final prefs = await SharedPreferences.getInstance();
    String? code = prefs.getString(_doctorCodeKey);
    if (code != null && code.isNotEmpty) return code;

    // If not cached, try to fetch from backend API
    final user = Supabase.instance.client.auth.currentUser;
    if (user?.email != null) {
      // Try backend API
      try {
        final url = Uri.parse(
            '${ApiConfig.baseUrl}/auth/doctor/code?email=${Uri.encodeComponent(user!.email!)}');
        final resp = await http.get(url).timeout(const Duration(seconds: 10));
        if (resp.statusCode == 200) {
          final data = jsonDecode(resp.body);
          if (data['code'] != null) {
            code = data['code'] as String;
            await prefs.setString(_doctorCodeKey, code);
            return code;
          }
        }
      } catch (e) {
        print('Error fetching doctor code from API: $e');
      }

      // Fallback: try Supabase direct query
      try {
        final supabase = Supabase.instance.client;
        final resp = await supabase
            .from('doctors')
            .select('doctor_code')
            .eq('email', user!.email!)
            .maybeSingle();
        if (resp != null && resp['doctor_code'] != null) {
          code = resp['doctor_code'] as String;
          await prefs.setString(_doctorCodeKey, code);
          return code;
        }
      } catch (e) {
        print('Error fetching doctor code from Supabase: $e');
      }
    }
    return null;
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
  /// Returns null on success, or an error message string on failure
  static Future<String?> connectPatient({
    required String patientCode,
  }) async {
    try {
      final doctorCode = await getDoctorCode();
      if (doctorCode == null || doctorCode.isEmpty) {
        print('No doctor code found');
        return 'Doctor code not found. Please log out and log in again.';
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

      if (response.statusCode == 200) {
        return null; // success
      } else {
        return response.body;
      }
    } catch (e) {
      print('Error connecting patient: $e');
      return 'Error: Could not connect. Is the server running?';
    }
  }

  /// Clear saved doctor code (on logout)
  static Future<void> clearDoctorCode() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_doctorCodeKey);
  }

  /// Get connected doctors for the current patient
  static Future<List<Map<String, dynamic>>> getConnectedDoctors() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final patientCode = prefs.getString('patient_code');
      if (patientCode == null || patientCode.isEmpty) {
        print('No patient code found');
        return [];
      }

      final url = Uri.parse(
          '${ApiConfig.baseUrl}/connections/patient/$patientCode/doctors');
      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body);
        return jsonList.cast<Map<String, dynamic>>();
      } else {
        print('Failed to load connected doctors: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error loading connected doctors: $e');
      return [];
    }
  }

  /// Disconnect the current patient from a doctor
  static Future<bool> disconnectFromDoctor(String doctorCode) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final patientCode = prefs.getString('patient_code');
      if (patientCode == null || patientCode.isEmpty) {
        print('disconnectFromDoctor: No patient_code in SharedPreferences');
        return false;
      }

      final url = Uri.parse(
          '${ApiConfig.baseUrl}/connections/disconnect?doctorCode=$doctorCode&patientCode=$patientCode');
      final response = await http.delete(url).timeout(
        const Duration(seconds: 10),
      );

      print('disconnectFromDoctor: status=${response.statusCode}, body=${response.body}');
      return response.statusCode == 200;
    } catch (e) {
      print('disconnectFromDoctor: exception=$e');
      return false;
    }
  }

  /// Disconnect a patient via backend API (used by doctors)
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
