import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/doctor_patient_connection.dart';

/// Service to manage doctor-patient connections
/// Uses SharedPreferences for local storage
class DoctorPatientService {
  static const _connectedPatientsKey = 'doctor_connected_patients';

  /// Get all connected patients for the current doctor
  static Future<List<DoctorPatientConnection>> getConnectedPatients() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_connectedPatientsKey);
      
      if (jsonString == null) {
        return [];
      }
      
      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((item) => DoctorPatientConnection.fromJson(item as Map<String, dynamic>))
          .toList();
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

  /// Connect a new patient (add to the list)
  static Future<bool> connectPatient({
    required String patientId,
    required String patientName,
  }) async {
    try {
      final patients = await getConnectedPatients();
      
      // Check if patient is already connected
      if (patients.any((p) => p.patientId == patientId)) {
        return false; // Already connected
      }
      
      // Add the new patient connection
      final newConnection = DoctorPatientConnection(
        patientId: patientId,
        patientName: patientName,
        connectedAt: DateTime.now(),
      );
      
      patients.add(newConnection);
      
      // Save to storage
      final prefs = await SharedPreferences.getInstance();
      final jsonList = patients.map((p) => p.toJson()).toList();
      await prefs.setString(_connectedPatientsKey, jsonEncode(jsonList));
      
      return true; // Successfully connected
    } catch (e) {
      print('Error connecting patient: $e');
      return false;
    }
  }

  /// Disconnect a patient (remove from the list)
  static Future<bool> disconnectPatient(String patientId) async {
    try {
      final patients = await getConnectedPatients();
      final initialLength = patients.length;
      
      // Remove the patient
      patients.removeWhere((p) => p.patientId == patientId);
      
      // Save to storage
      final prefs = await SharedPreferences.getInstance();
      final jsonList = patients.map((p) => p.toJson()).toList();
      await prefs.setString(_connectedPatientsKey, jsonEncode(jsonList));
      
      return patients.length < initialLength; // Successfully removed
    } catch (e) {
      print('Error disconnecting patient: $e');
      return false;
    }
  }

  /// Clear all connected patients (for testing or reset)
  static Future<void> clearAllConnections() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_connectedPatientsKey);
    } catch (e) {
      print('Error clearing connections: $e');
    }
  }
}
