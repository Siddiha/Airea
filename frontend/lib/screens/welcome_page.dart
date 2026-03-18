import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'role_selection_page.dart';
import 'patient_profile_frame.dart';


class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(flex: 2),

              // AIREA Logo
              Image.asset(
                'assets/images/logo.png',
                height: 220,
                width: 220,
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 24),

              // Description
              const Text(
                'Smart Respiratory Monitor for Early Lung\nCancer Detection.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.black87,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),

              const SizedBox(height: 30),

              // Get Started Button
              SizedBox(
                width: 220,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                      builder: (context) => const RoleSelectionPage()),
                      //builder: (context) => const PatientProfileFrame()), // Dont delete
                    );
                  },
                  style: AppTheme.primaryButton(),
                  child: const Text('Get started'),
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 200,
      height: 200,
      child: Image.asset(
        'assets/images/Airea Logo.png',
        fit: BoxFit.contain,
      ),
    );
  }
}
