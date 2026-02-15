import 'package:flutter/material.dart';
import 'guidance_to_connect_patient.dart';

class ConnectWithPatient extends StatelessWidget {
  const ConnectWithPatient({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEDEFF0),
      body: SafeArea(
        child: Stack(
          children: [
        
            // Main Content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Please enter patient’s\nid",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      ),
                  ),

                  const SizedBox(height: 20),

                  // Text Field
                 SizedBox(
                        width: 250,
                          child: TextField(
                         decoration: InputDecoration(
                             hintText: "type",
                              filled: true,
                          fillColor: Colors.grey[300],
                         contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                            vertical: 14,
                         ),
                           border: OutlineInputBorder(
                             borderRadius: BorderRadius.circular(25), // 👈 curve here
                            borderSide: BorderSide.none,
                      ),
                        ),
                      ),
                   ),

                  const SizedBox(height: 20),

                  // Confirm Button
                  SizedBox(
                    width: 150,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5DA092),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        // Add confirm logic here
                      },
                      child: const Text("Confirm"),
                    ),
                  ),

                  const SizedBox(height: 60),

                  const Text(
                    "Please contact with\ndoctor to get his/her id",
                    textAlign: TextAlign.center,
                     style: TextStyle(
                           fontSize: 18,
                           fontWeight: FontWeight.bold,
                   ),
                  ),

                  const SizedBox(height: 20),

                  // Guidance Button
                  SizedBox(
                    width: 280,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5DA092),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                        elevation: 5,
                      ),
                      onPressed: () {
                        Navigator.push(
                               context,
                           MaterialPageRoute(
                        builder: (context) => const GuidanceToConnectPatient(),
                       ),
  );
                      },
                      child: const Text(
                        "Guidance to connect \n with patient",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                               fontSize: 14,   
                        ),
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