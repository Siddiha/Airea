import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../widgets/custom_button.dart';
import 'doctor_daily_summary.dart';
import 'doctor_weekly_summary.dart';
import 'doctor_select_report.dart';
import 'doctor_allergic_conditions.dart';

class DoctorSummary extends StatelessWidget {
  const DoctorSummary({Key? key}) : super(key: key);

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
          'Summary',
          style: TextStyle(
            color: AppTheme.darkBlue,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              CustomButton(
                text: 'Daily summary',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DoctorDailySummary()),
                  );
                },
                isPrimary: true,
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Weekly summary',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DoctorWeeklySummary()),
                  );
                },
                isPrimary: true,
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'View past medical reports',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DoctorSelectReport()),
                  );
                },
                isPrimary: true,
              ),
              const SizedBox(height: 20),
              CustomButton(
                text: 'Allergic conditions',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const DoctorAllergicConditions()),
                  );
                },
                isPrimary: true,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
