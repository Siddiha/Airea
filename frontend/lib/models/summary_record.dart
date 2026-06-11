// Base class for all summary records
abstract class SummaryRecord {
  final String id;
  final DateTime date;
  final String summaryText;
  final DateTime generatedAt;
  final String recordType;

  SummaryRecord({
    required this.id,
    required this.date,
    required this.summaryText,
    required this.generatedAt,
    required this.recordType,
  });

  // For future backend integration
  Map<String, dynamic> toJson();
  
  // Copy with pattern for immutability
  SummaryRecord copyWith();
}

// Daily Summary Record
class DailySummaryRecord extends SummaryRecord {
  DailySummaryRecord({
    required String id,
    required DateTime date,
    required String summaryText,
    required DateTime generatedAt,
  }) : super(
          id: id,
          date: date,
          summaryText: summaryText,
          generatedAt: generatedAt,
          recordType: 'daily',
        );

  // Factory constructor for backend JSON parsing
  factory DailySummaryRecord.fromJson(Map<String, dynamic> json) {
    return DailySummaryRecord(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      summaryText: json['summaryText'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'summaryText': summaryText,
      'generatedAt': generatedAt.toIso8601String(),
      'recordType': recordType,
    };
  }

  @override
  DailySummaryRecord copyWith({
    String? id,
    DateTime? date,
    String? summaryText,
    DateTime? generatedAt,
  }) {
    return DailySummaryRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      summaryText: summaryText ?? this.summaryText,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}

// Weekly Summary Record
class WeeklySummaryRecord extends SummaryRecord {
  final DateTime weekStart;
  final DateTime weekEnd;

  WeeklySummaryRecord({
    required String id,
    required DateTime date,
    required this.weekStart,
    required this.weekEnd,
    required String summaryText,
    required DateTime generatedAt,
  }) : super(
          id: id,
          date: date,
          summaryText: summaryText,
          generatedAt: generatedAt,
          recordType: 'weekly',
        );

  // Factory constructor for backend JSON parsing
  factory WeeklySummaryRecord.fromJson(Map<String, dynamic> json) {
    return WeeklySummaryRecord(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      weekStart: DateTime.parse(json['weekStart'] as String),
      weekEnd: DateTime.parse(json['weekEnd'] as String),
      summaryText: json['summaryText'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'weekStart': weekStart.toIso8601String(),
      'weekEnd': weekEnd.toIso8601String(),
      'summaryText': summaryText,
      'generatedAt': generatedAt.toIso8601String(),
      'recordType': recordType,
    };
  }

  @override
  WeeklySummaryRecord copyWith({
    String? id,
    DateTime? date,
    DateTime? weekStart,
    DateTime? weekEnd,
    String? summaryText,
    DateTime? generatedAt,
  }) {
    return WeeklySummaryRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      weekStart: weekStart ?? this.weekStart,
      weekEnd: weekEnd ?? this.weekEnd,
      summaryText: summaryText ?? this.summaryText,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}
