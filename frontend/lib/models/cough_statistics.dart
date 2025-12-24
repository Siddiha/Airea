class CoughStatistics {
  final int totalCoughs;
  final int dryCoughs;
  final int wetCoughs;
  final int unknownCoughs;
  final double averageConfidence;
  final double coughsPerHour;
  final String mostCommonType;
  final String period;

  CoughStatistics({
    required this.totalCoughs,
    required this.dryCoughs,
    required this.wetCoughs,
    required this.unknownCoughs,
    required this.averageConfidence,
    required this.coughsPerHour,
    required this.mostCommonType,
    required this.period,
  });

  factory CoughStatistics.fromJson(Map<String, dynamic> json) {
    return CoughStatistics(
      totalCoughs: json['totalCoughs'] ?? 0,
      dryCoughs: json['dryCoughs'] ?? 0,
      wetCoughs: json['wetCoughs'] ?? 0,
      unknownCoughs: json['unknownCoughs'] ?? 0,
      averageConfidence: (json['averageConfidence'] ?? 0.0).toDouble(),
      coughsPerHour: (json['coughsPerHour'] ?? 0.0).toDouble(),
      mostCommonType: json['mostCommonType'] ?? 'none',
      period: json['period'] ?? 'unknown',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalCoughs': totalCoughs,
      'dryCoughs': dryCoughs,
      'wetCoughs': wetCoughs,
      'unknownCoughs': unknownCoughs,
      'averageConfidence': averageConfidence,
      'coughsPerHour': coughsPerHour,
      'mostCommonType': mostCommonType,
      'period': period,
    };
  }
}
