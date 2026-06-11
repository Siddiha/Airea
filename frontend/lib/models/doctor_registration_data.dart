/// Model to hold all doctor registration data across the multi-step signup flow
class DoctorRegistrationData {
  // Account credentials
  final String email;
  final String password;

  // Personal Information
  final String? fullName;
  final String? mobileNumber;
  final String? specializations; // Can be comma-separated or a single value
  final String? medicalLicenseNumber;

  DoctorRegistrationData({
    required this.email,
    required this.password,
    this.fullName,
    this.mobileNumber,
    this.specializations,
    this.medicalLicenseNumber,
  });

  /// Create a copy with updated fields
  DoctorRegistrationData copyWith({
    String? email,
    String? password,
    String? fullName,
    String? mobileNumber,
    String? specializations,
    String? medicalLicenseNumber,
  }) {
    return DoctorRegistrationData(
      email: email ?? this.email,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      mobileNumber: mobileNumber ?? this.mobileNumber,
      specializations: specializations ?? this.specializations,
      medicalLicenseNumber: medicalLicenseNumber ?? this.medicalLicenseNumber,
    );
  }

  /// Convert to JSON for API submission
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password,
      'fullName': fullName,
      'mobileNumber': mobileNumber,
      'specializations': specializations,
      'medicalLicenseNumber': medicalLicenseNumber,
    };
  }
}
