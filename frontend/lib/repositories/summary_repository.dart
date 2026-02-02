import '../models/summary_record.dart';
import '../utils/dummy_data_generator.dart';

/// Abstract repository interface - allows swapping between dummy and real API
abstract class SummaryRepository {
  Future<DailySummaryRecord?> getDailySummary(DateTime date);
  Future<WeeklySummaryRecord?> getWeeklySummary(DateTime weekStart, DateTime weekEnd);
  Future<List<DailySummaryRecord>> getDailySummaries(DateTime startDate, DateTime endDate);
  Future<List<WeeklySummaryRecord>> getWeeklySummaries(DateTime startDate, DateTime endDate);
}

/// Dummy implementation - generates Lorem Ipsum data
/// In future, create ApiSummaryRepository that calls Spring Boot backend
class DummySummaryRepository implements SummaryRepository {
  @override
  Future<DailySummaryRecord?> getDailySummary(DateTime date) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    return DailySummaryRecord(
      id: 'daily_${date.toString()}',
      date: date,
      summaryText: DummyDataGenerator.generateDailySummary(),
      generatedAt: DateTime.now(),
    );
  }

  @override
  Future<WeeklySummaryRecord?> getWeeklySummary(
    DateTime weekStart,
    DateTime weekEnd,
  ) async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 300));

    return WeeklySummaryRecord(
      id: 'weekly_${weekStart.toString()}',
      date: weekStart,
      weekStart: weekStart,
      weekEnd: weekEnd,
      summaryText: DummyDataGenerator.generateWeeklySummary(),
      generatedAt: DateTime.now(),
    );
  }

  @override
  Future<List<DailySummaryRecord>> getDailySummaries(
    DateTime startDate,
    DateTime endDate,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final List<DailySummaryRecord> summaries = [];
    DateTime currentDate = startDate;

    while (currentDate.isBefore(endDate) || currentDate.isAtSameMomentAs(endDate)) {
      summaries.add(
        DailySummaryRecord(
          id: 'daily_${currentDate.toString()}',
          date: currentDate,
          summaryText: DummyDataGenerator.generateDailySummary(),
          generatedAt: DateTime.now(),
        ),
      );
      currentDate = currentDate.add(const Duration(days: 1));
    }

    return summaries;
  }

  @override
  Future<List<WeeklySummaryRecord>> getWeeklySummaries(
    DateTime startDate,
    DateTime endDate,
  ) async {
    await Future.delayed(const Duration(milliseconds: 300));

    final List<WeeklySummaryRecord> summaries = [];
    DateTime currentWeekStart = startDate;

    while (currentWeekStart.isBefore(endDate)) {
      final weekEnd = currentWeekStart.add(const Duration(days: 6));
      summaries.add(
        WeeklySummaryRecord(
          id: 'weekly_${currentWeekStart.toString()}',
          date: currentWeekStart,
          weekStart: currentWeekStart,
          weekEnd: weekEnd,
          summaryText: DummyDataGenerator.generateWeeklySummary(),
          generatedAt: DateTime.now(),
        ),
      );
      currentWeekStart = currentWeekStart.add(const Duration(days: 7));
    }

    return summaries;
  }
}
