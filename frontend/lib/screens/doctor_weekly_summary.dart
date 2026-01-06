import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class DoctorWeeklySummary extends StatefulWidget {
  const DoctorWeeklySummary({Key? key}) : super(key: key);

  @override
  State<DoctorWeeklySummary> createState() => _DoctorWeeklySummaryState();
}

class _DoctorWeeklySummaryState extends State<DoctorWeeklySummary> {
  DateTime startDate = DateTime.now().subtract(const Duration(days: 7));
  DateTime endDate = DateTime.now();

  Future<void> _selectDateRange(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: startDate, end: endDate),
    );
    if (picked != null) {
      setState(() {
        startDate = picked.start;
        endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.darkBlue),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Weekly Summary',
          style: TextStyle(
            color: AppTheme.darkBlue,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Date Range',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkBlue,
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _selectDateRange(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E8E8),
                  borderRadius: BorderRadius.circular(25),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${startDate.day}/${startDate.month}/${startDate.year} - ${endDate.day}/${endDate.month}/${endDate.year}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Icon(Icons.calendar_today, color: AppTheme.primaryTeal),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Weekly Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkBlue,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.backgroundColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Text(
                'Over the past week, patient has shown consistent vital signs with average SpO2 at 97%, temperature ranging from 36.2°C to 36.8°C, and heart rate between 68-75 BPM. Cough frequency has been elevated with an average of 42 episodes per hour. Notable spike in symptoms on Monday and Wednesday. Overall trend shows slight improvement. Continue current treatment plan and reassess next week.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
