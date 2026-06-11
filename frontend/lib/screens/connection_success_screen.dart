import 'dart:async';
import 'package:flutter/material.dart';
import 'patient_homeScreen.dart'; // Ensure this matches your actual Home Screen filename

class ConnectionSuccessScreen extends StatefulWidget {
  const ConnectionSuccessScreen({super.key});

  @override
  State<ConnectionSuccessScreen> createState() =>
      _ConnectionSuccessScreenState();
}

class _ConnectionSuccessScreenState extends State<ConnectionSuccessScreen> {
  @override
  void initState() {
    super.initState();
    // Start a timer as soon as the screen loads
    _startAutoNavigation();
  }

  void _startAutoNavigation() {
    // Wait for 3 seconds, then navigate to Home
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => const PatientHomeScreen(),
          ),
          (route) => false, // This clears the back button history
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Success Animation/Icon
              TweenAnimationBuilder(
                duration: const Duration(milliseconds: 800),
                tween: Tween<double>(begin: 0, end: 1),
                curve: Curves.elasticOut,
                builder: (context, double value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0F2F1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF66A399),
                        size: 100,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              const Text(
                'Connected Successfully!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'Redirecting to dashboard...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 40),

              // Small loading indicator to show something is happening
              const CircularProgressIndicator(
                color: Color(0xFF66A399),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
