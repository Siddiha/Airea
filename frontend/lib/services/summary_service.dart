import 'package:intl/intl.dart';
import '../models/summary_record.dart';
import '../repositories/summary_repository.dart';

class SummaryService {
  final SummaryRepository _repository;

  SummaryService({SummaryRepository? repository})
      : _repository = repository ?? DummySummaryRepository();

  /// Get daily summary for specific date
  Future<DailySummaryRecord?> getDailySummaryForDate(DateTime date) async {
    return await _repository.getDailySummary(date);
  }

  /// Get weekly summary for specific week range
  Future<WeeklySummaryRecord?> getWeeklySummaryForRange(
    DateTime weekStart,
    DateTime weekEnd,
  ) async {
    return await _repository.getWeeklySummary(weekStart, weekEnd);
  }

  /// Format date for display (e.g., "20th November, 2025")
  String formatDateForDisplay(DateTime date) {
    final day = date.day;
    final suffix = _getOrdinalSuffix(day);
    final month = DateFormat('MMMM').format(date);
    final year = date.year;
    
    return '$day$suffix $month, $year';
  }

  /// Format week range for display (e.g., "15-21 November, 2025")
  String formatWeekRangeForDisplay(DateTime weekStart, DateTime weekEnd) {
    final startDay = weekStart.day;
    final endDay = weekEnd.day;
    final month = DateFormat('MMMM').format(weekStart);
    final year = weekStart.year;
    
    return '$startDay-$endDay $month, $year';
  }

  /// Get ordinal suffix (st, nd, rd, th)
  String _getOrdinalSuffix(int day) {
    if (day >= 11 && day <= 13) {
      return 'th';
    }
    switch (day % 10) {
      case 1:
        return 'st';
      case 2:
        return 'nd';
      case 3:
        return 'rd';
      default:
        return 'th';
    }
  }

  /// Calculate week start (Monday) from any date
  DateTime getWeekStart(DateTime date) {
    final weekday = date.weekday;
    return date.subtract(Duration(days: weekday - 1));
  }

  /// Calculate week end (Sunday) from any date
  DateTime getWeekEnd(DateTime date) {
    final weekday = date.weekday;
    return date.add(Duration(days: 7 - weekday));
  }
}
