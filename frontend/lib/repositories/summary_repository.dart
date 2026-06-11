import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/summary_record.dart';
import '../models/daily_summary_detail_model.dart';
import '../models/weekly_summary_detail_model.dart';
import '../utils/dummy_data_generator.dart';
import '../config/api_config.dart';

/// Abstract repository interface - allows swapping between dummy and real API
abstract class SummaryRepository {
  Future<DailySummaryRecord?> getDailySummary(DateTime date);
  Future<WeeklySummaryRecord?> getWeeklySummary(
      DateTime weekStart, DateTime weekEnd);
  Future<List<DailySummaryRecord>> getDailySummaries(
      DateTime startDate, DateTime endDate);
  Future<List<WeeklySummaryRecord>> getWeeklySummaries(
      DateTime startDate, DateTime endDate);

  // New method for detailed summary
  Future<DailySummaryDetailModel> getDailySummaryDetail(
      String deviceId, DateTime date);

  // New method for weekly detailed summary
  Future<WeeklySummaryDetailModel> getWeeklySummaryDetail(
      String deviceId, DateTime weekStart);
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

    while (currentDate.isBefore(endDate) ||
        currentDate.isAtSameMomentAs(endDate)) {
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

  @override
  Future<DailySummaryDetailModel> getDailySummaryDetail(
      String deviceId, DateTime date) async {
    await Future.delayed(const Duration(milliseconds: 300));
    throw UnimplementedError(
        'Dummy repository does not support detailed summaries');
  }

  @override
  Future<WeeklySummaryDetailModel> getWeeklySummaryDetail(
      String deviceId, DateTime weekStart) async {
    await Future.delayed(const Duration(milliseconds: 300));
    throw UnimplementedError(
        'Dummy repository does not support weekly detailed summaries');
  }
}

/// API implementation - calls Spring Boot backend
class ApiSummaryRepository implements SummaryRepository {
  final String baseUrl;

  ApiSummaryRepository({String? baseUrl})
      : baseUrl = baseUrl ?? ApiConfig.baseUrl;

  @override
  Future<DailySummaryDetailModel> getDailySummaryDetail(
      String deviceId, DateTime date) async {
    try {
      // Format date as yyyy-MM-dd (matches backend ISO date)
      final dateStr =
          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      final url = Uri.parse(ApiConfig.dailySummaryUrl(deviceId, dateStr));

      print('Making API call: $url');

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timeout - backend may not be running');
        },
      );

      print('API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('Total coughs: ${jsonData['totalCoughs']}');
        return DailySummaryDetailModel.fromJson(jsonData);
      } else {
        throw Exception('Failed to load summary: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching summary: $e');
      rethrow;
    }
  }

  @override
  Future<DailySummaryRecord?> getDailySummary(DateTime date) async {
    // Not implemented for now
    throw UnimplementedError();
  }

  @override
  Future<WeeklySummaryRecord?> getWeeklySummary(
      DateTime weekStart, DateTime weekEnd) async {
    // Not implemented for now
    throw UnimplementedError();
  }

  @override
  Future<List<DailySummaryRecord>> getDailySummaries(
      DateTime startDate, DateTime endDate) async {
    // Not implemented for now
    throw UnimplementedError();
  }

  @override
  Future<List<WeeklySummaryRecord>> getWeeklySummaries(
      DateTime startDate, DateTime endDate) async {
    // Not implemented for now
    throw UnimplementedError();
  }

  @override
  Future<WeeklySummaryDetailModel> getWeeklySummaryDetail(
      String deviceId, DateTime weekStart) async {
    try {
      // Format date as yyyy-MM-dd (matches backend ISO date)
      final dateStr =
          '${weekStart.year.toString().padLeft(4, '0')}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';
      final url = Uri.parse(ApiConfig.weeklySummaryUrl(deviceId, dateStr));

      print('Making Weekly API call: $url');

      final response = await http.get(url).timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Request timeout - backend may not be running');
        },
      );

      print('Weekly API Response: ${response.statusCode}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('Weekly total coughs: ${jsonData['coughSummary']?['totalCoughs']}');
        return WeeklySummaryDetailModel.fromJson(jsonData);
      } else {
        throw Exception('Failed to load weekly summary: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching weekly summary: $e');
      rethrow;
    }
  }
}
