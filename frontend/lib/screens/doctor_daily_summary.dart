import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class DoctorDailySummary extends StatefulWidget {
  const DoctorDailySummary({Key? key}) : super(key: key);

  @override
  State<DoctorDailySummary> createState() => _DoctorDailySummaryState();
}

class _DoctorDailySummaryState extends State<DoctorDailySummary> {
  DateTime selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
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
          'Daily Summary',
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
              'Select Date',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.darkBlue,
              ),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () => _selectDate(context),
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
                      '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
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
              'Summary',
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
                'Patient showed normal vital signs throughout the day. SpO2 levels maintained at 98%, temperature stable at 36.5°C, and heart rate averaged 72 BPM. Cough frequency was elevated with 45 episodes per hour, particularly during morning hours. Recommend continued monitoring and possible adjustment to medication if symptoms persist.',
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
