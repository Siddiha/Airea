import 'package:flutter/material.dart';
import 'doctor_verification_completed.dart';

class DoctorVerificationFrame extends StatelessWidget {
  const DoctorVerificationFrame({super.key});

  @override
  Widget build(BuildContext context) {
    // Simulate verification process
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const DoctorVerificationCompleted()),
      );
    });

    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Verification under\nprogression',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            SizedBox(height: 50),
            CircularProgressIndicator(
              color: Color(0xFF6DBAA6),
              strokeWidth: 5,
            ),
          ],
        ),
      ),
    );
  }
}
