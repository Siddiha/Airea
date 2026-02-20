import 'package:flutter/material.dart';
import 'doctor_patient_info.dart';

class DoctorHomeScreen extends StatelessWidget {
  const DoctorHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],

  

      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [

            const SizedBox(height: 30),

            // Greeting Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      child: Icon(Icons.person, size: 30),
                    ),
                    SizedBox(width: 10),
                    Text(
                      "Hello User!",
                      style: TextStyle(fontSize: 18),
                    ),
                  ],
                ),
                Icon(Icons.notifications_none, size: 28),
              ],
            ),

            const SizedBox(height: 40),

            // 🔹 Total Patients Card (Clickable)
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DoctorPatientInfo(),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 25),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 4),
                    )
                  ],
                ),
                child: const Column(
                  children: [
                    Text(
                      "Total number of patients",
                      style: TextStyle(fontSize: 18),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "23",
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 25),

            // Connect to Patient Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 25),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: const Column(
                children: [
                  Text(
                    "Connect to a patient",
                    style: TextStyle(fontSize: 18),
                  ),
                  SizedBox(height: 10),
                  Icon(Icons.add, size: 28, color: Colors.green),
                ],
              ),
            ),
          ],
        ),
      ),

 bottomNavigationBar: SafeArea(
  top: false,
  child: Container(
    color: Colors.white,
    padding: const EdgeInsets.only(top: 6, bottom: 8),
    child: InkWell(
      onTap: () {
        // If already on Home, do nothing
      },
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.home, size: 26),
          SizedBox(height: 2),
          Text(
            "Home",
            style: TextStyle(fontSize: 12),
          ),
        ],
      ),
    ),
  ),
),
);
  }
}