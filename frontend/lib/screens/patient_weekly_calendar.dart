import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/summary_service.dart';
import '../widgets/custom_calendar_widget.dart';
import 'patient_weekly_summary_detail.dart';

class PatientWeeklyCalendar extends StatefulWidget {
  final SummaryService summaryService;

  const PatientWeeklyCalendar({
    super.key,
    required this.summaryService,
  });

  @override
  State<PatientWeeklyCalendar> createState() => _PatientWeeklyCalendarState();
}

class _PatientWeeklyCalendarState extends State<PatientWeeklyCalendar> {
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
                      'Weekly Summary',
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
                  'Select a date range from the calendar',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Calendar with week selection
              CustomCalendarWidget(
                mode: CalendarMode.weekRange,
                initialMonth: DateTime(2025, 11), // November 2025 as per Figma
                onWeekSelected: (weekStart, weekEnd) {
                  _navigateToSummaryDetail(context, weekStart, weekEnd);
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  void _navigateToSummaryDetail(BuildContext context, DateTime weekStart, DateTime weekEnd) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientWeeklySummaryDetail(
          weekStart: weekStart,
          weekEnd: weekEnd,
          summaryService: widget.summaryService,
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.home, false),
              _buildNavItem(Icons.wifi, false),
              _buildNavItem(Icons.description, true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive) {
    return IconButton(
      icon: Icon(
        icon,
        color: isActive ? AppTheme.primaryTeal : Colors.grey,
        size: 28,
      ),
      onPressed: () {},
    );
  }
}
