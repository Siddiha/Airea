import 'dart:async';
import 'package:flutter/material.dart';
import 'patient_homeScreen.dart';

class PatientConnectWithDoctorMessage extends StatefulWidget {
  const PatientConnectWithDoctorMessage({super.key});

  @override
  State<PatientConnectWithDoctorMessage> createState() =>
      _PatientConnectWithDoctorMessageState();
}

class _PatientConnectWithDoctorMessageState
    extends State<PatientConnectWithDoctorMessage> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const PatientHomeScreen()),
          (route) => false,
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