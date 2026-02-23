import 'package:flutter/material.dart';
import 'doctor_home_screen.dart';

class DoctorNotificationScreen extends StatelessWidget {
  const DoctorNotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEFF0),
      body: SafeArea(
        child: Stack(
          children: [
            // Title
            const Positioned(
              top: 30,
              left: 20,
              child: Text(
                "Notifications",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Notification list centered
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  _NotificationCard(
                    text: "Connected with patient",
                    time: "13:00",
                  ),
                  SizedBox(height: 18),
                  _NotificationCard(
                    text: "Patient1 detected with\nhigh cough",
                    time: "12:56",
                  ),
                ],
              ),
            ),

            // Bottom home
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const DoctorHomeScreen(),
                    ),
                    (route) => false,
                  );
                },
                child: const Column(
                  children: [
                    Icon(Icons.home, size: 28),
                    Text("Home"),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final String text;
  final String time;

  const _NotificationCard({
    required this.text,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFDDE3E4),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              text,
              style: const TextStyle(fontSize: 13),
            ),
          ),
          Text(
            time,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
