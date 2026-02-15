import 'package:flutter/material.dart';

class GuidanceToConnectPatient extends StatelessWidget {
  const GuidanceToConnectPatient({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEFF0),
      body: SafeArea(
        child: Stack(
          children: [
            // Title + Close button
            Positioned(
              top: 30,
              left: 20,
              right: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Text(
                      "Guidance to connect with a patient",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context); // Go back
                    },
                  ),
                ],
              ),
            ),

            // Content box
            Center(
              child: Container(
                width: 300,
                height: 350,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFDDE3E4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade400),
                ),
                child: const SingleChildScrollView(
                  child: Text(
                    "Lorem Ipsum is simply dummy text of the printing and "
                    "typesetting industry. Lorem Ipsum has been the industry's "
                    "standard dummy text ever since the 1500s, when an unknown "
                    "printer took a galley of type and scrambled it to make "
                    "a type specimen book.",
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}