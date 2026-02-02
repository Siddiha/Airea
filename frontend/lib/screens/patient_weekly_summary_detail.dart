import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/summary_record.dart';
import '../services/summary_service.dart';

class PatientWeeklySummaryDetail extends StatefulWidget {
  final DateTime weekStart;
  final DateTime weekEnd;
  final SummaryService summaryService;

  const PatientWeeklySummaryDetail({
    super.key,
    required this.weekStart,
    required this.weekEnd,
    required this.summaryService,
  });

  @override
  State<PatientWeeklySummaryDetail> createState() => _PatientWeeklySummaryDetailState();
}

class _PatientWeeklySummaryDetailState extends State<PatientWeeklySummaryDetail> {
  late Future<WeeklySummaryRecord?> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = widget.summaryService.getWeeklySummaryForRange(
      widget.weekStart,
      widget.weekEnd,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Using weekStart date for display as per Figma (shows "20th November" for the week)
    final formattedDate = widget.summaryService.formatDateForDisplay(widget.weekStart);

    return Scaffold(
      backgroundColor: Colors.grey.withOpacity(0.3),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        'Weekly Summary for $formattedDate',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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

              // Summary content
              Expanded(
                child: FutureBuilder<WeeklySummaryRecord?>(
                  future: _summaryFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryTeal,
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            'Error loading summary: ${snapshot.error}',
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    }

                    final summary = snapshot.data;
                    if (summary == null) {
                      return const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16),
                          child: Text('No summary available for this week.'),
                        ),
                      );
                    }

                    return SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0F2F1), // Light teal/mint background
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          summary.summaryText,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
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
