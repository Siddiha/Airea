import 'package:flutter/material.dart';
import 'patient_connected_with_doctor.dart';

class PatientPendingMessage extends StatelessWidget {
  const PatientPendingMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5F3),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Close Button
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 28),
                ),
              ),

              const Spacer(),

              // Title
              const Text(
                'Connection message\nsent !',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),

              const SizedBox(height: 40),

              // Message
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Text(
                  'Please wait to be\napproved by the\ndoctor',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),

              const Spacer(),

              // Simulate connection - in real app this would wait for actual approval
              TextButton(
                onPressed: () {
                  // Simulate approval after a moment
                  Future.delayed(const Duration(seconds: 2), () {
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PatientConnectedWithDoctor(),
                        ),
                      );
                    }
                  });
                },
                child: Text(
                  'Tap to simulate approval',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
