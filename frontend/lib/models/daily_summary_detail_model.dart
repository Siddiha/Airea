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
  final VitalsSummaryModel? vitalsSummary; // NEW
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
    this.vitalsSummary, // NEW
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
      vitalsSummary: json['vitalsSummary'] != null 
          ? VitalsSummaryModel.fromJson(json['vitalsSummary']) 
          : null, // NEW
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

// ==================== VITALS MODELS ====================

class VitalsSummaryModel {
  final bool hasVitalsData;
  final String vitalsMessage;
  final int totalReadings;
  final SingleVitalSummaryModel? heartRate;
  final SingleVitalSummaryModel? temperature;
  final SingleVitalSummaryModel? respiratoryRate;
  final List<VitalsHourlyDataModel> hourlyVitals;
  final List<VitalsAnomalyModel> anomalies;
  final int vitalsSeverityScore;
  final String vitalsStatus;

  VitalsSummaryModel({
    required this.hasVitalsData,
    required this.vitalsMessage,
    required this.totalReadings,
    this.heartRate,
    this.temperature,
    this.respiratoryRate,
    required this.hourlyVitals,
    required this.anomalies,
    required this.vitalsSeverityScore,
    required this.vitalsStatus,
  });

  factory VitalsSummaryModel.fromJson(Map<String, dynamic> json) {
    return VitalsSummaryModel(
      hasVitalsData: json['hasVitalsData'] ?? false,
      vitalsMessage: json['vitalsMessage'] ?? '',
      totalReadings: json['totalReadings'] ?? 0,
      heartRate: json['heartRate'] != null 
          ? SingleVitalSummaryModel.fromJson(json['heartRate']) 
          : null,
      temperature: json['temperature'] != null 
          ? SingleVitalSummaryModel.fromJson(json['temperature']) 
          : null,
      respiratoryRate: json['respiratoryRate'] != null 
          ? SingleVitalSummaryModel.fromJson(json['respiratoryRate']) 
          : null,
      hourlyVitals: (json['hourlyVitals'] as List<dynamic>?)
              ?.map((e) => VitalsHourlyDataModel.fromJson(e))
              .toList() ??
          [],
      anomalies: (json['anomalies'] as List<dynamic>?)
              ?.map((e) => VitalsAnomalyModel.fromJson(e))
              .toList() ??
          [],
      vitalsSeverityScore: json['vitalsSeverityScore'] ?? 0,
      vitalsStatus: json['vitalsStatus'] ?? '',
    );
  }
}

class SingleVitalSummaryModel {
  final double average;
  final double min;
  final double max;
  final String status;
  final String statusMessage;
  final int readingCount;
  final int anomalyCount;

  SingleVitalSummaryModel({
    required this.average,
    required this.min,
    required this.max,
    required this.status,
    required this.statusMessage,
    required this.readingCount,
    required this.anomalyCount,
  });

  factory SingleVitalSummaryModel.fromJson(Map<String, dynamic> json) {
    return SingleVitalSummaryModel(
      average: (json['average'] ?? 0).toDouble(),
      min: (json['min'] ?? 0).toDouble(),
      max: (json['max'] ?? 0).toDouble(),
      status: json['status'] ?? 'UNKNOWN',
      statusMessage: json['statusMessage'] ?? '',
      readingCount: json['readingCount'] ?? 0,
      anomalyCount: json['anomalyCount'] ?? 0,
    );
  }
}

class VitalsHourlyDataModel {
  final int hour;
  final double? avgHeartRate;
  final double? avgTemperature;
  final double? avgRespiratoryRate;
  final int readingCount;

  VitalsHourlyDataModel({
    required this.hour,
    this.avgHeartRate,
    this.avgTemperature,
    this.avgRespiratoryRate,
    required this.readingCount,
  });

  factory VitalsHourlyDataModel.fromJson(Map<String, dynamic> json) {
    return VitalsHourlyDataModel(
      hour: json['hour'] ?? 0,
      avgHeartRate: json['avgHeartRate']?.toDouble(),
      avgTemperature: json['avgTemperature']?.toDouble(),
      avgRespiratoryRate: json['avgRespiratoryRate']?.toDouble(),
      readingCount: json['readingCount'] ?? 0,
    );
  }
}

class VitalsAnomalyModel {
  final String type;
  final String severity;
  final String condition;
  final double value;
  final String timestamp;
  final String message;

  VitalsAnomalyModel({
    required this.type,
    required this.severity,
    required this.condition,
    required this.value,
    required this.timestamp,
    required this.message,
  });

  factory VitalsAnomalyModel.fromJson(Map<String, dynamic> json) {
    return VitalsAnomalyModel(
      type: json['type'] ?? '',
      severity: json['severity'] ?? 'WARNING',
      condition: json['condition'] ?? '',
      value: (json['value'] ?? 0).toDouble(),
      timestamp: json['timestamp'] ?? '',
      message: json['message'] ?? '',
    );
  }
}
