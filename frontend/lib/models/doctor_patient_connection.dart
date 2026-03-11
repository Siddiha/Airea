/// Model representing a doctor-patient connection
class DoctorPatientConnection {
  final String patientId;
  final String patientName;
  final DateTime connectedAt;

  const DoctorPatientConnection({
    required this.patientId,
    required this.patientName,
    required this.connectedAt,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'patientId': patientId,
      'patientName': patientName,
      'connectedAt': connectedAt.toIso8601String(),
    };
  }

  /// Create from JSON
  factory DoctorPatientConnection.fromJson(Map<String, dynamic> json) {
    return DoctorPatientConnection(
      patientId: json['patientId'] as String,
      patientName: json['patientName'] as String,
      connectedAt: DateTime.parse(json['connectedAt'] as String),
    );
  }
}
