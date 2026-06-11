import 'package:flutter/material.dart';
import 'patient_homeScreen.dart';

class PatientConnectWithDoctorMessage extends StatelessWidget {
  const PatientConnectWithDoctorMessage({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (_) => const PatientHomeScreen()),
        (route) => false,
      );
    });
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.check_circle, color: Colors.green, size: 80),
            SizedBox(height: 20),
            Text(
              'Successfully connected\nwith doctor',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}