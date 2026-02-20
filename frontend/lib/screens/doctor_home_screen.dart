import 'package:flutter/material.dart';
import 'doctor_notification.dart';
import 'doctor_profile_frame.dart';
import 'doctor_patient_info.dart';
import 'doctor_patient_info_screen.dart';

class DoctorHomeScreen extends StatelessWidget {
  const DoctorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEFF0),

      // Bottom Navigation Bar
           bottomNavigationBar: Container(
                 height: 60,
                  color: Colors.white,
                   child: const Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                   children: [
                       Icon(Icons.home),
                       Text("Home"),
                   ],
                 ),
              ),

      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Top Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 👤 Profile Navigation
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DoctorProfileFrame(),
                        ),
                      );
                    },
                    child: const Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, color: Colors.black),
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Hello user !",
                          style: TextStyle(fontSize: 17),
                        ),
                      ],
                    ),
                  ),

                  //  Notification Navigation
                  IconButton(
                    icon: const Icon(Icons.notifications_none, size: 26),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DoctorNotificationScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 50),

            //  Total Patients (Bigger Card)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DoctorPatientInfo(),
                  ),
                );
              },
              child: _bigCard(
                "Total number of patients",
                "23",
              ),
            ),

            const SizedBox(height: 30),

            //  Connect Patient (Bigger Card)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const DoctorPatientInfoScreen(),
                  ),
                );
              },
              child: _bigCard(
                "Connect to a patient",
                "+",
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Bigger Card Widget
  Widget _bigCard(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        height: 140, // Increased size
        width: double.infinity,
        decoration: BoxDecoration(
          color: const Color(0xFFDDE3E4),
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18, // bigger title
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 28, // bigger number
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }
}