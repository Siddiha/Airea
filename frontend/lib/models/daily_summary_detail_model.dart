class DailySummaryDetailModel {
  final String date;
  final String deviceId;
  final int totalCoughs;
  final double coughFrequency;
  final double avgConfidence;
  final double avgVolume;
  final int nightCoughs;
  final int dayCoughs;
  final double nightPercentage;
  final int peakHour;
  final List<HourlyDistributionModel> hourlyDistribution;
  final List<CoughPatternModel> patterns;
  final int severityScore;
  final String severityLevel;
  final String healthStatus;
  final List<HealthInsightModel> insights;
  final List<String> recommendations;
  final DailyComparisonModel comparison;
  final bool hasData;
  final String message;

  DailySummaryDetailModel({
    required this.date,
    required this.deviceId,
    required this.totalCoughs,
    required this.coughFrequency,
    required this.avgConfidence,
    required this.avgVolume,
    required this.nightCoughs,
    required this.dayCoughs,
    required this.nightPercentage,
    required this.peakHour,
    required this.hourlyDistribution,
    required this.patterns,
    required this.severityScore,
    required this.severityLevel,
    required this.healthStatus,
    required this.insights,
    required this.recommendations,
    required this.comparison,
    required this.hasData,
    required this.message,
  });

  factory DailySummaryDetailModel.fromJson(Map<String, dynamic> json) {
    return DailySummaryDetailModel(
      date: json['date'] ?? '',
      deviceId: json['deviceId'] ?? '',
      totalCoughs: json['totalCoughs'] ?? 0,
      coughFrequency: (json['coughFrequency'] ?? 0).toDouble(),
      avgConfidence: (json['avgConfidence'] ?? 0).toDouble(),
      avgVolume: (json['avgVolume'] ?? 0).toDouble(),
      nightCoughs: json['nightCoughs'] ?? 0,
      dayCoughs: json['dayCoughs'] ?? 0,
      nightPercentage: (json['nightPercentage'] ?? 0).toDouble(),
      peakHour: json['peakHour'] ?? 0,
      hourlyDistribution: (json['hourlyDistribution'] as List<dynamic>?)
              ?.map((e) => HourlyDistributionModel.fromJson(e))
              .toList() ??
          [],
      patterns: (json['patterns'] as List<dynamic>?)
              ?.map((e) => CoughPatternModel.fromJson(e))
              .toList() ??
          [],
      severityScore: json['severityScore'] ?? 0,
      severityLevel: json['severityLevel'] ?? 'UNKNOWN',
      healthStatus: json['healthStatus'] ?? '',
      insights: (json['insights'] as List<dynamic>?)
              ?.map((e) => HealthInsightModel.fromJson(e))
              .toList() ??
          [],
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      comparison: json['comparison'] != null
          ? DailyComparisonModel.fromJson(json['comparison'])
          : DailyComparisonModel(
              yesterdayCoughs: 0,
              change: 0,
              percentageChange: 0,
              trend: 'STABLE',
            ),
      hasData: json['hasData'] ?? false,
      message: json['message'] ?? '',
    );
  }
}

class HourlyDistributionModel {
  final int hour;
  final int count;
  final double percentage;

  HourlyDistributionModel({
    required this.hour,
    required this.count,
    required this.percentage,
  });

  factory HourlyDistributionModel.fromJson(Map<String, dynamic> json) {
    return HourlyDistributionModel(
      hour: json['hour'] ?? 0,
      count: json['count'] ?? 0,
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }
}

class CoughPatternModel {
  final String type;
  final String description;
  final double confidence;

  CoughPatternModel({
    required this.type,
    required this.description,
    required this.confidence,
  });

  factory CoughPatternModel.fromJson(Map<String, dynamic> json) {
    return CoughPatternModel(
      type: json['type'] ?? '',
      description: json['description'] ?? '',
      confidence: (json['confidence'] ?? 0).toDouble(),
    );
  }
}

class HealthInsightModel {
  final String title;
  final String description;
  final String severity;
  final String category;

  HealthInsightModel({
    required this.title,
    required this.description,
    required this.severity,
    required this.category,
  });

  factory HealthInsightModel.fromJson(Map<String, dynamic> json) {
    return HealthInsightModel(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      severity: json['severity'] ?? 'INFO',
      category: json['category'] ?? 'GENERAL',
    );
  }
}

class DailyComparisonModel {
  final int yesterdayCoughs;
  final int change;
  final double percentageChange;
  final String trend;

  DailyComparisonModel({
    required this.yesterdayCoughs,
    required this.change,
    required this.percentageChange,
    required this.trend,
  });

  factory DailyComparisonModel.fromJson(Map<String, dynamic> json) {
    return DailyComparisonModel(
      yesterdayCoughs: json['yesterdayCoughs'] ?? 0,
      change: json['change'] ?? 0,
      percentageChange: (json['percentageChange'] ?? 0).toDouble(),
      trend: json['trend'] ?? 'STABLE',
    );
  }
}
