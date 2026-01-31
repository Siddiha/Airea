import 'package:flutter/material.dart';
import 'patient_connect_with_doctor_message.dart';

class PatientPendingMessage extends StatelessWidget {
  const PatientPendingMessage({super.key});

  @override
  Widget build(BuildContext context) {
    Future.delayed(const Duration(seconds: 3), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => const PatientConnectWithDoctorMessage()),
      );
    });

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Text(
              'Connection message sent!',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text('Please wait to be approved by the doctor'),
            SizedBox(height: 30),
            CircularProgressIndicator(color: Colors.teal),
          ],
        ),
      ),
    );
  }
}