/// Model class that holds all data entered by the doctor
/// on the "More details about doctor" screen.
class DoctorDetails {
  /// Medical specialization, e.g. "Cardiology"
  final String specialization;

  /// Medical license number issued by the relevant authority
  final String medicalLicenseNumber;

  /// Clinic or hospital address
  final String clinicOrHospitalAddress;

  /// Primary mobile / contact number
  final String primaryMobileNumber;

  /// Professional email address
  final String emailAddress;

  const DoctorDetails({
    required this.specialization,
    required this.medicalLicenseNumber,
    required this.clinicOrHospitalAddress,
    required this.primaryMobileNumber,
    required this.emailAddress,
  });

  /// Returns a new [DoctorDetails] with the given fields replaced.
  DoctorDetails copyWith({
    String? specialization,
    String? medicalLicenseNumber,
    String? clinicOrHospitalAddress,
    String? primaryMobileNumber,
    String? emailAddress,
  }) {
    return DoctorDetails(
      specialization: specialization ?? this.specialization,
      medicalLicenseNumber: medicalLicenseNumber ?? this.medicalLicenseNumber,
      clinicOrHospitalAddress:
          clinicOrHospitalAddress ?? this.clinicOrHospitalAddress,
      primaryMobileNumber: primaryMobileNumber ?? this.primaryMobileNumber,
      emailAddress: emailAddress ?? this.emailAddress,
    );
  }

  /// Returns which field labels are empty — used for validation messages.
  List<String> get emptyFields {
    final empty = <String>[];
    if (specialization.trim().isEmpty) empty.add('Specializations');
    if (medicalLicenseNumber.trim().isEmpty) empty.add('Medical license number');
    if (clinicOrHospitalAddress.trim().isEmpty) empty.add('Clinic or hospital address');
    if (primaryMobileNumber.trim().isEmpty) empty.add('Primary mobile number');
    if (emailAddress.trim().isEmpty) empty.add('Email address');
    return empty;
  }

  bool get isValid => emptyFields.isEmpty;

  @override
  String toString() =>
      'DoctorDetails(specialization: $specialization, '
      'licenseNumber: $medicalLicenseNumber, '
      'address: $clinicOrHospitalAddress, '
      'mobile: $primaryMobileNumber, '
      'email: $emailAddress)';
}
