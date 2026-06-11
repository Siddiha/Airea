import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'patient_connect_with_doctor.dart';

class PatientContactDoctor extends StatelessWidget {
  const PatientContactDoctor({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Do you want to connect\nwith a doctor?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: AppTheme.secondaryButton(),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PatientConnectWithDoctor()),
                    );
                  },
                  child: const Text('Yes'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: AppTheme.outlineButton(),
                  child: const Text('No'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}