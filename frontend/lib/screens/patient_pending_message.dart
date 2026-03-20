import 'dart:async';
import 'package:flutter/material.dart';
import 'patient_connect_with_doctor_message.dart';

class PatientPendingMessage extends StatefulWidget {
  const PatientPendingMessage({super.key});

  @override
  State<PatientPendingMessage> createState() => _PatientPendingMessageState();
}

class _PatientPendingMessageState extends State<PatientPendingMessage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) => const PatientConnectWithDoctorMessage()),
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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