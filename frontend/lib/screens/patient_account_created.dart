import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'patient_homescreen.dart';

class PatientAccountCreated extends StatelessWidget {
  const PatientAccountCreated({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Success Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.normalGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 80,
                ),
              ),

              const SizedBox(height: 40),

              // Success Message
              const Text(
                'User account created\nsuccessfully',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),

              const Spacer(),

              // Close Button (X)
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (context) => PatientHomeScreen()),
                      (route) => false,
                    );
                  },
                  icon: const Icon(Icons.close, size: 28),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
