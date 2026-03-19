import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/patient_medical_info.dart';
import '../models/patient_contact.dart';
import '../models/patient_allergy.dart';

/// Patient profile storage service.
///
/// All SharedPreferences keys are scoped per-user (appended with the user's
/// email) so that data never leaks between accounts on the same device.
///
/// Emergency contact phone number and gender are synced to the Supabase
/// `patients` table so they survive across devices.
class ProfileService {
  // Base key names – actual keys have the user email appended via [_key].
  static const _medicalBase = 'patient_medical_details';
  static const _contactBase = 'patient_emergency_contact';
  static const _allergiesBase = 'patient_allergies';
  static const _reportsBase = 'patient_medical_reports';

  // Old global (non-scoped) keys used before this fix – cleaned up on logout.
  static const _legacyKeys = [
    'patient_medical_details',
    'patient_emergency_contact',
    'patient_allergies',
    'patient_medical_reports',
  ];

  /// Returns the current authenticated user's email, or null.
  static String? _currentEmail() =>
      Supabase.instance.client.auth.currentUser?.email;

  /// Build a per-user SharedPreferences key.
  static String _key(String base) {
    final email = _currentEmail();
    if (email == null) return base;
    return '${base}_$email';
  }

  // ---------------------------------------------------------------------------
  // Medical details
  // ---------------------------------------------------------------------------

  /// Save medical details to user-scoped local storage AND sync gender to
  /// the Supabase `patients` table.
  static Future<void> saveMedicalDetails(PatientMedicalDetails details) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(_medicalBase), jsonEncode(_toJson(details)));

    // Sync gender to Supabase (column exists in patients table)
    _syncGenderToDatabase(details.gender);
  }

  /// Load medical details.  Tries user-scoped local storage first; for a
  /// fresh device install the gender field is fetched from Supabase.
  static Future<PatientMedicalDetails?> loadMedicalDetails() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key(_medicalBase));
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

  static Future<void> _syncGenderToDatabase(String gender) async {
    try {
      final email = _currentEmail();
      if (email == null || gender.isEmpty) return;
      await Supabase.instance.client
          .from('patients')
          .upsert({'email': email, 'gender': gender}, onConflict: 'email');
    } catch (e) {
      debugPrint('Failed to sync gender: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Emergency contact
  // ---------------------------------------------------------------------------

  /// Save an emergency contact entry.
  /// Also syncs to backend database to enable SMS alerts.
  static Future<void> saveEmergencyContact(PatientContact contact) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(_contactBase), jsonEncode({
      'relationship': contact.relationship,
      'contactNumber': contact.contactNumber,
    }));

    // Sync phone to Supabase
    await _syncEmergencyContactToDatabase(contact.contactNumber);
  }

  static Future<void> _syncEmergencyContactToDatabase(String contactNumber) async {
    try {
      final email = _currentEmail();
      if (email == null) return;
      await Supabase.instance.client
          .from('patients')
          .upsert({'email': email, 'emergency_contact': contactNumber}, onConflict: 'email');
    } catch (e) {
      debugPrint('Failed to sync emergency contact: $e');
    }
  }

  /// Load emergency contact.  The phone number is fetched from Supabase (real-
  /// time); the relationship field is stored locally (no DB column for it).
  static Future<PatientContact?> loadEmergencyContact() async {
    // Try Supabase first for the phone number
    String? supabasePhone;
    try {
      final email = _currentEmail();
      if (email != null) {
        final row = await Supabase.instance.client
            .from('patients')
            .select('emergency_contact')
            .eq('email', email)
            .maybeSingle();
        if (row != null && row['emergency_contact'] != null) {
          final phone = row['emergency_contact'] as String;
          if (phone.isNotEmpty) supabasePhone = phone;
        }
      }
    } catch (e) {
      debugPrint('Failed to load emergency contact from Supabase: $e');
    }

    // Load relationship (and fallback phone) from user-scoped local storage
    final local = await _loadLocalContact();

    if (supabasePhone != null || local != null) {
      return PatientContact(
        relationship: local?.relationship ?? '',
        contactNumber: supabasePhone ?? local?.contactNumber ?? '',
      );
    }
    return null;
  }

  static Future<PatientContact?> _loadLocalContact() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key(_contactBase));
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

  // ---------------------------------------------------------------------------
  // Allergies
  // ---------------------------------------------------------------------------

  static Future<void> saveAllergies(List<AllergyEntry> allergies) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = allergies.map((a) => _allergyToJson(a)).toList();
    await prefs.setString(_key(_allergiesBase), jsonEncode(jsonList));
  }

  static Future<List<AllergyEntry>> loadAllergies() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_key(_allergiesBase));
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

  // ---------------------------------------------------------------------------
  // Medical reports
  // ---------------------------------------------------------------------------

  static Future<void> saveMedicalReports(List<String> filePaths) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key(_reportsBase), filePaths);
  }

  static Future<List<String>> loadMedicalReports() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key(_reportsBase)) ?? [];
  }

  static Future<void> deleteMedicalReport(String filePath) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _key(_reportsBase);
    final reports = prefs.getStringList(key) ?? [];
    reports.removeWhere((path) => path == filePath);
    await prefs.setStringList(key, reports);
  }

  // ---------------------------------------------------------------------------
  // Logout cleanup
  // ---------------------------------------------------------------------------

  /// Remove old non-scoped (global) keys so stale data can never leak to
  /// another user who logs in on the same device.
  static Future<void> clearLegacyLocalData() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in _legacyKeys) {
      await prefs.remove(key);
    }
  }

  // ---------------------------------------------------------------------------
  // Device linking
  // ---------------------------------------------------------------------------

  /// Save the linked device ID to per-user local storage AND sync to Supabase.
  static Future<void> saveLinkedDevice(String deviceId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key('linked_device_id'), deviceId);
    await prefs.setString('linked_device_id', deviceId); // legacy key

    try {
      final email = _currentEmail();
      if (email != null) {
        await Supabase.instance.client
            .from('patients')
            .upsert({'email': email, 'device_id': deviceId}, onConflict: 'email');
      }
    } catch (e) {
      debugPrint('Failed to sync linked device to Supabase: $e');
    }
  }

  /// Read the linked device ID — per-user scoped, falls back to legacy key,
  /// then falls back to Supabase on a fresh install.
  static Future<String?> getLinkedDevice() async {
    final prefs = await SharedPreferences.getInstance();

    final scoped = prefs.getString(_key('linked_device_id'));
    if (scoped != null && scoped.isNotEmpty) return scoped;

    final legacy = prefs.getString('linked_device_id');
    if (legacy != null && legacy.isNotEmpty) return legacy;

    try {
      final email = _currentEmail();
      if (email != null) {
        final row = await Supabase.instance.client
            .from('patients')
            .select('device_id')
            .eq('email', email)
            .maybeSingle();
        if (row != null && row['device_id'] != null) {
          final id = row['device_id'] as String;
          if (id.isNotEmpty) {
            await prefs.setString(_key('linked_device_id'), id);
            await prefs.setString('linked_device_id', id);
            return id;
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch linked device from Supabase: $e');
    }

    return null;
  }

  /// Remove the linked device ID from local storage and Supabase.
  static Future<void> clearLinkedDevice() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key('linked_device_id'));
    await prefs.remove('linked_device_id');

    try {
      final email = _currentEmail();
      if (email != null) {
        await Supabase.instance.client
            .from('patients')
            .upsert({'email': email, 'device_id': null}, onConflict: 'email');
      }
    } catch (e) {
      debugPrint('Failed to clear linked device from Supabase: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

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
