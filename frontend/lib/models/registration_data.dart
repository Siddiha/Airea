import 'package:airea_cough_monitor/models/patient_allergy.dart';
import 'package:airea_cough_monitor/models/patient_contact.dart';
import 'package:airea_cough_monitor/models/patient_medical_info.dart';

/// Model to hold all registration data across the multi-step signup flow
class RegistrationData {
  // Account credentials
  final String email;
  final String password;

  // Personal Information
  final String? fullName;
  final String? dateOfBirth;
  final String? gender;
  final String? address;

  // Emergency Contact
  final PatientContact? emergencyContact;

  // Medical details collected at signup (age, height, weight, etc.)
  final PatientMedicalDetails? medicalDetails;

  // Medical Reports (file paths)
  final List<String> medicalReportPaths;

  // Allergies
  final List<AllergyEntry> allergies;

  RegistrationData({
    required this.email,
    required this.password,
    this.fullName,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.emergencyContact,
    this.medicalDetails,
    this.medicalReportPaths = const [],
    this.allergies = const [],
  });

  /// Create a copy with updated fields
  RegistrationData copyWith({
    String? email,
    String? password,
    String? fullName,
    String? dateOfBirth,
    String? gender,
    String? address,
    PatientContact? emergencyContact,
    PatientMedicalDetails? medicalDetails,
    List<String>? medicalReportPaths,
    List<AllergyEntry>? allergies,
  }) {
    return RegistrationData(
      email: email ?? this.email,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      medicalDetails: medicalDetails ?? this.medicalDetails,
      medicalReportPaths: medicalReportPaths ?? this.medicalReportPaths,
      allergies: allergies ?? this.allergies,
    );
  }

  /// Convert to JSON for API submission
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'fullName': fullName,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'address': address,
      'emergencyContact': emergencyContact != null
          ? {
              'relationship': emergencyContact!.relationship,
              'contactNumber': emergencyContact!.contactNumber,
            }
          : null,
      'medicalDetails': medicalDetails != null
          ? {
              'age': medicalDetails!.age,
              'height': medicalDetails!.height,
              'weight': medicalDetails!.weight,
              'gender': medicalDetails!.gender,
              'habbits': medicalDetails!.habbits,
              'workingEnvironment': medicalDetails!.workingEnvironment,
            }
          : null,
      'medicalReports': medicalReportPaths,
      'allergies': allergies
          .map((a) => {
                'name': a.name,
                'description': a.description,
              })
          .toList(),
    };
  }
}
