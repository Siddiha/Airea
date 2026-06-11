import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'patient_login_page.dart';
//import 'doctor_home_screen.dart';
import 'doctor_login_page.dart';

class RoleSelectionPage extends StatelessWidget {
  const RoleSelectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          //padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 200,),

              // Title
              const Text(
                'Continue as',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 60),

              // Patient Button
              SizedBox(
                width: 260,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PatientLoginPage()),
                    );
                  },
                  style: AppTheme.secondaryButton().copyWith(
                    minimumSize: const WidgetStatePropertyAll(Size(260, 56)),
                    textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                  ),
                  child: const Text('Patient'),
                ),
              ),

              const SizedBox(height: 24),

              // OR Divider
              const Text(
                'OR',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 24),

              // Doctor Button
              SizedBox(
                width: 260,
                child: ElevatedButton(
                  onPressed: () {
                      print("Doctor login not ready yet");
                      Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const DoctorLoginPage ()),
                    );
                  },
                  style: AppTheme.secondaryButton().copyWith(
                    minimumSize: const WidgetStatePropertyAll(Size(260, 56)),
                    textStyle: const WidgetStatePropertyAll(TextStyle(fontSize: 22, fontWeight: FontWeight.w600)),
                  ),
                  child: const Text('Doctor'),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

