class WeeklySummaryDetailModel {
  final String weekStart;
  final String weekEnd;
  final String deviceId;
  final int daysWithData;

  // Cough Summary
  final CoughWeeklySummaryModel coughSummary;

  // Week over week comparison
  final WeekOverWeekComparisonModel weekOverWeekComparison;

  // Daily breakdown (7 days)
  final List<DailyBreakdownModel> dailyBreakdown;

  // Vitals Summary
  final WeeklyVitalsSummaryModel? vitalsSummary;

  // Fall Events Summary
  final WeeklyFallEventsSummaryModel? fallEventsSummary;

  // Analysis
  final List<String> weeklyPatterns;
  final List<String> weeklyInsights;
  final List<String> recommendations;

  // Overall assessment
  final int severityScore;
  final String severityLevel;
  final String healthStatus;
  final bool hasData;
  final String message;

  WeeklySummaryDetailModel({
    required this.weekStart,
    required this.weekEnd,
    required this.deviceId,
    required this.daysWithData,
    required this.coughSummary,
    required this.weekOverWeekComparison,
    required this.dailyBreakdown,
    this.vitalsSummary,
    this.fallEventsSummary,
    required this.weeklyPatterns,
    required this.weeklyInsights,
    required this.recommendations,
    required this.severityScore,
    required this.severityLevel,
    required this.healthStatus,
    required this.hasData,
    required this.message,
  });

