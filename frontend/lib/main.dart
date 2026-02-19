import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // <--- ADD THIS IMPORT
import 'config/app_theme.dart';
import 'screens/welcome_page.dart';
import 'screens/patient_profile_frame.dart';
// Import for testing summary screens
import 'screens/summary_screens_test.dart';

Future<void> main() async {
  // <--- Changed to 'Future<void>' and 'async'
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize Supabase
  // REPLACE these values with your actual keys from Supabase Dashboard -> Project Settings -> API
  await Supabase.initialize(
    url: 'https://tzlosvcspgnmtcmjjlut.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InR6bG9zdmNzcGdubXRjbWpqbHV0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjY0OTU2MzIsImV4cCI6MjA4MjA3MTYzMn0.1zwveXDzxwyEtezTJgXHx0BrzzfrpkvaDWCjrFI_0E0',
  );

  // 2. Lock Orientation
  await SystemChrome.setPreferredOrientations([
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
      title: 'Airea',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      home: const WelcomePage(),
    );
  }
}

// Backwards-compatible alias used by tests and older code
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => const AireaApp();
}
