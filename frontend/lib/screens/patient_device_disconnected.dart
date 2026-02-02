import 'package:flutter/material.dart';
import '../config/app_theme.dart';

class PatientDeviceDisconnected extends StatelessWidget {
  const PatientDeviceDisconnected({super.key});

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
                    Navigator.pop(context);
                  },
                ),
              ),

              const SizedBox(height: 20), 

              // 2. Disconnected Text 
              const Text(
                'Device disconnected\nSuccessfully',
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