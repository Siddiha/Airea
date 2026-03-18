import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'doctor_patient_removed_success_screen.dart';

class DoctorRemovePatientScreen extends StatelessWidget {
  const DoctorRemovePatientScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            children: [
              const Spacer(flex: 2), 

              // --- Confirmation Text ---
              const Text(
                "Do you want to\nremove this\npatient from your\nlist",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 40), 

              // --- YES Button ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, true); 
                  },
                  style: AppTheme.secondaryButton(),
                  child: const Text('Yes'),
                ),
              ),

              const SizedBox(height: 15),
              
              const Text(
                "OR",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),

              const SizedBox(height: 15),

              // --- NO Button ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context, false); 
                  },
                  style: AppTheme.secondaryButton(),
                  child: const Text('No'),
                ),
              ),

              const Spacer(flex: 3), 
            ],
          ),
        ),
      ),
    );
  }
}