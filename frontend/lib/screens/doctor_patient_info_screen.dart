import 'package:flutter/material.dart';
import 'option_connect_patient.dart';

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
                "Registered Patient",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // Center Content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  //text outside box 
                  const Text(
                    "No any patients\nconnected !",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Grey Box
                GestureDetector(
                            onTap: () {
                       Navigator.push(
                         context,
                        MaterialPageRoute(
                        builder: (context) => const OptionConnectPatient(),
                        ),
                      );
                    },
                    child: Container(
                           width: 280,
                          height: 220,
                         decoration: BoxDecoration(
                            color: const Color(0xFFDDE3E4),
                             borderRadius: BorderRadius.circular(16),
                          ),
                           child: const Column(
                       mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                           CircleAvatar(
                         radius: 40,
                       backgroundColor: Colors.green,
                            child: Icon(
                          Icons.add,
                             size: 45,
                            color: Colors.white,
                            ),
                          ),
                           SizedBox(height: 20),
                          Text(
                                 "Press to\nconnect with\n a patient",
                          textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 14),
                      ),
                  ],
                   ),
                 ),
                ),
                ],
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