import 'package:airea_cough_monitor/screens/doctor_home_screen.dart';
import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'connect_with_patient.dart';


class OptionConnectPatient extends StatelessWidget {
  const OptionConnectPatient({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEFF0),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Do you want to connect\nwith a patient ?",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                ),
              ),

              const SizedBox(height: 40),

              // Yes Button
              SizedBox(
                width: 220,
                child: ElevatedButton(
                  style: AppTheme.secondaryButton(),
                  onPressed: () {
                    Navigator.push(
                              context,
                              MaterialPageRoute(
                               builder: (context) => const ConnectWithPatient(),
                             ),
                       );
                    },
                  child: const Text('Yes'),
                ),
              ),

              const SizedBox(height: 20),

              // No Button
              SizedBox(
                width: 220,
                child: ElevatedButton(
                  style: AppTheme.secondaryButton(),
                  onPressed: () {
                       Navigator.push(
                              context,
                              MaterialPageRoute(
                               builder: (context) => const DoctorHomeScreen(),
                             ),
                       );
                  },
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