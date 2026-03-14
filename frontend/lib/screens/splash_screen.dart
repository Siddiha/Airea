import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/doctor_patient_service.dart';
import 'welcome_page.dart';
import 'patient_homescreen.dart';
import 'doctor_home_screen.dart';
import 'role_selection_page.dart';

/// Splash screen that checks for valid session and auto-logs in if available.
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  /// Check if valid session exists and navigate accordingly
  Future<void> _checkSession() async {
    // Wait briefly to show splash (optional, for UX)
    await Future.delayed(const Duration(milliseconds: 500));

    final isValid = await _authService.hasValidSession();

    if (!mounted) return;

    if (isValid) {
      // Session valid: get cached user data and navigate to appropriate dashboard
      final userData = await _authService.getCachedUserData();
      if (userData != null) {
        final userType = userData['userType'] ?? 'patient';
        final email = userData['email'];

        // Ensure code is saved for View ID to work
        if (email != null) {
          await _ensureCodeSaved(userType, email);
        }

        if (!mounted) return;
        if (userType == 'doctor') {
          Navigator.pushReplacementNamed(context, '/doctor_home');
        } else {
          Navigator.pushReplacementNamed(context, '/patient_home');
        }
        return;
      }
    }

    // No valid session: show welcome page
    Navigator.pushReplacementNamed(context, '/welcome');
  }

  /// Fetch and cache the user's code if not already saved
  Future<void> _ensureCodeSaved(String userType, String email) async {
    try {
      final supabase = Supabase.instance.client;
      final prefs = await SharedPreferences.getInstance();

      if (userType == 'doctor') {
        final existing = await DoctorPatientService.getDoctorCode();
        if (existing == null || existing.isEmpty) {
          final resp = await supabase
              .from('doctors')
              .select('doctor_code')
              .eq('email', email)
              .maybeSingle();
          if (resp != null && resp['doctor_code'] != null) {
            await DoctorPatientService.saveDoctorCode(resp['doctor_code']);
          }
        }
      } else {
        final existing = prefs.getString('patient_code');
        if (existing == null || existing.isEmpty) {
          final resp = await supabase
              .from('patients')
              .select('patient_code')
              .eq('email', email)
              .maybeSingle();
          if (resp != null && resp['patient_code'] != null) {
            await prefs.setString('patient_code', resp['patient_code']);
          }
        }
      }
    } catch (e) {
      debugPrint('Error ensuring code saved: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App Logo
            Image.asset(
              'assets/images/logo.png',
              height: 150,
              width: 150,
              fit: BoxFit.contain,
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text(
              'Loading...',
              style: TextStyle(fontSize: 16, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
