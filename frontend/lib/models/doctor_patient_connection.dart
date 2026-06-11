/// Model representing a doctor-patient connection
class DoctorPatientConnection {
  final String patientId;
  final String patientCode;
  final String patientName;
  final String deviceId;
  final DateTime connectedAt;

  const DoctorPatientConnection({
    required this.patientId,
    this.patientCode = '',
    required this.patientName,
    this.deviceId = '',
    required this.connectedAt,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'patientCode': patientCode,
      'patientName': patientName,
      'deviceId': deviceId,
      'connectedAt': connectedAt.toIso8601String(),
    };
  }

  /// Create from JSON (local storage)
  factory DoctorPatientConnection.fromJson(Map<String, dynamic> json) {
    return DoctorPatientConnection(
      patientId: json['patientId'] as String,
      patientCode: json['patientCode'] as String? ?? '',
      patientName: json['patientName'] as String,
      deviceId: json['deviceId'] as String? ?? '',
      connectedAt: DateTime.parse(json['connectedAt'] as String),
    );
  }

  /// Create from backend API response
  factory DoctorPatientConnection.fromApiJson(Map<String, dynamic> json) {
    return DoctorPatientConnection(
      patientId: json['patientId'] as String,
      patientCode: json['patientCode'] as String? ?? '',
      patientName: json['patientName'] as String? ?? 'Unknown',
      deviceId: json['deviceId'] as String? ?? '',
      connectedAt: DateTime.now(),
    );
  }
}
