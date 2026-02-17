import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/app_theme.dart';
import 'screens/welcome_page.dart';
import 'screens/patient_profile_frame.dart';
// Import for testing summary screens
import 'screens/summary_screens_test.dart';

import 'package:airea_cough_monitor/screens/patient_allergies_entry.dart';
import 'package:airea_cough_monitor/screens/patient_edit_allergy.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const AireaApp());
}

class AireaApp extends StatelessWidget {
  const AireaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AIREA - Smart Respiratory Monitor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      home: const PatientAllergies(),
    );
  }
}

// Backwards-compatible alias used by tests and older code
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => const AireaApp();
}