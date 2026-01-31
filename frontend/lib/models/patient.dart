class Patient {
  final String? id;
  final String email;
  final String? fullName;
  final String? dateOfBirth;
  final String? gender;
  final String? address;
  final String? phoneNumber;
  final String? allergies;
  final String? emergencyContact;
  final String? deviceId;

  Patient({
    this.id,
    required this.email,
    this.fullName,
    this.dateOfBirth,
    this.gender,
    this.address,
    this.phoneNumber,
    this.allergies,
    this.emergencyContact,
    this.deviceId,
  });

  factory Patient.fromJson(Map<String, dynamic> json) {
    return Patient(
      id: json['id']?.toString(),
      email: json['email'] ?? '',
      fullName: json['fullName'],
      dateOfBirth: json['dateOfBirth'],
      gender: json['gender'],
      address: json['address'],
      phoneNumber: json['phoneNumber'],
      allergies: json['allergies'],
      emergencyContact: json['emergencyContact'],
      deviceId: json['deviceId'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'fullName': fullName,
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'address': address,
      'phoneNumber': phoneNumber,
      'allergies': allergies,
      'emergencyContact': emergencyContact,
      'deviceId': deviceId,
    };
  }

  Patient copyWith({
    String? id,
    String? email,
    String? fullName,
    String? dateOfBirth,
    String? gender,
    String? address,
    String? phoneNumber,
    String? allergies,
    String? emergencyContact,
    String? deviceId,
  }) {
    return Patient(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      allergies: allergies ?? this.allergies,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      deviceId: deviceId ?? this.deviceId,
    );
  }
}

class AuthResponse {
  final String token;
  final String tokenType;
  final int expiresIn;
  final Patient patient;

  AuthResponse({
    required this.token,
    required this.tokenType,
    required this.expiresIn,
    required this.patient,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] ?? '',
      tokenType: json['tokenType'] ?? 'Bearer',
      expiresIn: json['expiresIn'] ?? 0,
      patient: Patient.fromJson(json['patient'] ?? {}),
    );
  }
}