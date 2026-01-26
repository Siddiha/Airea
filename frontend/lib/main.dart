import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'config/app_theme.dart';

// ✅ Import the screen you are KEEPING
import 'screens/patient_homeScreen.dart';

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

      // ✅ Entry point changed from WelcomePage → PatientHomeScreen
      home: PatientHomeScreen(),
    );
  }
}

// Backwards-compatible alias used by tests and older code
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => const AireaApp();
}
