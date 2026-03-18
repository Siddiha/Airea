import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../screens/patient_summary_overview.dart';

/// Test runner for Summary screens
/// 
/// To test the summary screens, temporarily change main.dart's home to:
/// home: const SummaryScreensTestPage(),
class SummaryScreensTestPage extends StatelessWidget {
  const SummaryScreensTestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Summary Screens Test'),
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Test Summary Screens',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PatientSummaryOverview(),
                    ),
                  );
                },
                style: AppTheme.secondaryButton(),
                child: const Text('Open Summary Overview'),
              ),
              const SizedBox(height: 20),
              const Text(
                'This will open the summary selector screen.\nFrom there you can test all 5 screens.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
