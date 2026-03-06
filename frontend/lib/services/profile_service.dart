import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/patient_medical_info.dart';
import '../models/patient_contact.dart';
import '../models/patient_allergy.dart';

/// Simple local storage for patient profile extras (medical details, emergency contact, etc.)
/// Uses SharedPreferences so that values are persisted between app restarts.  This is
/// intentionally lightweight; the backend is responsible for keeping real user data.
/// 
/// NOTE: Emergency contact is also synced to the backend database to enable SMS alerts.
class ProfileService {
  static const _medicalKey = 'patient_medical_details';
  static const _contactKey = 'patient_emergency_contact';
  static const _allergiesKey = 'patient_allergies';
  static const _reportsKey = 'patient_medical_reports';

  /// Save medical details to local storage.
  static Future<void> saveMedicalDetails(PatientMedicalDetails details) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_medicalKey, jsonEncode(_toJson(details)));
  }

  /// Load previously saved medical details. Returns null if none stored.
  static Future<PatientMedicalDetails?> loadMedicalDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_medicalKey);
    if (jsonString == null) return null;
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return PatientMedicalDetails(
        age: map['age'] as int,
        height: map['height'] as int,
        weight: map['weight'] as int,
        gender: map['gender'] as String,
        habbits: map['habbits'] as String,
        workingEnvironment: map['workingEnvironment'] as String,
      );
    } catch (_) {
      return null;
    }
  }

  /// Save an emergency contact entry.
  /// Also syncs to backend database to enable SMS alerts.
  static Future<void> saveEmergencyContact(PatientContact contact) async {
    // Save to local storage
    final prefs = await SharedPreferences.getInstance();
    prefs.setString(_contactKey, jsonEncode({
      'relationship': contact.relationship,
      'contactNumber': contact.contactNumber,
    }));
    
    // Sync to backend database for SMS alerts
    await _syncEmergencyContactToDatabase(contact.contactNumber);
  }

  /// Sync emergency contact to the patients table in Supabase.
  /// This enables the backend to send SMS alerts when abnormal vitals are detected.
  static Future<void> _syncEmergencyContactToDatabase(String contactNumber) async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;
      
      if (user == null || user.email == null) {
        print('⚠️ No authenticated user - emergency contact not synced to database');
        return;
      }
      
      // Update the patients table with the emergency contact
      await supabase
          .from('patients')
          .update({'emergency_contact': contactNumber})
          .eq('email', user.email!);
      
      print('✅ Emergency contact synced to database: $contactNumber');
    } catch (e) {
      // Don't fail silently - log the error
      print('❌ Failed to sync emergency contact to database: $e');
      // Continue anyway - local storage was already saved
    }
  }

  /// Load saved emergency contact, or null if none exists.
  static Future<PatientContact?> loadEmergencyContact() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_contactKey);
    if (jsonString == null) return null;
    try {
      final map = jsonDecode(jsonString) as Map<String, dynamic>;
      return PatientContact(
        relationship: map['relationship'] as String,
        contactNumber: map['contactNumber'] as String,
      );
    } catch (_) {
      return null;
    }
  }

  static Map<String, dynamic> _toJson(PatientMedicalDetails d) => {
        'age': d.age,
        'height': d.height,
        'weight': d.weight,
        'gender': d.gender,
        'habbits': d.habbits,
        'workingEnvironment': d.workingEnvironment,
      };

  /// Save allergies list to local storage.
  static Future<void> saveAllergies(List<AllergyEntry> allergies) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = allergies.map((a) => _allergyToJson(a)).toList();
    prefs.setString(_allergiesKey, jsonEncode(jsonList));
  }

  /// Load previously saved allergies. Returns empty list if none stored.
  static Future<List<AllergyEntry>> loadAllergies() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_allergiesKey);
    if (jsonString == null || jsonString.isEmpty) return [];
    try {
      final list = jsonDecode(jsonString) as List<dynamic>;
      return list
          .map((item) => _jsonToAllergy(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Save medical report file paths to local storage.
  static Future<void> saveMedicalReports(List<String> filePaths) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList(_reportsKey, filePaths);
  }

  /// Load previously saved medical report file paths. Returns empty list if none stored.
  static Future<List<String>> loadMedicalReports() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_reportsKey) ?? [];
  }

  /// Delete a specific medical report by file path.
  static Future<void> deleteMedicalReport(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    final reports = prefs.getStringList(_reportsKey) ?? [];
    reports.removeWhere((path) => path == filePath);
    await prefs.setStringList(_reportsKey, reports);
  }

  static Map<String, dynamic> _allergyToJson(AllergyEntry a) => {
        'id': a.id,
        'name': a.name,
        'description': a.description,
        'createdAt': a.createdAt.toIso8601String(),
      };

  static AllergyEntry _jsonToAllergy(Map<String, dynamic> json) => AllergyEntry(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
