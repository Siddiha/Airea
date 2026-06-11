import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/doctor_patient_service.dart';
import '../config/api_config.dart';
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

        // Ensure code and name are saved
        if (email != null) {
          await _ensureCodeSaved(userType, email);
          await _ensureNameSaved(userType, email);
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
      if (userType == 'doctor') {
        // getDoctorCode() already has backend API + Supabase fallback
        await DoctorPatientService.getDoctorCode();
      } else {
        final prefs = await SharedPreferences.getInstance();
        final existing = prefs.getString('patient_code');
        if (existing == null || existing.isEmpty) {
          // Try backend API first
          try {
            final codeUrl = Uri.parse(
                '${ApiConfig.baseUrl}/auth/patient/code?email=${Uri.encodeComponent(email)}');
            final resp =
                await http.get(codeUrl).timeout(const Duration(seconds: 10));
            if (resp.statusCode == 200) {
              final data = jsonDecode(resp.body);
              if (data['code'] != null) {
                await prefs.setString('patient_code', data['code']);
                return;
              }
            }
          } catch (_) {}

          // Fallback: Supabase direct query
          final supabase = Supabase.instance.client;
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

  /// Fetch and cache the user's full name if not already saved
  Future<void> _ensureNameSaved(String userType, String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final existing = prefs.getString('user_full_name');
      if (existing != null && existing.isNotEmpty) return;

      final supabase = Supabase.instance.client;
      final table = userType == 'doctor' ? 'doctors' : 'patients';
      final resp = await supabase
          .from(table)
          .select('full_name')
          .eq('email', email)
          .maybeSingle();
      if (resp != null &&
          resp['full_name'] != null &&
          (resp['full_name'] as String).isNotEmpty) {
        await prefs.setString('user_full_name', resp['full_name']);
      }
    } catch (e) {
      debugPrint('Error ensuring name saved: $e');
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
