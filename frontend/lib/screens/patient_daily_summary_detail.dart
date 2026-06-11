import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/summary_record.dart';
import '../services/summary_service.dart';
import '../widgets/bottom_nav_bar.dart';

class PatientDailySummaryDetail extends StatefulWidget {
  final DateTime selectedDate;
  final SummaryService summaryService;

  const PatientDailySummaryDetail({
    super.key,
    required this.selectedDate,
    required this.summaryService,
  });

  @override
  State<PatientDailySummaryDetail> createState() => _PatientDailySummaryDetailState();
}

class _PatientDailySummaryDetailState extends State<PatientDailySummaryDetail> {
  late Future<DailySummaryRecord?> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = widget.summaryService.getDailySummaryForDate(widget.selectedDate);
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = widget.summaryService.formatDateForDisplay(widget.selectedDate);

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
                        'Daily Summary for $formattedDate',
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
                child: FutureBuilder<DailySummaryRecord?>(
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
                          child: Text('No summary available for this date.'),
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
      bottomNavigationBar: const PatientBottomNav(currentIndex: 2),
    );
  }
}
