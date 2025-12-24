class CoughEvent {
  final String id;
  final String deviceId;
  final String coughType;
  final double confidence;
  final double? rawScore;
  final DateTime timestamp;
  final double? audioVolume;
  final DateTime createdAt;

  CoughEvent({
    required this.id,
    required this.deviceId,
    required this.coughType,
    required this.confidence,
    this.rawScore,
    required this.timestamp,
    this.audioVolume,
    required this.createdAt,
  });

  factory CoughEvent.fromJson(Map<String, dynamic> json) {
    return CoughEvent(
      id: json['id'] as String,
      deviceId: json['deviceId'] as String,
      coughType: json['coughType'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      rawScore: json['rawScore'] != null
          ? (json['rawScore'] as num).toDouble()
          : null,
      timestamp: DateTime.parse(json['timestamp'] as String),
      audioVolume: json['audioVolume'] != null
          ? (json['audioVolume'] as num).toDouble()
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'deviceId': deviceId,
      'coughType': coughType,
      'confidence': confidence,
      'rawScore': rawScore,
      'timestamp': timestamp.toIso8601String(),
      'audioVolume': audioVolume,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  String get confidencePercentage => '${(confidence * 100).toInt()}%';
}
