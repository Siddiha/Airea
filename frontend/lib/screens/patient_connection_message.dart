import 'package:flutter/material.dart';
import 'patient_connection_success_message.dart';


class PatientConnectionMessage extends StatelessWidget {
  const PatientConnectionMessage({super.key});

  @override
  Widget build(BuildContext context) {

    // Auto navigate after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              const PatientConnectionSuccessMessage(),
        ),
      );
    });

    return Scaffold(
      backgroundColor: const Color(0xFFEDEFF0),
      body: const SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Connection message\nsent !",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 30),
              Text(
                "Please wait to be\napproved by the\npatient",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}