  factory WeeklySummaryDetailModel.fromJson(Map<String, dynamic> json) {
    return WeeklySummaryDetailModel(
      weekStart: json['weekStart'] ?? '',
      weekEnd: json['weekEnd'] ?? '',
      deviceId: json['deviceId'] ?? '',
      daysWithData: json['daysWithData'] ?? 0,
      coughSummary: json['coughSummary'] != null
          ? CoughWeeklySummaryModel.fromJson(json['coughSummary'])
          : CoughWeeklySummaryModel.empty(),
      weekOverWeekComparison: json['weekOverWeekComparison'] != null
          ? WeekOverWeekComparisonModel.fromJson(json['weekOverWeekComparison'])
          : WeekOverWeekComparisonModel.empty(),
      dailyBreakdown: (json['dailyBreakdown'] as List<dynamic>?)
              ?.map((e) => DailyBreakdownModel.fromJson(e))
              .toList() ??
          [],
      vitalsSummary: json['vitalsSummary'] != null
          ? WeeklyVitalsSummaryModel.fromJson(json['vitalsSummary'])
          : null,
      fallEventsSummary: json['fallEventsSummary'] != null
          ? WeeklyFallEventsSummaryModel.fromJson(json['fallEventsSummary'])
          : null,
      weeklyPatterns: (json['weeklyPatterns'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      weeklyInsights: (json['weeklyInsights'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      severityScore: json['severityScore'] ?? 0,
      severityLevel: json['severityLevel'] ?? 'UNKNOWN',
      healthStatus: json['healthStatus'] ?? '',
      hasData: json['hasData'] ?? false,
      message: json['message'] ?? '',
    );
  }
}

class CoughWeeklySummaryModel {
  final int totalCoughs;
  final double avgCoughsPerDay;
  final int totalDayCoughs;
  final int totalNightCoughs;
  final double nightCoughPercentage;
  final String severityLevel;
  final int peakDay;
  final String peakDayName;
  final int peakDayCoughs;
  final int lowestDay;
  final String lowestDayName;
  final int lowestDayCoughs;

  CoughWeeklySummaryModel({
    required this.totalCoughs,
    required this.avgCoughsPerDay,
    required this.totalDayCoughs,
    required this.totalNightCoughs,
    required this.nightCoughPercentage,
    required this.severityLevel,
    required this.peakDay,
    required this.peakDayName,
    required this.peakDayCoughs,
    required this.lowestDay,
    required this.lowestDayName,
    required this.lowestDayCoughs,
  });

  factory CoughWeeklySummaryModel.fromJson(Map<String, dynamic> json) {
    return CoughWeeklySummaryModel(
      totalCoughs: json['totalCoughs'] ?? 0,
      avgCoughsPerDay: (json['avgCoughsPerDay'] ?? 0).toDouble(),
      totalDayCoughs: json['totalDayCoughs'] ?? 0,
      totalNightCoughs: json['totalNightCoughs'] ?? 0,
      nightCoughPercentage: (json['nightCoughPercentage'] ?? 0).toDouble(),
      severityLevel: json['severityLevel'] ?? 'GOOD',
      peakDay: json['peakDay'] ?? 0,
      peakDayName: json['peakDayName'] ?? '',
      peakDayCoughs: json['peakDayCoughs'] ?? 0,
      lowestDay: json['lowestDay'] ?? 0,
      lowestDayName: json['lowestDayName'] ?? '',
      lowestDayCoughs: json['lowestDayCoughs'] ?? 0,
    );
  }

  factory CoughWeeklySummaryModel.empty() {
    return CoughWeeklySummaryModel(
      totalCoughs: 0,
      avgCoughsPerDay: 0,
      totalDayCoughs: 0,
      totalNightCoughs: 0,
      nightCoughPercentage: 0,
      severityLevel: 'GOOD',
      peakDay: 0,
      peakDayName: '',
      peakDayCoughs: 0,
      lowestDay: 0,
      lowestDayName: '',
      lowestDayCoughs: 0,
    );
  }
}

class WeekOverWeekComparisonModel {
  final int previousWeekTotal;
  final int currentWeekTotal;
  final int change;
  final double changePercentage;
  final String trend;
  final String trendMessage;

  WeekOverWeekComparisonModel({
    required this.previousWeekTotal,
    required this.currentWeekTotal,
    required this.change,
    required this.changePercentage,
    required this.trend,
    required this.trendMessage,
  });

  factory WeekOverWeekComparisonModel.fromJson(Map<String, dynamic> json) {
    return WeekOverWeekComparisonModel(
      previousWeekTotal: json['previousWeekTotal'] ?? 0,
      currentWeekTotal: json['currentWeekTotal'] ?? 0,
      change: json['change'] ?? 0,
      changePercentage: (json['changePercentage'] ?? 0).toDouble(),
      trend: json['trend'] ?? 'STABLE',
      trendMessage: json['trendMessage'] ?? '',
    );
  }

  factory WeekOverWeekComparisonModel.empty() {
    return WeekOverWeekComparisonModel(
      previousWeekTotal: 0,
      currentWeekTotal: 0,
      change: 0,
      changePercentage: 0,
      trend: 'STABLE',
      trendMessage: '',
    );
  }
}

class DailyBreakdownModel {
  final String date;
  final String dayName;
  final int dayIndex;
  final int totalCoughs;
  final int dayCoughs;
  final int nightCoughs;
  final double nightPercentage;
  final bool hasData;
  final double? avgHeartRate;
  final double? avgTemperature;
  final double? avgRespiratoryRate;
  final int fallCount;
  final int emergencyFallCount;
  final String severityLevel;

  DailyBreakdownModel({
    required this.date,
    required this.dayName,
    required this.dayIndex,
    required this.totalCoughs,
    required this.dayCoughs,
    required this.nightCoughs,
    required this.nightPercentage,
    required this.hasData,
    this.avgHeartRate,
    this.avgTemperature,
    this.avgRespiratoryRate,
    required this.fallCount,
    required this.emergencyFallCount,
    required this.severityLevel,
  });

  factory DailyBreakdownModel.fromJson(Map<String, dynamic> json) {
    return DailyBreakdownModel(
      date: json['date'] ?? '',
      dayName: json['dayName'] ?? '',
      dayIndex: json['dayIndex'] ?? 0,
      totalCoughs: json['totalCoughs'] ?? 0,
      dayCoughs: json['dayCoughs'] ?? 0,
      nightCoughs: json['nightCoughs'] ?? 0,
      nightPercentage: (json['nightPercentage'] ?? 0).toDouble(),
      hasData: json['hasData'] ?? false,
      avgHeartRate: json['avgHeartRate']?.toDouble(),
      avgTemperature: json['avgTemperature']?.toDouble(),
      avgRespiratoryRate: json['avgRespiratoryRate']?.toDouble(),
      fallCount: json['fallCount'] ?? 0,
      emergencyFallCount: json['emergencyFallCount'] ?? 0,
      severityLevel: json['severityLevel'] ?? 'GOOD',
    );
  }
}

class WeeklyVitalsSummaryModel {
  final bool hasVitalsData;
  final int totalReadings;
  final int daysWithVitalsData;
  final String vitalsMessage;
  final WeeklyVitalStatsModel? heartRate;
  final WeeklyVitalStatsModel? temperature;
  final WeeklyVitalStatsModel? respiratoryRate;
  final int vitalsSeverityScore;
  final String vitalsStatus;
  final List<double?> dailyHeartRateAverages;
  final List<double?> dailyTemperatureAverages;
  final List<double?> dailyRespiratoryRateAverages;
  final List<VitalsAnomalyModel> weeklyAnomalies;

  WeeklyVitalsSummaryModel({
    required this.hasVitalsData,
    required this.totalReadings,
    required this.daysWithVitalsData,
    required this.vitalsMessage,
    this.heartRate,
    this.temperature,
    this.respiratoryRate,
    required this.vitalsSeverityScore,
    required this.vitalsStatus,
    required this.dailyHeartRateAverages,
    required this.dailyTemperatureAverages,
    required this.dailyRespiratoryRateAverages,
    required this.weeklyAnomalies,
  });

  factory WeeklyVitalsSummaryModel.fromJson(Map<String, dynamic> json) {
    return WeeklyVitalsSummaryModel(
      hasVitalsData: json['hasVitalsData'] ?? false,
      totalReadings: json['totalReadings'] ?? 0,
      daysWithVitalsData: json['daysWithVitalsData'] ?? 0,
      vitalsMessage: json['vitalsMessage'] ?? '',
      heartRate: json['heartRate'] != null
          ? WeeklyVitalStatsModel.fromJson(json['heartRate'])
          : null,
      temperature: json['temperature'] != null
          ? WeeklyVitalStatsModel.fromJson(json['temperature'])
          : null,
      respiratoryRate: json['respiratoryRate'] != null
          ? WeeklyVitalStatsModel.fromJson(json['respiratoryRate'])
          : null,
      vitalsSeverityScore: json['vitalsSeverityScore'] ?? 0,
      vitalsStatus: json['vitalsStatus'] ?? '',
      dailyHeartRateAverages: (json['dailyHeartRateAverages'] as List<dynamic>?)
              ?.map<double?>((e) => e?.toDouble())
              .toList() ??
          [],
      dailyTemperatureAverages:
          (json['dailyTemperatureAverages'] as List<dynamic>?)
                  ?.map<double?>((e) => e?.toDouble())
                  .toList() ??
              [],
      dailyRespiratoryRateAverages:
          (json['dailyRespiratoryRateAverages'] as List<dynamic>?)
                  ?.map<double?>((e) => e?.toDouble())
                  .toList() ??
              [],
      weeklyAnomalies: (json['weeklyAnomalies'] as List<dynamic>?)
              ?.map((e) => VitalsAnomalyModel.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class WeeklyVitalStatsModel {
  final double weeklyAverage;
  final double weeklyMin;
  final double weeklyMax;
  final String status;
  final String statusMessage;
  final int totalReadings;
  final int anomalyCount;
  final String trend;

  WeeklyVitalStatsModel({
    required this.weeklyAverage,
    required this.weeklyMin,
    required this.weeklyMax,
    required this.status,
    required this.statusMessage,
    required this.totalReadings,
    required this.anomalyCount,
    required this.trend,
  });

  factory WeeklyVitalStatsModel.fromJson(Map<String, dynamic> json) {
    return WeeklyVitalStatsModel(
      weeklyAverage: (json['weeklyAverage'] ?? 0).toDouble(),
      weeklyMin: (json['weeklyMin'] ?? 0).toDouble(),
      weeklyMax: (json['weeklyMax'] ?? 0).toDouble(),
      status: json['status'] ?? 'UNKNOWN',
      statusMessage: json['statusMessage'] ?? '',
      totalReadings: json['totalReadings'] ?? 0,
      anomalyCount: json['anomalyCount'] ?? 0,
      trend: json['trend'] ?? 'STABLE',
    );
  }
}

// ==================== WEEKLY FALL EVENTS MODELS ====================

class WeeklyFallEventsSummaryModel {
  final bool hasFallData;
  final int totalFalls;
  final int totalEmergencyFalls;
  final double maxGForce;
  final double avgGForce;
  final int daysWithFalls;
  final double avgFallsPerDay;
  final String? worstEmergencyLevel;
  final String fallRiskLevel;
  final String fallRiskMessage;
  final List<int> dailyFallCounts;
  final List<int> dailyEmergencyCounts;

  WeeklyFallEventsSummaryModel({
    required this.hasFallData,
    required this.totalFalls,
    required this.totalEmergencyFalls,
    required this.maxGForce,
    required this.avgGForce,
    required this.daysWithFalls,
    required this.avgFallsPerDay,
    this.worstEmergencyLevel,
    required this.fallRiskLevel,
    required this.fallRiskMessage,
    required this.dailyFallCounts,
    required this.dailyEmergencyCounts,
  });

  factory WeeklyFallEventsSummaryModel.fromJson(Map<String, dynamic> json) {
    return WeeklyFallEventsSummaryModel(
      hasFallData: json['hasFallData'] ?? false,
      totalFalls: json['totalFalls'] ?? 0,
      totalEmergencyFalls: json['totalEmergencyFalls'] ?? 0,
      maxGForce: (json['maxGForce'] ?? 0).toDouble(),
      avgGForce: (json['avgGForce'] ?? 0).toDouble(),
      daysWithFalls: json['daysWithFalls'] ?? 0,
      avgFallsPerDay: (json['avgFallsPerDay'] ?? 0).toDouble(),
      worstEmergencyLevel: json['worstEmergencyLevel'],
      fallRiskLevel: json['fallRiskLevel'] ?? 'NONE',
      fallRiskMessage: json['fallRiskMessage'] ?? '',
      dailyFallCounts: (json['dailyFallCounts'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          List.filled(7, 0),
      dailyEmergencyCounts: (json['dailyEmergencyCounts'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          List.filled(7, 0),
    );
  }
}

// Import VitalsAnomalyModel from daily_summary_detail_model.dart
// Or redefine it here for completeness:
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
