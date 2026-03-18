import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import '../repositories/summary_repository.dart';
import '../services/summary_service.dart';
import '../widgets/custom_calendar_widget.dart';
import 'daily_summary_detail_screen_new.dart';
import '../widgets/bottom_nav_bar.dart';

class PatientDailyCalendar extends StatefulWidget {
  final SummaryService summaryService;

  const PatientDailyCalendar({
    super.key,
    required this.summaryService,
  });

  @override
  State<PatientDailyCalendar> createState() => _PatientDailyCalendarState();
}

class _PatientDailyCalendarState extends State<PatientDailyCalendar> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.withOpacity(0.3),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Daily Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // Instruction text
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Select a date form the calendar',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Calendar
              CustomCalendarWidget(
                mode: CalendarMode.singleDate,
                initialMonth: DateTime(2025, 11), // November 2025 as per Figma
                onDateSelected: (date) {
                  _navigateToSummaryDetail(context, date);
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const PatientBottomNav(currentIndex: 2),
    );
  }

  void _navigateToSummaryDetail(BuildContext context, DateTime date) {
    // Use same API-powered detail screen as doctor so patient gets real summary data
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DailySummaryDetailScreenNew(
          selectedDate: date,
          deviceId: ApiConfig.defaultDeviceId,
          repository: ApiSummaryRepository(),
        ),
      ),
    );
  }

}
