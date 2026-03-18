import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/summary_service.dart';
import 'patient_daily_calendar.dart';
import 'patient_weekly_calendar.dart';
import '../widgets/bottom_nav_bar.dart';

class PatientSummaryOverview extends StatelessWidget {
  final SummaryService _summaryService = SummaryService();

  PatientSummaryOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Summary heading
                    const Text(
                      'Summary',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    
                    const SizedBox(height: 40),
                    
                    // Daily summary button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _navigateToDailyCalendar(context),
                        style: AppTheme.secondaryButton(),
                        child: const Text('Daily summary'),
                      ),
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Weekly summary button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _navigateToWeeklyCalendar(context),
                        style: AppTheme.secondaryButton(),
                        child: const Text('Weekly summary'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const PatientBottomNav(currentIndex: 2),
    );
  }

  void _navigateToDailyCalendar(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientDailyCalendar(summaryService: _summaryService),
      ),
    );
  }

  void _navigateToWeeklyCalendar(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatientWeeklyCalendar(summaryService: _summaryService),
      ),
    );
  }
}
