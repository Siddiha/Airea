import 'package:flutter/material.dart';
import '../services/auth_service.dart';
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
