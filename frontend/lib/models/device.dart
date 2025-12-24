class Device {
  final String id;
  final String deviceId;
  final String? deviceName;
  final String? location;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Device({
    required this.id,
    required this.deviceId,
    this.deviceName,
    this.location,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Device.fromJson(Map<String, dynamic> json) {
    return Device(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      deviceName: json['deviceName'] as String?,
      location: json['location'] as String?,
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'location': location,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  String get displayName => deviceName ?? deviceId;
}
