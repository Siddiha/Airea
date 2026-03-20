import 'package:flutter/material.dart';
import 'patient_device_dashboard.dart';
import 'patient_homeScreen.dart';

class PatientDeviceConnected extends StatelessWidget {
  const PatientDeviceConnected({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), 
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              // 1. Close Button 
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: const Icon(Icons.close, size: 30, color: Colors.black),
                  onPressed: () {
                    // Navigate to dashboard but keep Home in the stack
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PatientDeviceDashboard(),
                      ),
                      (route) => route.isFirst,
                    );
                  },
                ),
              ),

              // 2. Success Text
              const Text(
                'Successfully\nconnected with\ndevice',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                  height: 1.2,
                ),
              ),

              const SizedBox(height: 30),

              // 3. Green Checkmark Circle
              Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50), 
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  color: Colors.white,
                  size: 80,
                ),
              ),

              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}