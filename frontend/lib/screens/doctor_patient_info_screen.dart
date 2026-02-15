import 'package:flutter/material.dart';

class DoctorPatientInfoScreen extends StatelessWidget {
  const DoctorPatientInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEFF0),
      body: SafeArea(
        child: Stack(
          children: [
            // Title
            const Positioned(
              top: 40,
              left: 20,
              child: Text(
                "Registered Patient’s",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Center Content
            Center(
              child: Container(
                width: 280,
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 30),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE3E4),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Text(
                      "No any patients\nconnected !",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 25),
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: Colors.green,
                      child: Icon(
                        Icons.add,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 15),
                    Text(
                      "Press to\nconnect with\n a patient",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Home
            const Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  Icon(Icons.home, size: 28),
                  Text("Home"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}