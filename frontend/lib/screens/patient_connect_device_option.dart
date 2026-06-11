import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'patient_connect_device_code.dart';
import '../widgets/bottom_nav_bar.dart';

class PatientConnectDeviceOption extends StatelessWidget {
  const PatientConnectDeviceOption({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), 
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2), 

              // 1. MAIN QUESTION TEXT
              const Text(
                'Do you want to pair\nwith the wearable\ndevice ?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24, 
                  height: 1.3,
                  fontWeight: FontWeight.w600, 
                  color: Colors.black,
                  letterSpacing: 0.5,
                ),
              ),

              const SizedBox(height: 50),

              // 2. "YES" BUTTON
              _buildOptionButton(
                context: context,
                label: "Yes",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PatientConnectDeviceCode(),
                    ),
                  );
                  print("Yes Pressed - Go to Code Screen");
                },
              ),

              const SizedBox(height: 20), // Spacing between buttons

              // 3. "NO" BUTTON
              _buildOptionButton(
                context: context,
                label: "No",
                onTap: () {
                  Navigator.pop(context);
                },
              ),

              const Spacer(flex: 3),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const PatientBottomNav(currentIndex: 1),
    );
  }

  Widget _buildOptionButton({
    required BuildContext context,
    required String label,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: AppTheme.secondaryButton(),
        child: Text(label),
      ),
    );
  }

}



  