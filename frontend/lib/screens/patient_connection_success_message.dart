import 'package:flutter/material.dart';

class PatientConnectionSuccessMessage extends StatelessWidget {
  const PatientConnectionSuccessMessage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEFF0),
      body: SafeArea(
        child: Stack(
          children: [
            // Close button
            Positioned(
              top: 30,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),

            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Text(
                    "Successfully\nconnected with\npatient",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 30),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.green,
                    child: Icon(
                      Icons.check,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}